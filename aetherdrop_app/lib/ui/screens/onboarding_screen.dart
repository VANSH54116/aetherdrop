import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/gamification.dart';
import '../../core/theme.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../../services/signaling_service.dart';
import '../widgets/avatar_badge.dart';
import '../widgets/glass_card.dart';

/// Breathtaking, minimalist 1-screen glassmorphic onboarding experience.
///
/// Features:
/// - Step 1: Email Address with live validation glow
/// - Step 2: Profile Name / Callsign
/// - Step 3: Interactive Starter Cyber Avatar carousel + Live Peer Preview card
/// - "Initialize Warp Node" glowing cyan CTA button
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    super.key,
    this.onOnboardingComplete,
  });

  /// Optional callback invoked after onboarding completes successfully.
  final void Function(UserProfile profile)? onOnboardingComplete;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _nameFocus = FocusNode();

  String _selectedAvatarId = Gamification.starterCyber01.id;
  bool _isEmailValid = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_onEmailChanged);
    _nameController.addListener(_onNameChanged);
  }

  @override
  void dispose() {
    _emailController.removeListener(_onEmailChanged);
    _nameController.removeListener(_onNameChanged);
    _emailController.dispose();
    _nameController.dispose();
    _emailFocus.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  void _onEmailChanged() {
    final String text = _emailController.text.trim();
    final bool valid = _emailRegex.hasMatch(text);
    if (valid != _isEmailValid) {
      setState(() {
        _isEmailValid = valid;
      });
    }

    // Auto-fill suggested display name from email prefix if name is empty
    if (_nameController.text.isEmpty && text.contains('@')) {
      final String prefix = text.split('@').first;
      if (prefix.isNotEmpty) {
        _nameController.text =
            prefix[0].toUpperCase() + prefix.substring(1);
      }
    }
  }

  void _onNameChanged() {
    setState(() {});
  }

  Future<void> _handleInitializeNode() async {
    final String email = _emailController.text.trim();
    final String displayName = _nameController.text.trim();

    if (!_emailRegex.hasMatch(email)) {
      setState(() {
        _errorMessage = 'Please enter a valid email address';
      });
      _emailFocus.requestFocus();
      return;
    }

    final String finalName = displayName.isEmpty
        ? email.split('@').first
        : displayName;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final UserProfile profile =
          await AuthService.instance.completeFirstTimeOnboarding(
        email: email,
        displayName: finalName,
        avatarId: _selectedAvatarId,
      );

      // Connect signaling presence mesh
      await SignalingService.instance.connect();

      if (mounted) {
        if (widget.onOnboardingComplete != null) {
          widget.onOnboardingComplete!(profile);
        } else {
          Navigator.of(context).maybePop(profile);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to initialize node: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final CyberAvatarInfo activeAvatar =
        Gamification.getAvatarById(_selectedAvatarId);
    final String currentDisplayName = _nameController.text.trim().isEmpty
        ? (_emailController.text.contains('@')
            ? _emailController.text.split('@').first
            : 'Warp Pilot')
        : _nameController.text.trim();
    final String currentEmail = _emailController.text.trim().isEmpty
        ? 'node@aetherdrop.net'
        : _emailController.text.trim();

    return Scaffold(
      backgroundColor: AetherDropColors.deepMatteObsidian,
      body: Stack(
        children: <Widget>[
          // Ambient Cyber Glow Blobs in corners
          Positioned(
            top: -100,
            left: -80,
            child: _buildAmbientBlob(
              AetherDropColors.electricCyan.withValues(alpha: 0.14),
              340,
            ),
          ),
          Positioned(
            bottom: -120,
            right: -100,
            child: _buildAmbientBlob(
              AetherDropColors.plasmaViolet.withValues(alpha: 0.16),
              380,
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 860),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      // Header Badge & Title
                      _buildHeader(),
                      const SizedBox(height: 28),

                      // Two-Column Responsive Layout for Desktop & Tablet, Stack on Mobile
                      LayoutBuilder(
                        builder: (
                          BuildContext context,
                          BoxConstraints constraints,
                        ) {
                          final bool isWide = constraints.maxWidth >= 720;
                          if (isWide) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                // Left Column: Inputs & Avatar Selector
                                Expanded(
                                  flex: 6,
                                  child: _buildInputsAndAvatarSelector(
                                    isDark,
                                    activeAvatar,
                                  ),
                                ),
                                const SizedBox(width: 24),
                                // Right Column: Live Peer Preview Card
                                Expanded(
                                  flex: 5,
                                  child: _buildLivePeerPreviewCard(
                                    currentDisplayName,
                                    currentEmail,
                                  ),
                                ),
                              ],
                            );
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              _buildInputsAndAvatarSelector(isDark, activeAvatar),
                              const SizedBox(height: 24),
                              _buildLivePeerPreviewCard(
                                currentDisplayName,
                                currentEmail,
                              ),
                            ],
                          );
                        },
                      ),

                      if (_errorMessage != null) ...<Widget>[
                        const SizedBox(height: 16),
                        _buildErrorBanner(),
                      ],

                      const SizedBox(height: 28),

                      // Glowing Cyan CTA Button
                      _buildInitializeButton(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AetherDropColors.electricCyan.withValues(alpha: 0.10),
                border: Border.all(
                  color: AetherDropColors.electricCyan.withValues(alpha: 0.35),
                  width: 1.5,
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: AetherDropColors.electricCyan.withValues(alpha: 0.25),
                    blurRadius: 18,
                  ),
                ],
              ),
              child: const Icon(
                LucideIcons.zap,
                color: AetherDropColors.electricCyan,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Text(
              'AETHERDROP',
              style: AetherDropTheme.headlineStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                letterSpacing: 3.5,
                color: Colors.white,
              ),
            ),
          ],
        ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2, end: 0),
        const SizedBox(height: 8),
        Text(
          'ZERO-COST P2P WARP PROTOCOL • INITIALIZE NODE IDENTITY',
          textAlign: TextAlign.center,
          style: AetherDropTheme.monoStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.8,
            color: AetherDropColors.electricCyan,
          ),
        ).animate().fadeIn(delay: 150.ms, duration: 400.ms),
      ],
    );
  }

  Widget _buildInputsAndAvatarSelector(
    bool isDark,
    CyberAvatarInfo activeAvatar,
  ) {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Step 1: Email Address
          _buildStepHeader('01', 'WARP IDENTITY // EMAIL ADDRESS'),
          const SizedBox(height: 10),
          _buildEmailField(),
          const SizedBox(height: 22),

          // Step 2: Node Callsign / Display Name
          _buildStepHeader('02', 'NODE CALLSIGN // DISPLAY NAME'),
          const SizedBox(height: 10),
          _buildNameField(),
          const SizedBox(height: 24),

          // Step 3: Starter Avatar Carousel
          _buildStepHeader('03', 'SELECT STARTER CYBER AVATAR'),
          const SizedBox(height: 12),
          _buildAvatarCarousel(),
          const SizedBox(height: 12),
          Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Column(
                key: ValueKey<String>(activeAvatar.id),
                children: <Widget>[
                  Text(
                    activeAvatar.name.toUpperCase(),
                    style: AetherDropTheme.monoStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: activeAvatar.primaryColor,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    activeAvatar.subtitle,
                    textAlign: TextAlign.center,
                    style: AetherDropTheme.bodyStyle(
                      fontSize: 12,
                      color: AetherDropColors.textSecondaryDark,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepHeader(String number, String label) {
    return Row(
      children: <Widget>[
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: AetherDropColors.electricCyan.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: AetherDropColors.electricCyan.withValues(alpha: 0.4),
              width: 1,
            ),
          ),
          child: Text(
            number,
            style: AetherDropTheme.monoStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: AetherDropColors.electricCyan,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: AetherDropTheme.monoStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: AetherDropColors.textSecondaryDark,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmailField() {
    final bool hasText = _emailController.text.isNotEmpty;
    final Color glowColor = _isEmailValid
        ? AetherDropColors.neonEmerald
        : (hasText ? const Color(0xFFF59E0B) : AetherDropColors.electricCyan);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: const Color(0xFF0F141C),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: glowColor.withValues(alpha: _isEmailValid ? 0.85 : 0.28),
          width: _isEmailValid ? 1.6 : 1.0,
        ),
        boxShadow: <BoxShadow>[
          if (_isEmailValid)
            BoxShadow(
              color: AetherDropColors.neonEmerald.withValues(alpha: 0.28),
              blurRadius: 14,
              spreadRadius: 1,
            ),
        ],
      ),
      child: TextField(
        controller: _emailController,
        focusNode: _emailFocus,
        keyboardType: TextInputType.emailAddress,
        style: AetherDropTheme.bodyStyle(
          fontSize: 14.5,
          color: Colors.white,
        ),
        decoration: InputDecoration(
          prefixIcon: Icon(
            LucideIcons.mail,
            size: 19,
            color: glowColor,
          ),
          suffixIcon: _isEmailValid
              ? const Icon(
                  LucideIcons.checkCircle2,
                  size: 20,
                  color: AetherDropColors.neonEmerald,
                )
              : null,
          hintText: 'pilot@example.com',
          hintStyle: AetherDropTheme.bodyStyle(
            fontSize: 14,
            color: AetherDropColors.textMutedDark,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildNameField() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F141C),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AetherDropColors.glassBorder,
          width: 1.0,
        ),
      ),
      child: TextField(
        controller: _nameController,
        focusNode: _nameFocus,
        style: AetherDropTheme.bodyStyle(
          fontSize: 14.5,
          color: Colors.white,
        ),
        decoration: InputDecoration(
          prefixIcon: const Icon(
            LucideIcons.user,
            size: 19,
            color: AetherDropColors.electricCyan,
          ),
          hintText: 'e.g. CyberVanguard',
          hintStyle: AetherDropTheme.bodyStyle(
            fontSize: 14,
            color: AetherDropColors.textMutedDark,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarCarousel() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: Gamification.starterAvatars.map((CyberAvatarInfo avatar) {
            final bool isSelected = avatar.id == _selectedAvatarId;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedAvatarId = avatar.id;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? avatar.primaryColor.withValues(alpha: 0.16)
                        : Colors.transparent,
                    border: Border.all(
                      color: isSelected
                          ? avatar.primaryColor
                          : Colors.white.withValues(alpha: 0.12),
                      width: isSelected ? 2.2 : 1.0,
                    ),
                    boxShadow: <BoxShadow>[
                      if (isSelected)
                        BoxShadow(
                          color: avatar.primaryColor.withValues(alpha: 0.40),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                    ],
                  ),
                  child: AvatarBadge(
                    avatarId: avatar.id,
                    level: 1,
                    size: 54,
                    showLevelPill: false,
                    animateRing: isSelected,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildLivePeerPreviewCard(
    String displayName,
    String email,
  ) {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      borderColor: AetherDropColors.electricCyan.withValues(alpha: 0.28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Preview Card Header Pill
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Flexible(
                child: Text(
                  'LIVE PEER PREVIEW',
                  overflow: TextOverflow.ellipsis,
                  style: AetherDropTheme.monoStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: AetherDropColors.textSecondaryDark,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AetherDropColors.neonEmerald.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: AetherDropColors.neonEmerald.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: AetherDropColors.neonEmerald,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'ONLINE',
                      style: AetherDropTheme.monoStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: AetherDropColors.neonEmerald,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Central Avatar with Animated Ring
          Center(
            child: AvatarBadge(
              avatarId: _selectedAvatarId,
              level: 1,
              size: 96,
              isOnline: true,
              showLevelPill: true,
              animateRing: true,
            ),
          ),
          const SizedBox(height: 18),

          // Callsign / Display Name
          Center(
            child: Text(
              displayName,
              textAlign: TextAlign.center,
              style: AetherDropTheme.titleStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 4),

          // Email
          Center(
            child: Text(
              email,
              textAlign: TextAlign.center,
              style: AetherDropTheme.monoStyle(
                fontSize: 12,
                color: AetherDropColors.textSecondaryDark,
              ),
            ),
          ),
          const SizedBox(height: 20),

          const Divider(
            color: Color.fromRGBO(255, 255, 255, 0.08),
            height: 1,
          ),
          const SizedBox(height: 18),

          // Live Metrics Preview
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              Expanded(
                child: _buildPreviewMetric(
                  label: 'RANK TIER',
                  value: 'Spark Node',
                  accent: AetherDropColors.electricCyan,
                ),
              ),
              Expanded(
                child: _buildPreviewMetric(
                  label: 'CO-OP STREAK',
                  value: '🔥 1 Day',
                  accent: AetherDropColors.liquidGold,
                ),
              ),
              Expanded(
                child: _buildPreviewMetric(
                  label: 'WARP XP',
                  value: '0 WXP',
                  accent: AetherDropColors.plasmaViolet,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewMetric({
    required String label,
    required String value,
    required Color accent,
  }) {
    return Column(
      children: <Widget>[
        Text(
          label,
          style: AetherDropTheme.monoStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
            color: AetherDropColors.textMutedDark,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AetherDropTheme.monoStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: accent,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AetherDropColors.crimsonPulse.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AetherDropColors.crimsonPulse.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Row(
        children: <Widget>[
          const Icon(
            LucideIcons.alertCircle,
            color: AetherDropColors.crimsonPulse,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _errorMessage!,
              style: AetherDropTheme.bodyStyle(
                fontSize: 12.5,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitializeButton() {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: <Color>[
            AetherDropColors.electricCyan,
            AetherDropColors.hyperCobalt,
          ],
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AetherDropColors.electricCyan.withValues(alpha: 0.38),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _handleInitializeNode,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isSubmitting
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: AetherDropColors.deepMatteObsidian,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    'ESTABLISHING QUANTUM LINK...',
                    style: AetherDropTheme.monoStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: AetherDropColors.deepMatteObsidian,
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Icon(
                    LucideIcons.radio,
                    size: 20,
                    color: AetherDropColors.deepMatteObsidian,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'INITIALIZE WARP NODE',
                    style: AetherDropTheme.monoStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                      color: AetherDropColors.deepMatteObsidian,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildAmbientBlob(Color color, double diameter) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: <Color>[
            color,
            color.withValues(alpha: 0.0),
          ],
        ),
      ),
    );
  }
}
