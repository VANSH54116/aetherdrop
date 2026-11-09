import 'package:aetherdrop_app/core/theme.dart';
import 'package:aetherdrop_app/models/transfer_manifest.dart';
import 'package:aetherdrop_app/ui/screens/home_radar_screen.dart';
import 'package:aetherdrop_app/ui/screens/transfer_warp_modal.dart';
import 'package:aetherdrop_app/ui/screens/vault_avatars_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('VaultAvatarsScreen renders header, avatars and badges', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AetherDropTheme.darkTheme,
        home: const VaultAvatarsScreen(),
      ),
    );

    await tester.pump();

    expect(find.text('AVATAR & RANK VAULT'), findsOneWidget);
    expect(find.text('LIFETIME WARP METRICS'), findsOneWidget);
    expect(find.text('CYBER AVATARS // 12 PROCEDURAL TIERS'), findsOneWidget);
    expect(find.text('PROGRESSION MILESTONE BADGES'), findsOneWidget);
    expect(find.text('Neon Pulse Core'), findsOneWidget);
    expect(find.text('First Warp'), findsOneWidget);
  });

  testWidgets('TransferWarpModal renders incoming transfer invitation popup', (
    WidgetTester tester,
  ) async {
    final TransferManifest manifest = TransferManifest.singleFile(
      transferId: 'test_tx_001',
      senderId: 'user_123',
      senderName: 'Vansh',
      senderAvatar: 'starter_cyber_01',
      fileName: 'Project_Folder.zip',
      fileSize: 1524628992, // ~1.42 GB
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AetherDropTheme.darkTheme,
        home: Scaffold(
          body: TransferWarpModal(
            incomingManifest: manifest,
            isSender: false,
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('AETHERDROP // WARP TUNNEL V2'), findsOneWidget);
    expect(find.text('Vansh wants to beam'), findsOneWidget);
    expect(find.text('Project_Folder.zip'), findsOneWidget);
    expect(find.text('ACCEPT WARP'), findsOneWidget);
    expect(find.text('DECLINE'), findsOneWidget);
    expect(
      find.text('Auto-accept from trusted streak friends'),
      findsOneWidget,
    );
  });

  testWidgets('HomeRadarScreen renders header, search bar, and radar view', (
    WidgetTester tester,
  ) async {
    final ThemeProvider themeProvider = ThemeProvider();

    await tester.pumpWidget(
      MaterialApp(
        theme: AetherDropTheme.darkTheme,
        home: HomeRadarScreen(themeProvider: themeProvider),
      ),
    );

    await tester.pump();

    expect(find.text('VAULT'), findsOneWidget);
    expect(
      find.text('Search anyone globally by email or name...'),
      findsOneWidget,
    );
    expect(find.text('RECENT CO-OP RADAR & STREAKS'), findsOneWidget);
  });
}
