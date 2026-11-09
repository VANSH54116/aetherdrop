import 'package:aetherdrop_app/services/webrtc_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TransferProgress Metrics Tests', () {
    test('metrics formats speed, percentage, ETA and volume correctly', () {
      const TransferProgress progress = TransferProgress(
        transferId: 'tx-123',
        status: TransferStatus.transferring,
        isSender: true,
        peerId: 'peer-456',
        peerDisplayName: 'QuantumNode',
        peerAvatarId: 'starter_cyber_01',
        bytesTransferred: 52428800, // 50 MB
        totalBytes: 104857600, // 100 MB
        progress: 0.5,
        speedMBps: 68.4,
        eta: Duration(seconds: 14),
        currentFileIndex: 2,
        totalFiles: 5,
        currentFileName: 'render_scene.blend',
      );

      expect(progress.speedDisplay, '68.4 MB/s');
      expect(progress.percentageDisplay, '50%');
      expect(progress.etaDisplay, '14s');
      expect(progress.fileCounterDisplay, 'File 3 of 5');
      expect(progress.volumeDisplay, '50.0 MB / 100.0 MB');
    });

    test('ETA formats minutes and seconds correctly', () {
      const TransferProgress progress = TransferProgress(
        transferId: 'tx-124',
        status: TransferStatus.transferring,
        isSender: true,
        peerId: 'peer-456',
        peerDisplayName: 'QuantumNode',
        peerAvatarId: 'starter_cyber_01',
        eta: Duration(minutes: 2, seconds: 15),
      );

      expect(progress.etaDisplay, '2m 15s');
    });

    test('TransferProgress copyWith updates specific fields cleanly', () {
      const TransferProgress initial = TransferProgress(
        transferId: 'tx-initial',
        status: TransferStatus.idle,
        isSender: false,
        peerId: 'p-1',
        peerDisplayName: 'Alice',
        peerAvatarId: 'starter_cyber_01',
      );

      final TransferProgress updated = initial.copyWith(
        status: TransferStatus.transferring,
        bytesTransferred: 1024,
        progress: 0.25,
      );

      expect(updated.transferId, 'tx-initial');
      expect(updated.status, TransferStatus.transferring);
      expect(updated.bytesTransferred, 1024);
      expect(updated.progress, 0.25);
    });
  });

  group('WebRTCEngine Singleton & Reaction Tests', () {
    test('singleton instance exists and has idle status initially', () {
      final WebRTCEngine engine = WebRTCEngine.instance;
      expect(engine, isNotNull);
      expect(engine.status, TransferStatus.idle);
      expect(engine.isTransferring, isFalse);
    });

    test('reactionStream emits reactions correctly', () async {
      final WebRTCEngine engine = WebRTCEngine.instance;
      final Future<String> reactionFuture = engine.reactionStream.first;

      engine.sendReaction('🚀');

      final String received = await reactionFuture;
      expect(received, '🚀');
    });
  });
}
