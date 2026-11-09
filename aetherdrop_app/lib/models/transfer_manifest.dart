import 'dart:convert';

/// The 4 supported high-level transfer payload types in AetherDrop.
enum TransferPayloadType {
  /// Single file direct beam.
  singleFile('single_file'),

  /// Multiple individual files selected together.
  multiFile('multi_file'),

  /// Entire directory tree recursively traversed and reconstructed.
  folderArchive('folder_archive'),

  /// Instant live clipboard beam (text snippet, code, URL, or screenshot PNG bytes).
  instantClipboard('instant_clipboard');

  const TransferPayloadType(this.value);

  /// String wire format representation.
  final String value;

  /// Parses a [TransferPayloadType] from a string wire value.
  static TransferPayloadType fromString(String? val) {
    switch (val) {
      case 'single_file':
        return TransferPayloadType.singleFile;
      case 'multi_file':
        return TransferPayloadType.multiFile;
      case 'folder_archive':
        return TransferPayloadType.folderArchive;
      case 'instant_clipboard':
        return TransferPayloadType.instantClipboard;
      default:
        return TransferPayloadType.singleFile;
    }
  }

  bool get isSingleFile => this == TransferPayloadType.singleFile;
  bool get isMultiFile => this == TransferPayloadType.multiFile;
  bool get isFolder => this == TransferPayloadType.folderArchive;
  bool get isClipboard => this == TransferPayloadType.instantClipboard;
}

/// The specific subtype of an instant clipboard payload.
enum ClipboardPayloadType {
  /// Plain text, formatted note, source code snippet, or web URL.
  text('text'),

  /// Raw PNG image bytes from a clipboard screenshot or graphic copy.
  image('image'),

  /// File paths copied directly from the OS file explorer / Finder.
  filePaths('file_paths');

  const ClipboardPayloadType(this.value);

  final String value;

  static ClipboardPayloadType? fromString(String? val) {
    if (val == null) return null;
    switch (val) {
      case 'text':
        return ClipboardPayloadType.text;
      case 'image':
        return ClipboardPayloadType.image;
      case 'file_paths':
        return ClipboardPayloadType.filePaths;
      default:
        return null;
    }
  }

  bool get isText => this == ClipboardPayloadType.text;
  bool get isImage => this == ClipboardPayloadType.image;
  bool get isFiles => this == ClipboardPayloadType.filePaths;
}

/// Metadata entry for an individual file within a transfer manifest.
///
/// Supports exact relative subpaths so nested directory trees can be
/// reconstructed completely on the recipient device.
class TransferFileEntry {
  const TransferFileEntry({
    required this.index,
    required this.name,
    required this.relativePath,
    required this.size,
    this.mimeType = 'application/octet-stream',
    this.checksum,
  });

  /// 0-indexed position within the manifest file list.
  final int index;

  /// Base filename (e.g. `report.pdf`, `index.html`).
  final String name;

  /// Relative path preserving nested folder hierarchy (e.g. `assets/images/logo.png`).
  final String relativePath;

  /// Total size in bytes.
  final int size;

  /// MIME type string or inferred classification.
  final String mimeType;

  /// Optional SHA-256 or fast checksum for integrity verification.
  final String? checksum;

  /// Deserializes a [TransferFileEntry] from JSON.
  factory TransferFileEntry.fromJson(Map<String, dynamic> json) {
    return TransferFileEntry(
      index: (json['index'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? 'unnamed_file',
      relativePath: json['relative_path'] as String? ??
          json['name'] as String? ??
          'unnamed_file',
      size: (json['size'] as num?)?.toInt() ?? 0,
      mimeType: json['mime_type'] as String? ?? 'application/octet-stream',
      checksum: json['checksum'] as String?,
    );
  }

  /// Serializes this file entry to JSON.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'index': index,
      'name': name,
      'relative_path': relativePath,
      'size': size,
      'mime_type': mimeType,
      if (checksum != null) 'checksum': checksum,
    };
  }

