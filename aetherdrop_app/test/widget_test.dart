import 'package:aetherdrop_app/core/constants.dart';
import 'package:aetherdrop_app/core/theme.dart';
import 'package:aetherdrop_app/ui/widgets/avatar_badge.dart';
import 'package:aetherdrop_app/ui/widgets/glass_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AetherDrop core widgets and constants smoke test', (
    WidgetTester tester,
  ) async {
    expect(chunkSize, 262144);
    expect(stunServers.length, 3);

    final ThemeProvider themeProvider = ThemeProvider();
    expect(themeProvider.isDarkMode, true);

    await tester.pumpWidget(
      MaterialApp(
        theme: AetherDropTheme.darkTheme,
        home: const Scaffold(
          body: GlassCard(
            child: AvatarBadge(
              avatarId: 'starter_cyber_01',
              level: 10,
              animateRing: false,
            ),
          ),
        ),
      ),
    );

    expect(find.byType(GlassCard), findsOneWidget);
    expect(find.byType(AvatarBadge), findsOneWidget);
    expect(find.text('LVL 10'), findsOneWidget);
  });
}
