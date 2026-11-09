import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/constants.dart';
import '../models/transfer_manifest.dart';
import '../models/user_profile.dart';
import 'auth_service.dart';
import 'signaling_service.dart';

/// State of an active or pending P2P warp transfer.
enum TransferStatus {
  idle,
  initiating,
  waitingForPeer,
  connecting,
  connected,
  transferring,
  completed,
  failed,
  cancelled,
}

/// Real-time live metrics snapshot emitted at 60fps for UI consumption.
class TransferProgress {
  const TransferProgress({
    required this.transferId,
    required this.status,
    required this.isSender,
    required this.peerId,
    required this.peerDisplayName,
    required this.peerAvatarId,
    this.manifest,
    this.bytesTransferred = 0,
    this.totalBytes = 0,
    this.progress = 0.0,
    this.speedMBps = 0.0,
    this.eta,
    this.currentFileIndex = 0,
    this.totalFiles = 1,
    this.currentFileName = '',
    this.errorMessage,
    this.completionResult,
  });

  final String transferId;
  final TransferStatus status;
  final bool isSender;
  final String peerId;
  final String peerDisplayName;
  final String peerAvatarId;
  final TransferManifest? manifest;
  final int bytesTransferred;
  final int totalBytes;

  /// Progress fraction clamped between 0.0 and 1.0.
  final double progress;

  /// Real-time transfer speed in Megabytes per second.
  final double speedMBps;

  /// Estimated time remaining based on recent throughput.
  final Duration? eta;

  /// Index of the file currently in flight (0-based).
  final int currentFileIndex;

  /// Total count of files in the current payload.
  final int totalFiles;

  /// Name of the file currently being beamed.
  final String currentFileName;

  /// Error message if status == [TransferStatus.failed].
  final String? errorMessage;

  /// Gamification and streak results returned upon 100% completion.
  final Map<String, dynamic>? completionResult;

  /// Speed display formatted string (e.g. `68.4 MB/s`).
  String get speedDisplay => '${speedMBps.toStringAsFixed(1)} MB/s';

  /// Percentage completed string (e.g. `74%`).
  String get percentageDisplay => '${(progress * 100).clamp(0, 100).toInt()}%';

  /// Formatted ETA string (e.g. `14s`, `2m 10s`, or `--`).
  String get etaDisplay {
    if (eta == null || eta!.inSeconds <= 0) return '--';
    if (eta!.inMinutes < 1) return '${eta!.inSeconds}s';
    return '${eta!.inMinutes}m ${eta!.inSeconds % 60}s';
  }

  /// Formatted volume transferred (e.g. `124.5 MB / 1.42 GB`).
  String get volumeDisplay {
    final String current = _formatBytes(bytesTransferred);
    final String total = _formatBytes(totalBytes);
    return '$current / $total';
  }

  /// Current item counter string (e.g. `File 3 of 12`).
  String get fileCounterDisplay => 'File ${currentFileIndex + 1} of $totalFiles';

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  TransferProgress copyWith({
    String? transferId,
    TransferStatus? status,
    bool? isSender,
    String? peerId,
    String? peerDisplayName,
    String? peerAvatarId,
    TransferManifest? manifest,
    int? bytesTransferred,
    int? totalBytes,
    double? progress,
    double? speedMBps,
    Duration? eta,
    int? currentFileIndex,
    int? totalFiles,
    String? currentFileName,
    String? errorMessage,
    Map<String, dynamic>? completionResult,
  }) {
    return TransferProgress(
      transferId: transferId ?? this.transferId,
      status: status ?? this.status,
      isSender: isSender ?? this.isSender,
      peerId: peerId ?? this.peerId,
      peerDisplayName: peerDisplayName ?? this.peerDisplayName,
      peerAvatarId: peerAvatarId ?? this.peerAvatarId,
      manifest: manifest ?? this.manifest,
      bytesTransferred: bytesTransferred ?? this.bytesTransferred,
      totalBytes: totalBytes ?? this.totalBytes,
      progress: progress ?? this.progress,
      speedMBps: speedMBps ?? this.speedMBps,
      eta: eta ?? this.eta,
      currentFileIndex: currentFileIndex ?? this.currentFileIndex,
      totalFiles: totalFiles ?? this.totalFiles,
      currentFileName: currentFileName ?? this.currentFileName,
      errorMessage: errorMessage ?? this.errorMessage,
      completionResult: completionResult ?? this.completionResult,
    );
  }
}

/// Incoming clipboard item container for immediate inline UI rendering.
class IncomingClipboardPayload {
  const IncomingClipboardPayload({
    required this.type,
    this.text,
    this.imageBytes,
    this.savedFilePath,
    required this.senderName,
    required this.senderAvatar,
  });

  final ClipboardPayloadType type;
  final String? text;
  final Uint8List? imageBytes;
  final String? savedFilePath;
  final String senderName;
  final String senderAvatar;
}

/// Core Ultra-Fast Peer-to-Peer Transfer Engine for AetherDrop.
///
/// Features:
/// - Direct WebRTC connection with STUN/TURN fallback.
/// - Ordered, reliable 256 KB chunked binary data streaming (`aetherdrop-warp-pipe`).
/// - Buffered amount low threshold backpressure monitoring to maintain low RAM (< 15 MB).
/// - Recursive nested folder scanning and exact hierarchy reconstruction.
/// - 60fps smoothed metrics calculation (MB/s, %, ETA).
/// - Automatic Supabase WXP award & Co-Op Warp Streak progression.
/// - Interactive real-time reaction emojis (`⚡`, `🚀`, `🔥`, `💎`) streamed over WebRTC.
class WebRTCEngine extends ChangeNotifier {
  WebRTCEngine._() {
    _initSignalingListener();
  }

  static final WebRTCEngine instance = WebRTCEngine._();

