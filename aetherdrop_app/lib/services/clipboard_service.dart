import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:super_clipboard/super_clipboard.dart';

import '../models/transfer_manifest.dart';
import 'webrtc_engine.dart';

/// Content category detected from OS clipboard inspection.
enum ClipboardContentType {
  /// PNG binary screenshot or graphical buffer.
  image,

  /// Text note, URL, or code snippet.
  text,

  /// File paths copied from Finder or Windows Explorer.
  files,

  /// Clipboard is empty or contains unsupported formats.
  empty,
}

/// Represents the inspected and normalized clipboard content.
class ClipboardPayload {
  const ClipboardPayload({
    required this.type,
    this.text,
    this.imageBytes,
    this.filePaths = const <String>[],
    this.isUrl = false,
    this.isCode = false,
    this.byteSize = 0,
  });

  final ClipboardContentType type;
  final String? text;
  final Uint8List? imageBytes;
  final List<String> filePaths;
  final bool isUrl;
  final bool isCode;
  final int byteSize;

  factory ClipboardPayload.image(Uint8List bytes) {
    return ClipboardPayload(
      type: ClipboardContentType.image,
      imageBytes: bytes,
      byteSize: bytes.length,
    );
  }

  factory ClipboardPayload.text(String text) {
    final bool isUrl = _checkIsUrl(text);
    final bool isCode = _checkIsCode(text);
    final List<int> utf8Bytes = utf8.encode(text);

    return ClipboardPayload(
      type: ClipboardContentType.text,
      text: text,
      isUrl: isUrl,
      isCode: isCode,
      byteSize: utf8Bytes.length,
    );
  }

  factory ClipboardPayload.files(List<String> paths) {
    return ClipboardPayload(
      type: ClipboardContentType.files,
      filePaths: paths,
      byteSize: 0,
    );
  }

  static const ClipboardPayload empty = ClipboardPayload(
    type: ClipboardContentType.empty,
  );

  /// Human-friendly description for notifications and confirmation chips.
  String get summary {
    switch (type) {
      case ClipboardContentType.image:
        final double kb = byteSize / 1024.0;
        return 'Screenshot Image (${kb > 1024 ? "${(kb / 1024).toStringAsFixed(1)} MB" : "${kb.toStringAsFixed(1)} KB"})';

      case ClipboardContentType.text:
        if (isUrl) return 'Web URL ($text)';
        if (isCode) return 'Code Snippet (${text?.split('\n').length} lines)';
        final int len = text?.length ?? 0;
        return 'Text Note ($len char${len == 1 ? '' : 's'})';

      case ClipboardContentType.files:
        return '${filePaths.length} Copied File${filePaths.length == 1 ? '' : 's'}';

      case ClipboardContentType.empty:
        return 'Empty Clipboard';
    }
  }

  static bool _checkIsUrl(String raw) {
    final String clean = raw.trim();
    if (clean.startsWith('http://') || clean.startsWith('https://')) {
      final Uri? uri = Uri.tryParse(clean);
      return uri != null && uri.hasAuthority;
    }
    if (clean.contains('.') &&
        !clean.contains(' ') &&
        !clean.contains('\n') &&
        clean.length > 4) {
      final Uri? uri = Uri.tryParse('https://$clean');
      return uri != null && uri.hasAuthority && clean.split('.').last.length >= 2;
    }
    return false;
  }

  static bool _checkIsCode(String raw) {
    if (!raw.contains('\n') && raw.length < 50) return false;
    final List<String> codeMarkers = <String>[
      '{',
      '}',
      ';',
      'const ',
      'final ',
      'import ',
      'class ',
      'function',
      'def ',
      'return ',
      '=>',
      '</',
      '/>',
      'public ',
      'private ',
      'struct ',
    ];
    int matchCount = 0;
    for (final String marker in codeMarkers) {
      if (raw.contains(marker)) {
        matchCount++;
      }
    }
    return matchCount >= 2;
  }
}

/// System clipboard listener and instant beam orchestrator for AetherDrop.
///
/// Features:
/// - Detects copied screenshots (raw PNG buffers) via `super_clipboard`.
/// - Detects copied text, code snippets, or URLs.
/// - Detects copied file paths from native file explorers.
/// - Global keyboard handler for `Ctrl+V` (Windows/Android) and `Cmd+V` (macOS/iOS).
/// - 1-click clipboard writeback helper for receivers.
class ClipboardService extends ChangeNotifier {
  ClipboardService._() {
    _registerGlobalShortcutHandler();
  }

  static final ClipboardService instance = ClipboardService._();

  String? _selectedPeerId;
  bool _isShortcutListeningEnabled = true;

  /// Currently focused peer on the radar screen.
  String? get selectedPeerId => _selectedPeerId;

  /// Sets the currently highlighted peer for keyboard shortcut triggering.
  void setSelectedPeer(String? peerId) {
    _selectedPeerId = peerId;
    notifyListeners();
  }

  /// Enables or disables the global keyboard paste shortcut.
  void setShortcutListening(bool enabled) {
    _isShortcutListeningEnabled = enabled;
  }

  // ---------------------------------------------------------------------------
  // Global Keyboard Shortcut Registration (`Ctrl+V` & `Cmd+V`)
  // ---------------------------------------------------------------------------

