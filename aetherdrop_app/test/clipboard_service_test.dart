import 'dart:typed_data';

import 'package:aetherdrop_app/services/clipboard_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ClipboardPayload Detection Tests', () {
    test('detects URL correctly', () {
      final ClipboardPayload payloadHttp = ClipboardPayload.text('https://aetherdrop.net/download');
      expect(payloadHttp.type, ClipboardContentType.text);
      expect(payloadHttp.isUrl, isTrue);
      expect(payloadHttp.isCode, isFalse);
      expect(payloadHttp.summary, contains('Web URL'));

      final ClipboardPayload payloadBare = ClipboardPayload.text('github.com/aetherdrop/app');
      expect(payloadBare.isUrl, isTrue);
    });

    test('detects code snippet correctly', () {
      const String codeSample = '''
import 'package:flutter/material.dart';

class CustomWidget extends StatelessWidget {
  const CustomWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
''';

      final ClipboardPayload payload = ClipboardPayload.text(codeSample);
      expect(payload.type, ClipboardContentType.text);
      expect(payload.isCode, isTrue);
      expect(payload.isUrl, isFalse);
      expect(payload.summary, contains('Code Snippet'));
    });

    test('detects plain text note correctly', () {
      final ClipboardPayload payload = ClipboardPayload.text('Meeting at 3 PM for the warp demo!');
      expect(payload.type, ClipboardContentType.text);
      expect(payload.isCode, isFalse);
      expect(payload.isUrl, isFalse);
      expect(payload.summary, contains('Text Note (34 chars)'));
    });

    test('detects image payload correctly', () {
      final Uint8List fakeBytes = Uint8List(2048);
      final ClipboardPayload payload = ClipboardPayload.image(fakeBytes);

      expect(payload.type, ClipboardContentType.image);
      expect(payload.byteSize, 2048);
      expect(payload.summary, contains('Screenshot Image (2.0 KB)'));
    });

    test('detects files payload correctly', () {
      final List<String> paths = <String>[
        '/Users/user/Downloads/file1.png',
        '/Users/user/Downloads/file2.pdf',
      ];
      final ClipboardPayload payload = ClipboardPayload.files(paths);

      expect(payload.type, ClipboardContentType.files);
      expect(payload.filePaths.length, 2);
      expect(payload.summary, '2 Copied Files');
    });
  });

  group('ClipboardService Tests', () {
    test('singleton instance allows selecting and clearing peer', () {
      final ClipboardService service = ClipboardService.instance;
      expect(service, isNotNull);

      service.setSelectedPeer('peer_abc');
      expect(service.selectedPeerId, 'peer_abc');

      service.setSelectedPeer(null);
      expect(service.selectedPeerId, isNull);
    });

    test('copyTextToClipboard executes without exception', () async {
      final ClipboardService service = ClipboardService.instance;
      await service.copyTextToClipboard('Beamed with AetherDrop');
    });
  });
}