  /// Formatted human-readable file size (e.g. `12.4 MB`, `450 KB`).
  String get formattedSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) {
      return '${(size / 1024).toStringAsFixed(1)} KB';
    }
    if (size < 1024 * 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  /// File extension without leading dot (e.g. `png`, `pdf`).
  String get extension {
    final int dotIndex = name.lastIndexOf('.');
    if (dotIndex == -1 || dotIndex == name.length - 1) return '';
    return name.substring(dotIndex + 1).toLowerCase();
  }

  TransferFileEntry copyWith({
    int? index,
    String? name,
    String? relativePath,
    int? size,
    String? mimeType,
    String? checksum,
  }) {
    return TransferFileEntry(
      index: index ?? this.index,
      name: name ?? this.name,
      relativePath: relativePath ?? this.relativePath,
      size: size ?? this.size,
      mimeType: mimeType ?? this.mimeType,
      checksum: checksum ?? this.checksum,
    );
  }
}

/// Represents the complete transfer payload header sent as JSON over the WebRTC
/// DataChannel (`aetherdrop-warp-pipe`) before binary chunks begin.
///
/// Contains all session, sender, payload structure, and directory tree metadata
/// needed for the receiver to allocate disk space, prepare folders, and calculate
/// real-time transfer progress.
class TransferManifest {
  const TransferManifest({
    required this.transferId,
    required this.senderId,
    required this.senderName,
    required this.senderAvatar,
    required this.payloadType,
    required this.totalBytes,
    required this.totalItems,
    required this.files,
    this.clipboardType,
    this.clipboardText,
    this.clipboardPreview,
    this.folderRootName,
    required this.timestamp,
    this.metadata = const <String, dynamic>{},
  });

  /// Unique UUID identifying this transfer session.
  final String transferId;

  /// Supabase UUID of the sending peer.
  final String senderId;

  /// Display name of the sending peer.
  final String senderName;

  /// Active cyber avatar ID of the sending peer.
  final String senderAvatar;

  /// High-level payload classification.
  final TransferPayloadType payloadType;

  /// Total payload size across all files/buffers in bytes.
  final int totalBytes;

  /// Total count of individual files or items.
  final int totalItems;

  /// Detailed list of all files with relative paths.
  final List<TransferFileEntry> files;

  /// Sub-classification if [payloadType] is [TransferPayloadType.instantClipboard].
  final ClipboardPayloadType? clipboardType;

  /// Direct text content if [clipboardType] is [ClipboardPayloadType.text].
  final String? clipboardText;

  /// Optional base64 or thumbnail preview representation.
  final String? clipboardPreview;

  /// Root folder name if [payloadType] is [TransferPayloadType.folderArchive].
  final String? folderRootName;

  /// Time when the transfer was initiated.
  final DateTime timestamp;

  /// Extensible metadata map for custom client headers.
  final Map<String, dynamic> metadata;

  /// Helper factory for a single file beam.
  factory TransferManifest.singleFile({
    required String transferId,
    required String senderId,
    required String senderName,
    required String senderAvatar,
    required String fileName,
    required int fileSize,
    String mimeType = 'application/octet-stream',
    String? checksum,
  }) {
    final TransferFileEntry entry = TransferFileEntry(
      index: 0,
      name: fileName,
      relativePath: fileName,
      size: fileSize,
      mimeType: mimeType,
      checksum: checksum,
    );

    return TransferManifest(
      transferId: transferId,
      senderId: senderId,
      senderName: senderName,
      senderAvatar: senderAvatar,
      payloadType: TransferPayloadType.singleFile,
      totalBytes: fileSize,
      totalItems: 1,
      files: <TransferFileEntry>[entry],
      timestamp: DateTime.now(),
    );
  }