  void _registerGlobalShortcutHandler() {
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (!_isShortcutListeningEnabled || _selectedPeerId == null) {
      return false;
    }

    // Only process on key down
    if (event is! KeyDownEvent) return false;

    // Check if focused widget is an editable text field (e.g. search bar).
    // If so, do not intercept normal text field paste!
    final BuildContext? focusedContext =
        FocusManager.instance.primaryFocus?.context;
    if (focusedContext != null) {
      final Element element = focusedContext as Element;
      bool isEditingText = false;
      element.visitAncestorElements((Element ancestor) {
        if (ancestor.widget is EditableText) {
          isEditingText = true;
          return false;
        }
        return true;
      });
      if (isEditingText) return false;
    }

    final bool isMetaPressed = HardwareKeyboard.instance.isMetaPressed;
    final bool isControlPressed = HardwareKeyboard.instance.isControlPressed;
    final bool isV = event.logicalKey == LogicalKeyboardKey.keyV;

    // Cmd+V (macOS) or Ctrl+V (Windows/Linux/Android)
    if ((isMetaPressed || isControlPressed) && isV) {
      if (_selectedPeerId != null) {
        pasteAndBeam(targetUserId: _selectedPeerId!);
        return true;
      }
    }

    return false;
  }

  // ---------------------------------------------------------------------------
  // Clipboard Reading via super_clipboard
  // ---------------------------------------------------------------------------

  /// Inspects OS clipboard contents and returns a structured [ClipboardPayload].
  Future<ClipboardPayload> getClipboardPayload() async {
    try {
      final SystemClipboard? clipboard = SystemClipboard.instance;

      if (clipboard != null) {
        final ClipboardReader reader = await clipboard.read();

        // 1. Check for file paths copied in Finder / File Explorer
        if (reader.canProvide(Formats.fileUri)) {
          try {
            final Uri? uri = await reader.readValue(Formats.fileUri);
            if (uri != null && uri.toFilePath().isNotEmpty) {
              return ClipboardPayload.files(<String>[uri.toFilePath()]);
            }
          } catch (_) {}
        }

        // 2. Check for copied PNG image / screenshot
        if (reader.canProvide(Formats.png)) {
          final Completer<Uint8List?> imgCompleter = Completer<Uint8List?>();

          reader.getFile(Formats.png, (file) async {
            try {
              final Uint8List bytes = await file.readAll();
              if (!imgCompleter.isCompleted) {
                imgCompleter.complete(bytes);
              }
            } catch (e) {
              if (!imgCompleter.isCompleted) {
                imgCompleter.complete(null);
              }
            }
          });

          final Uint8List? imageBytes = await imgCompleter.future.timeout(
            const Duration(seconds: 2),
            onTimeout: () => null,
          );

          if (imageBytes != null && imageBytes.isNotEmpty) {
            return ClipboardPayload.image(imageBytes);
          }
        }

        // 3. Check for plain text
        if (reader.canProvide(Formats.plainText)) {
          final String? text = await reader.readValue(Formats.plainText);
          if (text != null && text.trim().isNotEmpty) {
            return ClipboardPayload.text(text.trim());
          }
        }
      }
    } catch (e) {
      debugPrint('super_clipboard error: $e');
    }

    // Fallback: Flutter standard system clipboard
    try {
      final ClipboardData? fallbackData =
          await Clipboard.getData(Clipboard.kTextPlain);
      if (fallbackData != null &&
          fallbackData.text != null &&
          fallbackData.text!.trim().isNotEmpty) {
        return ClipboardPayload.text(fallbackData.text!.trim());
      }
    } catch (e) {
      debugPrint('Fallback Clipboard error: $e');
    }

    return ClipboardPayload.empty;
  }

  // ---------------------------------------------------------------------------
  // Action: Paste & Beam Directly to Peer
  // ---------------------------------------------------------------------------

  /// Reads the current OS clipboard and beams it immediately to [targetUserId].
  ///
  /// Returns `true` if a payload was found and transmission began.
  Future<bool> pasteAndBeam({required String targetUserId}) async {
    final ClipboardPayload payload = await getClipboardPayload();
    if (payload.type == ClipboardContentType.empty) {
      return false;
    }

    switch (payload.type) {
      case ClipboardContentType.image:
        await WebRTCEngine.instance.sendClipboardPayload(
          targetUserId: targetUserId,
          type: ClipboardPayloadType.image,
          imageBytes: payload.imageBytes,
        );
        return true;

      case ClipboardContentType.text:
        await WebRTCEngine.instance.sendClipboardPayload(
          targetUserId: targetUserId,
          type: ClipboardPayloadType.text,
          text: payload.text,
        );
        return true;

      case ClipboardContentType.files:
        await WebRTCEngine.instance.sendFiles(
          targetUserId: targetUserId,
          filePaths: payload.filePaths,
        );
        return true;

      case ClipboardContentType.empty:
        return false;
    }
  }

  /// Direct beam for user-composed text or code snippets.
  Future<void> beamCustomText({
    required String targetUserId,
    required String text,
  }) async {
    if (text.trim().isEmpty) return;

    await WebRTCEngine.instance.sendClipboardPayload(
      targetUserId: targetUserId,
      type: ClipboardPayloadType.text,
      text: text.trim(),
    );
  }

  // ---------------------------------------------------------------------------
  // Receiver Helper: 1-Click Copy to OS Clipboard
  // ---------------------------------------------------------------------------

  /// Copies text directly to the native OS clipboard.
  Future<void> copyTextToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    super.dispose();
  }
}