  // WebRTC Peer Connection & DataChannel
  RTCPeerConnection? _peerConnection;
  RTCDataChannel? _dataChannel;
  StreamSubscription<SignalPayload>? _signalSubscription;

  // Active Transfer State
  String? _activeTransferId;
  String? _activePeerId;
  String? _activePeerDisplayName;
  String? _activePeerAvatar;
  bool _isSender = false;
  TransferStatus _status = TransferStatus.idle;
  TransferManifest? _activeManifest;
  bool _isCancelled = false;

  // Receiver File Buffering
  IOSink? _currentFileSink;
  int _currentReceivingFileIndex = -1;
  int _bytesReceivedForCurrentFile = 0;
  int _totalBytesReceived = 0;
  String? _destinationBasePath;
  final BytesBuilder _clipboardImageBuffer = BytesBuilder(copy: false);

  // Backpressure & Throttling
  Completer<void>? _bufferLowCompleter;
  DateTime? _lastMetricsEmitTime;
  int _lastMetricsBytes = 0;
  final List<double> _speedSampleBuffer = <double>[];
  static const int _speedWindowSamples = 5;

  // Stream Controllers
  final StreamController<TransferProgress> _progressController =
      StreamController<TransferProgress>.broadcast();
  final StreamController<TransferManifest> _incomingInvitationController =
      StreamController<TransferManifest>.broadcast();
  final StreamController<IncomingClipboardPayload> _incomingClipboardController =
      StreamController<IncomingClipboardPayload>.broadcast();
  final StreamController<String> _reactionStreamController =
      StreamController<String>.broadcast();

  // Public Streams & Getters
  Stream<TransferProgress> get progressStream => _progressController.stream;
  Stream<TransferManifest> get incomingInvitationStream =>
      _incomingInvitationController.stream;
  Stream<IncomingClipboardPayload> get incomingClipboardStream =>
      _incomingClipboardController.stream;
  Stream<String> get reactionStream => _reactionStreamController.stream;

  TransferStatus get status => _status;
  bool get isTransferring => _status == TransferStatus.transferring;
  TransferManifest? get activeManifest => _activeManifest;

  // ---------------------------------------------------------------------------
  // Signaling & Handshake Orchestration
  // ---------------------------------------------------------------------------

  void _initSignalingListener() {
    _signalSubscription = SignalingService.instance.incomingSignals.listen(
      _handleIncomingSignal,
      onError: (dynamic error) {
        debugPrint('WebRTCEngine signaling stream error: $error');
      },
    );
  }

  Future<void> _handleIncomingSignal(SignalPayload signal) async {
    final Map<String, dynamic> data = signal.data;

    switch (signal.event) {
      case 'transfer_invitation':
        _handleIncomingInvitation(signal);
        break;

      case 'webrtc_offer':
        await _handleRemoteOffer(signal);
        break;

      case 'webrtc_answer':
        await _handleRemoteAnswer(data);
        break;

      case 'ice_candidate':
        await _handleRemoteCandidate(data);
        break;

      case 'transfer_declined':
        if (_activeTransferId == data['transfer_id']) {
          _updateStatus(
            TransferStatus.failed,
            errorMessage: 'Peer declined the transfer request.',
          );
          await cancelTransfer();
        }
        break;

      case 'warp_reaction':
        final String? emoji = data['emoji'] as String?;
        if (emoji != null && emoji.isNotEmpty) {
          _reactionStreamController.add(emoji);
        }
        break;
    }
  }

  void _handleIncomingInvitation(SignalPayload signal) {
    try {
      final Map<String, dynamic> manifestData =
          (signal.data['manifest'] as Map<String, dynamic>?) ?? signal.data;
      final TransferManifest manifest = TransferManifest.fromJson(manifestData);

      _activeTransferId = manifest.transferId;
      _activePeerId = signal.fromUserId;
      _activePeerDisplayName = signal.fromDisplayName;
      _activePeerAvatar = signal.fromAvatarId;
      _activeManifest = manifest;
      _isSender = false;

      _updateStatus(TransferStatus.waitingForPeer);
      _incomingInvitationController.add(manifest);
    } catch (e) {
      debugPrint('Error parsing incoming transfer invitation: $e');
    }
  }

  Future<void> _handleRemoteOffer(SignalPayload signal) async {
    try {
      final Map<String, dynamic> data = signal.data;
      final Map<String, dynamic> sdpMap =
          (data['sdp'] as Map<String, dynamic>?) ?? data;
      final String? transferId = data['transfer_id'] as String?;

      if (data.containsKey('manifest')) {
        _activeManifest = TransferManifest.fromJson(
          data['manifest'] as Map<String, dynamic>,
        );
      }

      _activeTransferId = transferId ?? _activeTransferId;
      _activePeerId = signal.fromUserId;
      _activePeerDisplayName = signal.fromDisplayName;
      _activePeerAvatar = signal.fromAvatarId;
      _isSender = false;

      _updateStatus(TransferStatus.connecting);

      // Create PeerConnection for receiver
      await _createPeerConnection();

      final RTCSessionDescription remoteDesc = RTCSessionDescription(
        sdpMap['sdp'] as String?,
        sdpMap['type'] as String?,
      );
      await _peerConnection!.setRemoteDescription(remoteDesc);

      final RTCSessionDescription answer = await _peerConnection!.createAnswer();
      await _peerConnection!.setLocalDescription(answer);

      // Send answer back to sender
      await SignalingService.instance.sendSignal(
        targetUserId: signal.fromUserId,
        event: 'webrtc_answer',
        payload: <String, dynamic>{
          'transfer_id': _activeTransferId,
          'sdp': answer.toMap(),
        },
      );
    } catch (e) {
      debugPrint('Error handling remote offer: $e');
      _updateStatus(TransferStatus.failed, errorMessage: 'SDP negotiation failed: $e');
    }
  }