  /// Helper factory for a multi-file beam.
  factory TransferManifest.multiFile({
    required String transferId,
    required String senderId,
    required String senderName,
    required String senderAvatar,
    required List<TransferFileEntry> files,
  }) {
    final int total = files.fold<int>(0, (int sum, TransferFileEntry f) => sum + f.size);
    return TransferManifest(
      transferId: transferId,
      senderId: senderId,
      senderName: senderName,
      senderAvatar: senderAvatar,
      payloadType: TransferPayloadType.multiFile,
      totalBytes: total,
      totalItems: files.length,
      files: files,
      timestamp: DateTime.now(),
    );
  }

  /// Helper factory for an entire nested directory tree.
  factory TransferManifest.folderArchive({
    required String transferId,
    required String senderId,
    required String senderName,
    required String senderAvatar,
    required String folderName,
    required List<TransferFileEntry> files,
  }) {
    final int total = files.fold<int>(0, (int sum, TransferFileEntry f) => sum + f.size);
    return TransferManifest(
      transferId: transferId,
      senderId: senderId,
      senderName: senderName,
      senderAvatar: senderAvatar,
      payloadType: TransferPayloadType.folderArchive,
      totalBytes: total,
      totalItems: files.length,
      files: files,
      folderRootName: folderName,
      timestamp: DateTime.now(),
    );
  }

  /// Helper factory for instant clipboard text/code beam.
  factory TransferManifest.clipboardText({
    required String transferId,
    required String senderId,
    required String senderName,
    required String senderAvatar,
    required String text,
    String? preview,
  }) {
    final List<int> utf8Bytes = utf8.encode(text);
    return TransferManifest(
      transferId: transferId,
      senderId: senderId,
      senderName: senderName,
      senderAvatar: senderAvatar,
      payloadType: TransferPayloadType.instantClipboard,
      clipboardType: ClipboardPayloadType.text,
      clipboardText: text,
      clipboardPreview: preview ?? (text.length > 80 ? '${text.substring(0, 80)}...' : text),
      totalBytes: utf8Bytes.length,
      totalItems: 1,
      files: <TransferFileEntry>[
        TransferFileEntry(
          index: 0,
          name: 'clipboard_snippet.txt',
          relativePath: 'clipboard_snippet.txt',
          size: utf8Bytes.length,
          mimeType: 'text/plain',
        ),
      ],
      timestamp: DateTime.now(),
    );
  }

  /// Helper factory for instant clipboard screenshot PNG beam.
  factory TransferManifest.clipboardImage({
    required String transferId,
    required String senderId,
    required String senderName,
    required String senderAvatar,
    required int imageSizeBytes,
    String? base64Preview,
  }) {
    final String timestampStr = DateTime.now().millisecondsSinceEpoch.toString();
    final String fileName = 'screenshot_$timestampStr.png';

    return TransferManifest(
      transferId: transferId,
      senderId: senderId,
      senderName: senderName,
      senderAvatar: senderAvatar,
      payloadType: TransferPayloadType.instantClipboard,
      clipboardType: ClipboardPayloadType.image,
      clipboardPreview: base64Preview,
      totalBytes: imageSizeBytes,
      totalItems: 1,
      files: <TransferFileEntry>[
        TransferFileEntry(
          index: 0,
          name: fileName,
          relativePath: fileName,
          size: imageSizeBytes,
          mimeType: 'image/png',
        ),
      ],
      timestamp: DateTime.now(),
    );
  }

  /// Deserializes a [TransferManifest] from a JSON map.
  factory TransferManifest.fromJson(Map<String, dynamic> json) {
    final List<dynamic>? rawFiles = json['files'] as List<dynamic>?;
    final List<TransferFileEntry> filesList = rawFiles != null
        ? rawFiles
            .map((dynamic f) => TransferFileEntry.fromJson(f as Map<String, dynamic>))
            .toList()
        : <TransferFileEntry>[];

    return TransferManifest(
      transferId: json['transfer_id'] as String? ?? '',
      senderId: json['sender_id'] as String? ?? '',
      senderName: json['sender_name'] as String? ?? 'Anonymous Peer',
      senderAvatar: json['sender_avatar'] as String? ?? 'starter_cyber_01',
      payloadType: TransferPayloadType.fromString(json['payload_type'] as String?),
      totalBytes: (json['total_bytes'] as num?)?.toInt() ?? 0,
      totalItems: (json['total_items'] as num?)?.toInt() ?? filesList.length,
      files: filesList,
      clipboardType: ClipboardPayloadType.fromString(json['clipboard_type'] as String?),
      clipboardText: json['clipboard_text'] as String?,
      clipboardPreview: json['clipboard_preview'] as String?,
      folderRootName: json['folder_root_name'] as String?,
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
      metadata: (json['metadata'] as Map<String, dynamic>?) ?? <String, dynamic>{},
    );
  }

