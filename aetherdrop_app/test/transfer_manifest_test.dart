import 'package:aetherdrop_app/models/transfer_manifest.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TransferManifest Tests', () {
    test('singleFile factory builds correct manifest and json roundtrip', () {
      final TransferManifest manifest = TransferManifest.singleFile(
        transferId: 'tx-001',
        senderId: 'user-sender',
        senderName: 'Vansh',
        senderAvatar: 'starter_cyber_01',
        fileName: 'blueprint.pdf',
        fileSize: 10485760, // 10 MB
        mimeType: 'application/pdf',
      );

      expect(manifest.transferId, 'tx-001');
      expect(manifest.payloadType, TransferPayloadType.singleFile);
      expect(manifest.isSingleFile, isTrue);
      expect(manifest.totalBytes, 10485760);
      expect(manifest.formattedTotalBytes, '10.0 MB');
      expect(manifest.displayTitle, 'blueprint.pdf');

      final String encoded = manifest.encodeJson();
      final TransferManifest decoded = TransferManifest.decodeJson(encoded);

      expect(decoded.transferId, manifest.transferId);
      expect(decoded.files.first.name, 'blueprint.pdf');
      expect(decoded.files.first.relativePath, 'blueprint.pdf');
      expect(decoded.files.first.size, 10485760);
    });

    test('folderArchive factory builds correct nested directory structure', () {
      final List<TransferFileEntry> files = <TransferFileEntry>[
        const TransferFileEntry(
          index: 0,
          name: 'index.html',
          relativePath: 'web/index.html',
          size: 2048,
        ),
        const TransferFileEntry(
          index: 1,
          name: 'app.js',
          relativePath: 'web/scripts/app.js',
          size: 4096,
        ),
      ];

      final TransferManifest manifest = TransferManifest.folderArchive(
        transferId: 'tx-002',
        senderId: 'user-sender',
        senderName: 'Vansh',
        senderAvatar: 'cyber_kitsune_05',
        folderName: 'web',
        files: files,
      );

      expect(manifest.payloadType.isFolder, isTrue);
      expect(manifest.totalItems, 2);
      expect(manifest.totalBytes, 6144);
      expect(manifest.displayTitle, 'web');
      expect(manifest.files[1].relativePath, 'web/scripts/app.js');
    });

    test('instantClipboard text factory formats properly', () {
      final TransferManifest manifest = TransferManifest.clipboardText(
        transferId: 'tx-003',
        senderId: 'user-sender',
        senderName: 'Vansh',
        senderAvatar: 'holo_samurai_10',
        text: 'https://aetherdrop.net/join?code=XYZ',
      );

      expect(manifest.payloadType.isClipboard, isTrue);
      expect(manifest.clipboardType?.isText, isTrue);
      expect(manifest.clipboardText, 'https://aetherdrop.net/join?code=XYZ');
      expect(manifest.displayTitle, 'https://aetherdrop.net/join?code=XYZ');
    });
  });
}