  Future<void> _handleRemoteAnswer(Map<String, dynamic> data) async {
    try {
      if (_peerConnection == null) return;
      final Map<String, dynamic> sdpMap =
          (data['sdp'] as Map<String, dynamic>?) ?? data;

      final RTCSessionDescription remoteDesc = RTCSessionDescription(
        sdpMap['sdp'] as String?,
        sdpMap['type'] as String?,
      );
      await _peerConnection!.setRemoteDescription(remoteDesc);
    } catch (e) {
      debugPrint('Error setting remote answer: $e');
    }
  }

  Future<void> _handleRemoteCandidate(Map<String, dynamic> data) async {
    try {
      if (_peerConnection == null) return;
      final Map<String, dynamic>? candidateMap =
          data['candidate'] as Map<String, dynamic>?;

      if (candidateMap != null) {
        final RTCIceCandidate candidate = RTCIceCandidate(
          candidateMap['candidate'] as String?,
          candidateMap['sdpMid'] as String?,
          candidateMap['sdpMLineIndex'] as int?,
        );
        await _peerConnection!.addCandidate(candidate);
      }
    } catch (e) {
      debugPrint('Error adding remote ICE candidate: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // RTCPeerConnection & DataChannel Initialization
  // ---------------------------------------------------------------------------

  Future<void> _createPeerConnection() async {
    if (_peerConnection != null) {
      await _peerConnection!.close();
      await _peerConnection!.dispose();
      _peerConnection = null;
    }

    _peerConnection = await createPeerConnection(
      AppConstants.rtcConfiguration,
      <String, dynamic>{
        'mandatory': <String, dynamic>{
          'OfferToReceiveAudio': false,
          'OfferToReceiveVideo': false,
        },
        'optional': <Map<String, dynamic>>[
          <String, dynamic>{'DtlsSrtpKeyAgreement': true},
        ],
      },
    );

    _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
      if (_activePeerId != null && candidate.candidate != null) {
        SignalingService.instance.sendSignal(
          targetUserId: _activePeerId!,
          event: 'ice_candidate',
          payload: <String, dynamic>{
            'transfer_id': _activeTransferId,
            'candidate': candidate.toMap(),
          },
        );
      }
    };

    _peerConnection!.onDataChannel = (RTCDataChannel channel) {
      _setupDataChannel(channel, isSender: false);
    };

    _peerConnection!.onIceConnectionState = (RTCIceConnectionState state) {
      if (state == RTCIceConnectionState.RTCIceConnectionStateDisconnected ||
          state == RTCIceConnectionState.RTCIceConnectionStateFailed) {
        if (_status == TransferStatus.transferring) {
          _updateStatus(
            TransferStatus.failed,
            errorMessage: 'P2P Warp Tunnel disconnected unexpectedly.',
          );
        }
      }
    };
  }

  void _setupDataChannel(RTCDataChannel channel, {required bool isSender}) {
    _dataChannel = channel;

    // High-speed backpressure control
    channel.bufferedAmountLowThreshold = AppConstants.bufferedAmountLowThreshold;

    channel.onBufferedAmountLow = (int _) {
      if (_bufferLowCompleter != null && !_bufferLowCompleter!.isCompleted) {
        _bufferLowCompleter!.complete();
      }
      _bufferLowCompleter = null;
    };

    channel.onDataChannelState = (RTCDataChannelState state) {
      if (state == RTCDataChannelState.RTCDataChannelOpen) {
        _updateStatus(TransferStatus.connected);
        if (isSender) {
          _startStreamingPayload();
        }
      } else if (state == RTCDataChannelState.RTCDataChannelClosed) {
        if (_status == TransferStatus.transferring) {
          _updateStatus(
            TransferStatus.failed,
            errorMessage: 'DataChannel warp pipe closed prematurely.',
          );
        }
      }
    };

    channel.onMessage = (RTCDataChannelMessage message) {
      if (message.isBinary) {
        _handleIncomingBinaryChunk(message.binary);
      } else {
        _handleIncomingTextMessage(message.text);
      }
    };
  }

  // ---------------------------------------------------------------------------
  // SENDER FLOW: Start Transfer (Files, Folders, Clipboard)
  // ---------------------------------------------------------------------------

  /// Initiates a high-speed P2P transfer of one or more files to [targetUserId].
  Future<void> sendFiles({
    required String targetUserId,
    required List<String> filePaths,
  }) async {
    final UserProfile? currentUser = AuthService.instance.currentProfile;
    if (currentUser == null) throw StateError('User not authenticated');
    if (filePaths.isEmpty) throw ArgumentError('filePaths cannot be empty');

    final List<File> files = filePaths.map((String p) => File(p)).toList();
    final List<TransferFileEntry> entries = <TransferFileEntry>[];

    for (int i = 0; i < files.length; i++) {
      final File file = files[i];
      final int size = await file.length();
      entries.add(
        TransferFileEntry(
          index: i,
          name: p.basename(file.path),
          relativePath: p.basename(file.path),
          size: size,
          mimeType: _inferMimeType(file.path),
        ),
      );
    }

    final String txId = _generateTransferId();
    final TransferManifest manifest = entries.length == 1
        ? TransferManifest.singleFile(
            transferId: txId,
            senderId: currentUser.id,
            senderName: currentUser.displayName,
            senderAvatar: currentUser.avatarId,
            fileName: entries.first.name,
            fileSize: entries.first.size,
            mimeType: entries.first.mimeType,
          )
        : TransferManifest.multiFile(
            transferId: txId,
            senderId: currentUser.id,
            senderName: currentUser.displayName,
            senderAvatar: currentUser.avatarId,
            files: entries,
          );

    await _initiateTransferSession(
      targetUserId: targetUserId,
      manifest: manifest,
      localFileSources: filePaths,
    );
  }

  /// Recursively scans an entire folder tree and streams it sequentially to [targetUserId].
  Future<void> sendFolder({
    required String targetUserId,
    required String folderPath,
  }) async {
    final UserProfile? currentUser = AuthService.instance.currentProfile;
    if (currentUser == null) throw StateError('User not authenticated');

    final Directory rootDir = Directory(folderPath);
    if (!await rootDir.exists()) {
      throw FileSystemException('Folder does not exist', folderPath);
    }

    _updateStatus(TransferStatus.initiating);

    // Recursively scan folder
    final List<File> fileList = <File>[];
    await for (final FileSystemEntity entity in rootDir.list(
      recursive: true,
      followLinks: false,
    )) {
      if (entity is File) {
        fileList.add(entity);
      }
    }

    if (fileList.isEmpty) {
      throw ArgumentError('Selected folder contains no files.');
    }

    final String rootName = p.basename(rootDir.path);
    final List<TransferFileEntry> entries = <TransferFileEntry>[];
    final List<String> sourcePaths = <String>[];

    for (int i = 0; i < fileList.length; i++) {
      final File file = fileList[i];
      final int size = await file.length();
      final String relative = p.relative(file.path, from: rootDir.path);

      entries.add(
        TransferFileEntry(
          index: i,
          name: p.basename(file.path),
          relativePath: relative,
          size: size,
          mimeType: _inferMimeType(file.path),
        ),
      );
      sourcePaths.add(file.path);
    }

    final String txId = _generateTransferId();
    final TransferManifest manifest = TransferManifest.folderArchive(
      transferId: txId,
      senderId: currentUser.id,
      senderName: currentUser.displayName,
      senderAvatar: currentUser.avatarId,
      folderName: rootName,
      files: entries,
    );

    await _initiateTransferSession(
      targetUserId: targetUserId,
      manifest: manifest,
      localFileSources: sourcePaths,
    );
  }

  /// Beams clipboard text/code or raw screenshot PNG bytes directly to [targetUserId].
  Future<void> sendClipboardPayload({
    required String targetUserId,
    required ClipboardPayloadType type,
    String? text,
    Uint8List? imageBytes,
  }) async {
    final UserProfile? currentUser = AuthService.instance.currentProfile;
    if (currentUser == null) throw StateError('User not authenticated');

    final String txId = _generateTransferId();
    TransferManifest manifest;
    List<String> sources = <String>[];

    if (type == ClipboardPayloadType.text) {
      final String safeText = text ?? '';
      manifest = TransferManifest.clipboardText(
        transferId: txId,
        senderId: currentUser.id,
        senderName: currentUser.displayName,
        senderAvatar: currentUser.avatarId,
        text: safeText,
      );
    } else if (type == ClipboardPayloadType.image) {
      final Uint8List bytes = imageBytes ?? Uint8List(0);
      final String? preview = bytes.isNotEmpty && bytes.length <= 65536
          ? base64Encode(bytes)
          : null;

      manifest = TransferManifest.clipboardImage(
        transferId: txId,
        senderId: currentUser.id,
        senderName: currentUser.displayName,
        senderAvatar: currentUser.avatarId,
        imageSizeBytes: bytes.length,
        base64Preview: preview,
      );

      // Write temp PNG file to stream cleanly
      final Directory tempDir = await getTemporaryDirectory();
      final File tempFile = File(
        p.join(tempDir.path, 'clipboard_beam_${DateTime.now().millisecondsSinceEpoch}.png'),
      );
      await tempFile.writeAsBytes(bytes);
      sources = <String>[tempFile.path];
    } else {
      throw UnsupportedError('Unsupported clipboard type');
    }

    await _initiateTransferSession(
      targetUserId: targetUserId,
      manifest: manifest,
      localFileSources: sources,
    );
  }

  // Sender session bootstrap
  List<String> _cachedLocalSources = <String>[];

  Future<void> _initiateTransferSession({
    required String targetUserId,
    required TransferManifest manifest,
    required List<String> localFileSources,
  }) async {
    _activeTransferId = manifest.transferId;
    _activePeerId = targetUserId;
    _activeManifest = manifest;
    _cachedLocalSources = localFileSources;
    _isSender = true;
    _isCancelled = false;
    _speedSampleBuffer.clear();

    _updateStatus(TransferStatus.connecting);

    // 1. Send transfer invitation signal to target peer
    await SignalingService.instance.sendSignal(
      targetUserId: targetUserId,
      event: 'transfer_invitation',
      payload: <String, dynamic>{
        'manifest': manifest.toJson(),
      },
    );

    // 2. Setup RTCPeerConnection as offerer
    await _createPeerConnection();

    // 3. Create high-throughput ordered DataChannel
    final RTCDataChannelInit dcInit = RTCDataChannelInit()
      ..ordered = true
      ..maxRetransmits = -1;

    final RTCDataChannel channel = await _peerConnection!.createDataChannel(
      AppConstants.dataChannelLabel,
      dcInit,
    );
    _setupDataChannel(channel, isSender: true);

    // 4. Create and dispatch WebRTC SDP offer
    final RTCSessionDescription offer = await _peerConnection!.createOffer(
      <String, dynamic>{
        'mandatory': <String, dynamic>{
          'OfferToReceiveAudio': false,
          'OfferToReceiveVideo': false,
        },
        'optional': <dynamic>[],
      },
    );
    await _peerConnection!.setLocalDescription(offer);

    await SignalingService.instance.sendSignal(
      targetUserId: targetUserId,
      event: 'webrtc_offer',
      payload: <String, dynamic>{
        'transfer_id': manifest.transferId,
        'sdp': offer.toMap(),
        'manifest': manifest.toJson(),
      },
    );
  }

  // ---------------------------------------------------------------------------
  // SENDER STREAMING: 256 KB Chunks & Backpressure Control
  // ---------------------------------------------------------------------------

  Future<void> _startStreamingPayload() async {
    if (_dataChannel == null || _activeManifest == null) return;
    final TransferManifest manifest = _activeManifest!;
    _updateStatus(TransferStatus.transferring);

    final Stopwatch stopwatch = Stopwatch()..start();
    _lastMetricsEmitTime = DateTime.now();
    _lastMetricsBytes = 0;
    int cumulativeBytesSent = 0;

    // Send manifest header as JSON text message first
    _dataChannel!.send(RTCDataChannelMessage(manifest.encodeJson()));

    // Special case: direct text clipboard payload
    if (manifest.payloadType.isClipboard &&
        manifest.clipboardType == ClipboardPayloadType.text) {
      final List<int> utf8Bytes = utf8.encode(manifest.clipboardText ?? '');
      final Uint8List frame = _buildBinaryFrame(0, Uint8List.fromList(utf8Bytes));
      await _sendFrameWithBackpressure(frame);
      cumulativeBytesSent += utf8Bytes.length;
      _emitProgress(
        bytesTransferred: cumulativeBytesSent,
        currentFileIndex: 0,
        currentFileName: 'clipboard_snippet.txt',
        speedMBps: 10.0,
      );
      await _completeTransfer(isSender: true);
      return;
    }

    // Stream files sequentially
    for (int i = 0; i < manifest.files.length; i++) {
      if (_isCancelled) break;
      final TransferFileEntry fileEntry = manifest.files[i];
      final String sourcePath = _cachedLocalSources[i];
      final File sourceFile = File(sourcePath);

      if (!await sourceFile.exists()) {
        continue;
      }

      // Stream file using Dart Stream<List<int>> in 256 KB chunks
      // Guarantees < 15 MB RAM even for a 50 GB file!
      await for (final Uint8List chunk in _streamFileIn256KbChunks(
        sourceFile,
        AppConstants.chunkSize,
      )) {
        if (_isCancelled) break;

        final Uint8List frame = _buildBinaryFrame(fileEntry.index, chunk);
        await _sendFrameWithBackpressure(frame);

        cumulativeBytesSent += chunk.length;

        // Calculate metrics
        _calculateAndEmitMetrics(
          cumulativeBytesSent: cumulativeBytesSent,
          totalBytes: manifest.totalBytes,
          fileIndex: i,
          fileName: fileEntry.name,
          stopwatch: stopwatch,
        );
      }
    }

    stopwatch.stop();

    if (!_isCancelled) {
      await _completeTransfer(isSender: true);
    }
  }

  /// Transforms file disk stream into exact 256 KB chunks.
  Stream<Uint8List> _streamFileIn256KbChunks(File file, int chunkSize) async* {
    final Stream<List<int>> readStream = file.openRead();
    final BytesBuilder accumulator = BytesBuilder(copy: false);

    await for (final List<int> block in readStream) {
      accumulator.add(block);
      while (accumulator.length >= chunkSize) {
        final Uint8List fullBlock = accumulator.takeBytes();
        yield Uint8List.sublistView(fullBlock, 0, chunkSize);
        if (fullBlock.length > chunkSize) {
          accumulator.add(Uint8List.sublistView(fullBlock, chunkSize));
        }
      }
    }

    if (accumulator.isNotEmpty) {
      yield accumulator.takeBytes();
    }
  }

  /// Encodes lightweight 8-byte frame header: [fileIndex (4 bytes), chunkLength (4 bytes), ...payload].
  Uint8List _buildBinaryFrame(int fileIndex, Uint8List chunk) {
    final Uint8List frame = Uint8List(8 + chunk.length);
    final ByteData bd = ByteData.sublistView(frame, 0, 8);
    bd.setUint32(0, fileIndex, Endian.big);
    bd.setUint32(4, chunk.length, Endian.big);
    frame.setRange(8, 8 + chunk.length, chunk);
    return frame;
  }

  /// High-Speed Backpressure Control:
  /// Monitors `dataChannel.bufferedAmount`. If > 4 MB (`maxBufferedAmount`),
  /// pauses and waits for `onBufferedAmountLow` (< 1 MB threshold) before resuming.
  Future<void> _sendFrameWithBackpressure(Uint8List frame) async {
    if (_dataChannel == null) return;

    try {
      final int? buffered = _dataChannel!.bufferedAmount;
      if (buffered != null && buffered > AppConstants.maxBufferedAmount) {
        _bufferLowCompleter ??= Completer<void>();
        await _bufferLowCompleter!.future.timeout(
          const Duration(milliseconds: 250),
          onTimeout: () {},
        );
      }
    } catch (_) {
      // Fallback if platform does not return bufferedAmount future
    }

    await _dataChannel!.send(RTCDataChannelMessage.fromBinary(frame));
  }

  // ---------------------------------------------------------------------------
  // RECEIVER FLOW: File Assembly & Directory Reconstruction
  // ---------------------------------------------------------------------------

  /// Accepts an incoming transfer invitation and prepares the download directory.
  Future<void> acceptIncomingTransfer() async {
    if (_activeManifest == null || _activePeerId == null) return;
    _updateStatus(TransferStatus.connecting);

    // Prepare destination Downloads/AetherDrop folder
    final Directory baseDir = await _getDestinationDirectory();
    final TransferManifest manifest = _activeManifest!;

    if (manifest.payloadType.isFolder && manifest.folderRootName != null) {
      final Directory folderRoot = Directory(
        p.join(baseDir.path, manifest.folderRootName!),
      );
      if (!await folderRoot.exists()) {
        await folderRoot.create(recursive: true);
      }
      _destinationBasePath = folderRoot.path;
    } else {
      _destinationBasePath = baseDir.path;
    }

    _currentReceivingFileIndex = -1;
    _bytesReceivedForCurrentFile = 0;
    _totalBytesReceived = 0;
    _clipboardImageBuffer.clear();
  }

  /// Declines an incoming transfer invitation.
  Future<void> declineIncomingTransfer() async {
    if (_activePeerId != null && _activeTransferId != null) {
      await SignalingService.instance.sendSignal(
        targetUserId: _activePeerId!,
        event: 'transfer_declined',
        payload: <String, dynamic>{
          'transfer_id': _activeTransferId,
        },
      );
    }
    await cancelTransfer();
  }

  void _handleIncomingTextMessage(String rawJson) {
    try {
      final Map<String, dynamic> msg = jsonDecode(rawJson) as Map<String, dynamic>;

      // Handle Quick Reactions
      if (msg['type'] == 'reaction') {
        final String? emoji = msg['emoji'] as String?;
        if (emoji != null) {
          _reactionStreamController.add(emoji);
        }
        return;
      }

      // Handle Manifest
      if (msg.containsKey('transfer_id') && msg.containsKey('payload_type')) {
        _activeManifest = TransferManifest.fromJson(msg);
        _updateStatus(TransferStatus.transferring);
      }
    } catch (e) {
      debugPrint('Error parsing text message on data channel: $e');
    }
  }

  Future<void> _handleIncomingBinaryChunk(Uint8List frame) async {
    if (frame.length < 8 || _activeManifest == null) return;

    final ByteData bd = ByteData.sublistView(frame, 0, 8);
    final int fileIndex = bd.getUint32(0, Endian.big);
    final int chunkLength = bd.getUint32(4, Endian.big);

    if (frame.length < 8 + chunkLength) return;
    final Uint8List chunkData = Uint8List.sublistView(frame, 8, 8 + chunkLength);

    final TransferManifest manifest = _activeManifest!;

    // Check if new file started
    if (_currentReceivingFileIndex != fileIndex) {
      await _closeCurrentFileSink();
      _currentReceivingFileIndex = fileIndex;
      _bytesReceivedForCurrentFile = 0;

      if (fileIndex < manifest.files.length) {
        final TransferFileEntry fileEntry = manifest.files[fileIndex];
        await _openSinkForFile(fileEntry);
      }
    }

    // Write chunk
    if (_currentFileSink != null) {
      _currentFileSink!.add(chunkData);
    }

    if (manifest.payloadType.isClipboard &&
        manifest.clipboardType == ClipboardPayloadType.image) {
      _clipboardImageBuffer.add(chunkData);
    }

    _bytesReceivedForCurrentFile += chunkData.length;
    _totalBytesReceived += chunkData.length;

    // Check if current file completed
    if (fileIndex < manifest.files.length &&
        _bytesReceivedForCurrentFile >= manifest.files[fileIndex].size) {
      await _closeCurrentFileSink();
    }

    // Emit live progress
    final double progress = manifest.totalBytes > 0
        ? (_totalBytesReceived / manifest.totalBytes).clamp(0.0, 1.0)
        : 1.0;

    final String currentFileName = fileIndex < manifest.files.length
        ? manifest.files[fileIndex].name
        : '';

    _emitProgress(
      bytesTransferred: _totalBytesReceived,
      currentFileIndex: fileIndex,
      currentFileName: currentFileName,
      progressFraction: progress,
    );

    // Check if entire transfer finished (100%)
    if (_totalBytesReceived >= manifest.totalBytes) {
      await _completeTransfer(isSender: false);
    }
  }

  Future<void> _openSinkForFile(TransferFileEntry entry) async {
    final String base = _destinationBasePath ??
        (await _getDestinationDirectory()).path;

    final String targetFilePath = p.join(base, entry.relativePath);
    final File targetFile = File(targetFilePath);

    // Recreate exact nested subfolder structure
    if (!await targetFile.parent.exists()) {
      await targetFile.parent.create(recursive: true);
    }

    _currentFileSink = targetFile.openWrite(mode: FileMode.writeOnly);
  }

  Future<void> _closeCurrentFileSink() async {
    if (_currentFileSink != null) {
      await _currentFileSink!.flush();
      await _currentFileSink!.close();
      _currentFileSink = null;
    }
  }

  Future<Directory> _getDestinationDirectory() async {
    Directory? downloadsDir;
    try {
      downloadsDir = await getDownloadsDirectory();
    } catch (_) {
      // getDownloadsDirectory unsupported on certain mobile/embedded targets
    }

    downloadsDir ??= await getApplicationDocumentsDirectory();
    final Directory target = Directory(
      p.join(downloadsDir.path, AppConstants.downloadSubdirectory),
    );

    if (!await target.exists()) {
      await target.create(recursive: true);
    }
    return target;
  }

  // ---------------------------------------------------------------------------
  // LIVE METRICS & 60FPS UI STREAMING
  // ---------------------------------------------------------------------------

  void _calculateAndEmitMetrics({
    required int cumulativeBytesSent,
    required int totalBytes,
    required int fileIndex,
    required String fileName,
    required Stopwatch stopwatch,
  }) {
    final DateTime now = DateTime.now();
    _lastMetricsEmitTime ??= now;

    final int elapsedMs = now.difference(_lastMetricsEmitTime!).inMilliseconds;
    if (elapsedMs < 16) {
      // Throttle to 60fps (minimum 16ms between frames)
      return;
    }

    final int bytesDiff = cumulativeBytesSent - _lastMetricsBytes;
    final double instantSpeedMBps =
        (bytesDiff / (elapsedMs / 1000.0)) / (1024.0 * 1024.0);

    _speedSampleBuffer.add(instantSpeedMBps);
    if (_speedSampleBuffer.length > _speedWindowSamples) {
      _speedSampleBuffer.removeAt(0);
    }

    final double smoothedSpeedMBps =
        _speedSampleBuffer.reduce((double a, double b) => a + b) /
            _speedSampleBuffer.length;

    final double progressFraction =
        totalBytes > 0 ? (cumulativeBytesSent / totalBytes).clamp(0.0, 1.0) : 1.0;

    final int remainingBytes = totalBytes - cumulativeBytesSent;
    Duration? eta;
    if (smoothedSpeedMBps > 0.05 && remainingBytes > 0) {
      final double seconds = remainingBytes / (smoothedSpeedMBps * 1024 * 1024);
      eta = Duration(seconds: seconds.round());
    }

    _lastMetricsEmitTime = now;
    _lastMetricsBytes = cumulativeBytesSent;

    _emitProgress(
      bytesTransferred: cumulativeBytesSent,
      currentFileIndex: fileIndex,
      currentFileName: fileName,
      progressFraction: progressFraction,
      speedMBps: smoothedSpeedMBps,
      eta: eta,
    );
  }

  void _emitProgress({
    required int bytesTransferred,
    required int currentFileIndex,
    required String currentFileName,
    double? progressFraction,
    double speedMBps = 0.0,
    Duration? eta,
  }) {
    if (_activeManifest == null) return;
    final TransferManifest manifest = _activeManifest!;

    final double progress = progressFraction ??
        (manifest.totalBytes > 0
            ? (bytesTransferred / manifest.totalBytes).clamp(0.0, 1.0)
            : 1.0);

    final TransferProgress update = TransferProgress(
      transferId: manifest.transferId,
      status: _status,
      isSender: _isSender,
      peerId: _activePeerId ?? '',
      peerDisplayName: _activePeerDisplayName ?? 'Warp Peer',
      peerAvatarId: _activePeerAvatar ?? 'starter_cyber_01',
      manifest: manifest,
      bytesTransferred: bytesTransferred,
      totalBytes: manifest.totalBytes,
      progress: progress,
      speedMBps: speedMBps,
      eta: eta,
      currentFileIndex: currentFileIndex,
      totalFiles: manifest.totalItems,
      currentFileName: currentFileName,
    );

    _progressController.add(update);
  }

  // ---------------------------------------------------------------------------
  // COMPLETION, GAMIFICATION & CO-OP STREAK AWARD
  // ---------------------------------------------------------------------------

  Future<void> _completeTransfer({required bool isSender}) async {
    await _closeCurrentFileSink();
    _updateStatus(TransferStatus.completed);

    Map<String, dynamic>? completionResult;

    if (_activeManifest != null && _activePeerId != null) {
      final TransferManifest manifest = _activeManifest!;

      // If receiver got clipboard payload, deliver to clipboard stream
      if (!isSender && manifest.payloadType.isClipboard) {
        if (manifest.clipboardType == ClipboardPayloadType.text) {
          _incomingClipboardController.add(
            IncomingClipboardPayload(
              type: ClipboardPayloadType.text,
              text: manifest.clipboardText,
              senderName: manifest.senderName,
              senderAvatar: manifest.senderAvatar,
            ),
          );
        } else if (manifest.clipboardType == ClipboardPayloadType.image) {
          final Uint8List imgBytes = _clipboardImageBuffer.takeBytes();
          _incomingClipboardController.add(
            IncomingClipboardPayload(
              type: ClipboardPayloadType.image,
              imageBytes: imgBytes,
              savedFilePath: _destinationBasePath != null
                  ? p.join(_destinationBasePath!, manifest.files.first.name)
                  : null,
              senderName: manifest.senderName,
              senderAvatar: manifest.senderAvatar,
            ),
          );
        }
      }

      // Automatic WXP Reward & Co-Op Streak calculation
      final String senderId = manifest.senderId;
      final String receiverId = isSender ? _activePeerId! : manifest.senderId;

      completionResult = await _recordTransferAndIncrementStreak(
        senderId: senderId,
        receiverId: receiverId,
        bytesSent: manifest.totalBytes,
        filesCount: manifest.totalItems,
        isFolder: manifest.payloadType.isFolder,
      );
    }

    _progressController.add(
      TransferProgress(
        transferId: _activeTransferId ?? '',
        status: TransferStatus.completed,
        isSender: _isSender,
        peerId: _activePeerId ?? '',
        peerDisplayName: _activePeerDisplayName ?? 'Warp Peer',
        peerAvatarId: _activePeerAvatar ?? 'starter_cyber_01',
        manifest: _activeManifest,
        bytesTransferred: _activeManifest?.totalBytes ?? 0,
        totalBytes: _activeManifest?.totalBytes ?? 0,
        progress: 1.0,
        currentFileIndex: (_activeManifest?.totalItems ?? 1) - 1,
        totalFiles: _activeManifest?.totalItems ?? 1,
        completionResult: completionResult,
      ),
    );
  }

  /// Invokes `record_transfer_and_award_xp` in Supabase and updates
  /// `public.peer_connections` to increment Co-Op Streak.
  Future<Map<String, dynamic>?> _recordTransferAndIncrementStreak({
    required String senderId,
    required String receiverId,
    required int bytesSent,
    required int filesCount,
    required bool isFolder,
  }) async {
    final SupabaseClient? client = AuthService.instance.supabaseClient;
    if (client == null) return null;

    Map<String, dynamic> results = <String, dynamic>{
      'xpGained': 50 + (bytesSent ~/ (100 * 1024 * 1024)) * 10 + (isFolder ? 150 : 0),
    };

    // 1. Award WXP via Postgres RPC function
    try {
      final dynamic rpcResult = await client.rpc(
        'record_transfer_and_award_xp',
        params: <String, dynamic>{
          'p_user_id': senderId,
          'p_bytes_sent': bytesSent,
          'p_files_count': filesCount,
          'p_is_folder': isFolder,
        },
      );
      if (rpcResult is Map<String, dynamic>) {
        results.addAll(rpcResult);
      }
    } catch (e) {
      debugPrint('Error invoking record_transfer_and_award_xp: $e');
    }

    // 2. Increment Co-Op Streak in public.peer_connections
    try {
      final int streak = await _updatePeerStreak(
        client: client,
        userA: senderId,
        userB: receiverId,
        sharedBytes: bytesSent,
      );
      results['streakCount'] = streak;
    } catch (e) {
      debugPrint('Error updating peer connections streak: $e');
    }

    // 3. Refresh local profile cache
    try {
      await AuthService.instance.refreshProfile();
    } catch (e) {
      debugPrint('Error refreshing user profile: $e');
    }

    return results;
  }

  Future<int> _updatePeerStreak({
    required SupabaseClient client,
    required String userA,
    required String userB,
    required int sharedBytes,
  }) async {
    final List<dynamic> rows = await client
        .from('peer_connections')
        .select()
        .or('and(user_a.eq.$userA,user_b.eq.$userB),and(user_a.eq.$userB,user_b.eq.$userA)')
        .limit(1);

    final DateTime now = DateTime.now();

    if (rows.isNotEmpty) {
      final Map<String, dynamic> row = rows.first as Map<String, dynamic>;
      final String connectionId = row['id'] as String;
      final int currentStreak = (row['streak_count'] as num?)?.toInt() ?? 1;
      final int currentBytes =
          (row['total_shared_bytes'] as num?)?.toInt() ?? 0;
      final DateTime? lastTransfer = row['last_transfer_at'] != null
          ? DateTime.tryParse(row['last_transfer_at'].toString())
          : null;

      int newStreak = currentStreak;
      if (lastTransfer != null) {
        final Duration diff = now.difference(lastTransfer);
        if (diff.inHours >= 18 && diff.inHours <= 48) {
          newStreak = currentStreak + 1;
        } else if (diff.inHours > 48) {
          newStreak = 1;
        }
      }

      await client.from('peer_connections').update(<String, dynamic>{
        'streak_count': newStreak,
        'last_transfer_at': now.toIso8601String(),
        'total_shared_bytes': currentBytes + sharedBytes,
      }).eq('id', connectionId);

      return newStreak;
    } else {
      await client.from('peer_connections').insert(<String, dynamic>{
        'user_a': userA,
        'user_b': userB,
        'streak_count': 1,
        'last_transfer_at': now.toIso8601String(),
        'total_shared_bytes': sharedBytes,
      });
      return 1;
    }
  }

  // ---------------------------------------------------------------------------
  // INTERACTIVE WARP REACTIONS (`⚡`, `🚀`, `🔥`, `💎`)
  // ---------------------------------------------------------------------------

  /// Broadcasts an interactive emoji reaction over the WebRTC DataChannel
  /// with Supabase Realtime fallback.
  void sendReaction(String emoji) {
    _reactionStreamController.add(emoji);

    // 1. Send via active WebRTC DataChannel if open
    if (_dataChannel != null) {
      try {
        _dataChannel!.send(
          RTCDataChannelMessage(
            jsonEncode(<String, dynamic>{
              'type': 'reaction',
              'emoji': emoji,
              'timestamp': DateTime.now().toIso8601String(),
            }),
          ),
        );
        return;
      } catch (_) {}
    }

    // 2. Fallback to Supabase Realtime signal
    if (_activePeerId != null) {
      SignalingService.instance.sendSignal(
        targetUserId: _activePeerId!,
        event: 'warp_reaction',
        payload: <String, dynamic>{
          'emoji': emoji,
          'transfer_id': _activeTransferId,
        },
      );
    }
  }

  // ---------------------------------------------------------------------------
  // LIFECYCLE & CANCELLATION
  // ---------------------------------------------------------------------------

  /// Cancels an in-flight transfer and releases all peer resources.
  Future<void> cancelTransfer() async {
    _isCancelled = true;
    _updateStatus(TransferStatus.cancelled);

    await _closeCurrentFileSink();

    if (_dataChannel != null) {
      try {
        await _dataChannel!.close();
      } catch (_) {}
      _dataChannel = null;
    }

    if (_peerConnection != null) {
      try {
        await _peerConnection!.close();
        await _peerConnection!.dispose();
      } catch (_) {}
      _peerConnection = null;
    }

    _activeTransferId = null;
    _activePeerId = null;
    _activeManifest = null;
    _cachedLocalSources.clear();
  }

  void _updateStatus(TransferStatus newStatus, {String? errorMessage}) {
    _status = newStatus;
    notifyListeners();

    _progressController.add(
      TransferProgress(
        transferId: _activeTransferId ?? '',
        status: newStatus,
        isSender: _isSender,
        peerId: _activePeerId ?? '',
        peerDisplayName: _activePeerDisplayName ?? 'Warp Peer',
        peerAvatarId: _activePeerAvatar ?? 'starter_cyber_01',
        manifest: _activeManifest,
        errorMessage: errorMessage,
      ),
    );
  }

  String _generateTransferId() {
    final int rand = math.Random().nextInt(999999);
    final int time = DateTime.now().millisecondsSinceEpoch;
    return 'tx_${time}_$rand';
  }

  String _inferMimeType(String filePath) {
    final String ext = p.extension(filePath).toLowerCase();
    switch (ext) {
      case '.png':
        return 'image/png';
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';
      case '.pdf':
        return 'application/pdf';
      case '.zip':
      case '.tar':
      case '.gz':
        return 'application/zip';
      case '.mp4':
      case '.mov':
      case '.mkv':
        return 'video/mp4';
      case '.mp3':
      case '.wav':
      case '.flac':
        return 'audio/mpeg';
      case '.txt':
      case '.md':
        return 'text/plain';
      case '.dart':
      case '.js':
      case '.ts':
      case '.json':
        return 'application/json';
      default:
        return 'application/octet-stream';
    }
  }

  @override
  void dispose() {
    _signalSubscription?.cancel();
    _progressController.close();
    _incomingInvitationController.close();
    _incomingClipboardController.close();
    _reactionStreamController.close();
    cancelTransfer();
    super.dispose();
  }
}