  /// Serializes this manifest to a standard JSON map.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'transfer_id': transferId,
      'sender_id': senderId,
      'sender_name': senderName,
      'sender_avatar': senderAvatar,
      'payload_type': payloadType.value,
      'total_bytes': totalBytes,
      'total_items': totalItems,
      'files': files.map((TransferFileEntry f) => f.toJson()).toList(),
      if (clipboardType != null) 'clipboard_type': clipboardType!.value,
      if (clipboardText != null) 'clipboard_text': clipboardText,
      if (clipboardPreview != null) 'clipboard_preview': clipboardPreview,
      if (folderRootName != null) 'folder_root_name': folderRootName,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
    };
  }

  /// Encodes this manifest directly into a JSON string suitable for sending
  /// over the WebRTC DataChannel.
  String encodeJson() => jsonEncode(toJson());

  /// Decodes a JSON string into a [TransferManifest].
  static TransferManifest decodeJson(String rawJson) {
    return TransferManifest.fromJson(jsonDecode(rawJson) as Map<String, dynamic>);
  }

  bool get isSingleFile => payloadType.isSingleFile;
  bool get isMultiFile => payloadType.isMultiFile;
  bool get isFolder => payloadType.isFolder;
  bool get isClipboard => payloadType.isClipboard;

  /// Formatted total volume string (e.g. `1.42 GB`, `24.5 MB`).
  String get formattedTotalBytes {
    if (totalBytes < 1024) return '$totalBytes B';
    if (totalBytes < 1024 * 1024) {
      return '${(totalBytes / 1024).toStringAsFixed(1)} KB';
    }
    if (totalBytes < 1024 * 1024 * 1024) {
      return '${(totalBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(totalBytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  /// Human-friendly display title for modals, toasts, and history items.
  String get displayTitle {
    switch (payloadType) {
      case TransferPayloadType.singleFile:
        return files.isNotEmpty ? files.first.name : 'Single File';
      case TransferPayloadType.multiFile:
        if (files.isEmpty) return 'Multiple Files';
        if (files.length == 1) return files.first.name;
        return '${files.first.name} + ${files.length - 1} more';
      case TransferPayloadType.folderArchive:
        return folderRootName ?? (files.isNotEmpty ? 'Folder (${files.length} items)' : 'Folder');
      case TransferPayloadType.instantClipboard:
        if (clipboardType == ClipboardPayloadType.image) {
          return 'Pasted Screenshot';
        }
        if (clipboardType == ClipboardPayloadType.filePaths) {
          return 'Pasted Files (${files.length})';
        }
        if (clipboardText != null && clipboardText!.trim().isNotEmpty) {
          final String trimmed = clipboardText!.trim();
          if (trimmed.length > 36) {
            return '${trimmed.substring(0, 36)}...';
          }
          return trimmed;
        }
        return 'Pasted Note';
    }
  }

  /// Secondary subtitle with item count and formatted size.
  String get displaySubtitle {
    if (payloadType.isFolder) {
      return '$totalItems file${totalItems == 1 ? '' : 's'} • $formattedTotalBytes';
    }
    if (payloadType.isMultiFile) {
      return '$totalItems files • $formattedTotalBytes';
    }
    if (payloadType.isClipboard && clipboardType == ClipboardPayloadType.text) {
      return 'Instant Text • $formattedTotalBytes';
    }
    return formattedTotalBytes;
  }
}
