import 'package:aetherdrop_app/core/theme.dart';
import 'package:aetherdrop_app/ui/screens/onboarding_screen.dart';
import 'package:aetherdrop_app/ui/widgets/avatar_badge.dart';
import 'package:aetherdrop_app/ui/widgets/glass_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('OnboardingScreen renders header, input steps, carousel, and preview card', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AetherDropTheme.darkTheme,
        home: const OnboardingScreen(),
      ),
    );

    // Initial pump for animations
    await tester.pump(const Duration(milliseconds: 600));

    // Verify Title and Subtitle
    expect(find.text('AETHERDROP'), findsOneWidget);
    expect(
      find.text('ZERO-COST P2P WARP PROTOCOL • INITIALIZE NODE IDENTITY'),
      findsOneWidget,
    );

    // Verify Step Labels
    expect(find.text('WARP IDENTITY // EMAIL ADDRESS'), findsOneWidget);
    expect(find.text('NODE CALLSIGN // DISPLAY NAME'), findsOneWidget);
    expect(find.text('SELECT STARTER CYBER AVATAR'), findsOneWidget);
    expect(find.text('LIVE PEER PREVIEW'), findsOneWidget);

    // Verify CTA button
    expect(find.text('INITIALIZE WARP NODE'), findsOneWidget);

    // Verify that GlassCard and AvatarBadge are present
    expect(find.byType(GlassCard), findsWidgets);
    expect(find.byType(AvatarBadge), findsWidgets);
  });
}
