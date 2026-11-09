import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/transfer_manifest.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../../services/webrtc_engine.dart';
import '../widgets/avatar_badge.dart';

/// Modal dialog presenting the Incoming Transfer Request popup, the 60fps Live
/// Particle Warp Tunnel with digital speedometer & quick reactions, and the
/// celebratory "+WXP Gained!" level-up completion banner.
class TransferWarpModal extends StatefulWidget {
  const TransferWarpModal({
    super.key,
    this.incomingManifest,
    this.isSender = false,
  });

  /// Non-null if this modal was opened to prompt for an incoming peer invitation.
  final TransferManifest? incomingManifest;

  /// True if the current user initiated this transfer.
  final bool isSender;

  /// Convenience launcher to open the warp modal dialog across the app.
  static Future<void> show(
    BuildContext context, {
    TransferManifest? incomingManifest,
    bool isSender = false,
  }) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      barrierLabel: 'AetherDrop Warp Portal',
      transitionDuration: const Duration(milliseconds: 280),
      transitionBuilder: (BuildContext context, Animation<double> a1, Animation<double> a2, Widget child) {
        final double curved = Curves.easeOutCubic.transform(a1.value);
        return Transform.scale(
          scale: 0.92 + 0.08 * curved,
          child: Opacity(
            opacity: curved,
            child: child,
          ),
        );
      },
      pageBuilder: (BuildContext context, _, __) {
        return TransferWarpModal(
          incomingManifest: incomingManifest,
          isSender: isSender,
        );
      },
    );
  }

  @override
  State<TransferWarpModal> createState() => _TransferWarpModalState();
}

class _TransferWarpModalState extends State<TransferWarpModal>
    with TickerProviderStateMixin {
  // Streams & Engine
  StreamSubscription<TransferProgress>? _progressSub;
  StreamSubscription<String>? _reactionSub;

  TransferProgress? _currentProgress;
  TransferStatus _status = TransferStatus.idle;
  TransferManifest? _manifest;

  // Particle Stream Controller (60fps)
  late final AnimationController _particleController;
  final List<_WarpParticle> _particles = <_WarpParticle>[];
  final math.Random _rng = math.Random();

  // Floating Reaction Emojis
  final List<_FloatingReaction> _activeReactions = <_FloatingReaction>[];

  // Auto-Accept toggle preference
  bool _autoAcceptStreakFriends = false;
  static const String _prefAutoAccept = 'aetherdrop_auto_accept_streak_friends';

  // Gamification completion result cache
  int _xpEarned = 25;
  int _currentStreak = 1;
  bool _didLevelUp = false;
  int _newLevel = 1;

  @override
  void initState() {
    super.initState();
    _manifest = widget.incomingManifest ?? WebRTCEngine.instance.activeManifest;
    _status = widget.incomingManifest != null
        ? TransferStatus.waitingForPeer
        : WebRTCEngine.instance.status;

    _loadAutoAcceptPreference();

    // 60fps continuous animation ticker for the Warp Tunnel particles
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_tickParticles)..repeat();

    _initEngineListeners();
  }

  Future<void> _loadAutoAcceptPreference() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final bool val = prefs.getBool(_prefAutoAccept) ?? false;
      if (mounted) {
        setState(() => _autoAcceptStreakFriends = val);
      }
    } catch (_) {}
  }

  Future<void> _toggleAutoAccept(bool value) async {
    setState(() => _autoAcceptStreakFriends = value);
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefAutoAccept, value);
    } catch (_) {}
  }

  void _initEngineListeners() {
    // 1. Listen to real-time 60fps transfer metrics
    _progressSub = WebRTCEngine.instance.progressStream.listen((TransferProgress progress) {
      if (!mounted) return;
      setState(() {
        _currentProgress = progress;
        _status = progress.status;
        if (progress.manifest != null) {
          _manifest = progress.manifest;
        }

        if (progress.status == TransferStatus.completed &&
            progress.completionResult != null) {
          final Map<String, dynamic> res = progress.completionResult!;
          _xpEarned = (res['xp_earned'] as num?)?.toInt() ?? 25;
          _currentStreak = (res['streak'] as num?)?.toInt() ?? 1;
          _didLevelUp = res['level_up'] as bool? ?? false;
          _newLevel = (res['new_level'] as num?)?.toInt() ?? 1;
        }
      });
    });

    // 2. Listen to real-time WebRTC reactions
    _reactionSub = WebRTCEngine.instance.reactionStream.listen((String emoji) {
      _triggerReactionBurst(emoji);
    });
  }

  void _triggerReactionBurst(String emoji) {
    if (!mounted) return;
    setState(() {
      _activeReactions.add(
        _FloatingReaction(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          emoji: emoji,
          xRatio: 0.25 + _rng.nextDouble() * 0.50,
          yRatio: 0.70 + _rng.nextDouble() * 0.20,
          opacity: 1.0,
          scale: 0.6 + _rng.nextDouble() * 0.6,
          speed: 0.015 + _rng.nextDouble() * 0.02,
        ),
      );
    });
  }

  void _tickParticles() {
    // Update floating emoji reactions
    for (int i = _activeReactions.length - 1; i >= 0; i--) {
      final _FloatingReaction r = _activeReactions[i];
      r.yRatio -= r.speed;
      r.opacity -= 0.018;
      if (r.opacity <= 0 || r.yRatio <= 0) {
        _activeReactions.removeAt(i);
      }
    }

    // Particle creation and movement in the Warp Tunnel
    final double speedMBps = _currentProgress?.speedMBps ?? 12.0;
    final int spawnCount = math.max(1, (speedMBps / 12.0).clamp(1, 6).toInt());

    for (int s = 0; s < spawnCount; s++) {
      if (_particles.length < 90) {
        final bool isCyan = _rng.nextBool();
        _particles.add(
          _WarpParticle(
            x: _rng.nextDouble(),
            y: _rng.nextDouble(),
            progress: 0.0,
            speed: 0.018 + _rng.nextDouble() * (0.015 + speedMBps * 0.0006),
            size: 2.5 + _rng.nextDouble() * 4.5,
            color: isCyan
                ? AetherDropColors.electricCyan
                : AetherDropColors.plasmaViolet,
            trailLength: 0.05 + _rng.nextDouble() * 0.12,
          ),
        );
      }
    }

    // Advance particles along trajectory
    for (int i = _particles.length - 1; i >= 0; i--) {
      final _WarpParticle p = _particles[i];
      p.progress += p.speed;
      if (p.progress >= 1.0) {
        _particles.removeAt(i);
      }
    }

    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _particleController.dispose();
    _progressSub?.cancel();
    _reactionSub?.cancel();
    super.dispose();
  }

  Future<void> _acceptTransfer() async {
    setState(() => _status = TransferStatus.connecting);
    await WebRTCEngine.instance.acceptIncomingTransfer();
  }

  Future<void> _declineTransfer() async {
    await WebRTCEngine.instance.declineIncomingTransfer();
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _cancelOrCloseTransfer() async {
    if (_status == TransferStatus.transferring ||
        _status == TransferStatus.connecting ||
        _status == TransferStatus.initiating) {
      await WebRTCEngine.instance.cancelTransfer();
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _openDestinationFolder() async {
    try {
      Directory? downloadsDir;
      try {
        downloadsDir = await getDownloadsDirectory();
      } catch (_) {}
      downloadsDir ??= await getApplicationDocumentsDirectory();

      final Directory targetDir = Directory(
        p.join(downloadsDir.path, AppConstants.downloadSubdirectory),
      );

      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }

      if (!kIsWeb) {
        if (Platform.isMacOS) {
          await Process.run('open', <String>[targetDir.path]);
          return;
        } else if (Platform.isWindows) {
          await Process.run('explorer.exe', <String>[targetDir.path]);
          return;
        } else if (Platform.isLinux) {
          await Process.run('xdg-open', <String>[targetDir.path]);
          return;
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AetherDropColors.elevatedObsidian,
            content: Text(
              'Files saved in: ${targetDir.path}',
              style: AetherDropTheme.monoStyle(fontSize: 12, color: Colors.white),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error opening destination folder: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isIncomingRequest = widget.incomingManifest != null &&
        (_status == TransferStatus.waitingForPeer ||
            _status == TransferStatus.idle);

    final bool isCompleted = _status == TransferStatus.completed;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 680,
          margin: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF0C1019),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: AetherDropColors.electricCyan.withValues(alpha: 0.45),
              width: 1.4,
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: AetherDropColors.electricCyan.withValues(alpha: 0.16),
                blurRadius: 36,
                spreadRadius: 2,
              ),
              const BoxShadow(
                color: Colors.black,
                blurRadius: 48,
                offset: Offset(0, 16),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // Top Neon Header Bar
              _buildTopBar(),

              // View Selector:
              // 1. Incoming Request Popup
              // 2. Active Transfer Warp Tunnel
              // 3. Completed Celebration Screen
              if (isIncomingRequest)
                _buildIncomingRequestView()
              else if (isCompleted)
                _buildCompletedCelebrationView()
              else
                _buildActiveWarpTunnelView(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF131824),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _status == TransferStatus.completed
                      ? AetherDropColors.neonEmerald
                      : (_status == TransferStatus.transferring
                          ? AetherDropColors.electricCyan
                          : AetherDropColors.liquidGold),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: AetherDropColors.electricCyan.withValues(alpha: 0.6),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'AETHERDROP // WARP TUNNEL V2',
                style: AetherDropTheme.monoStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                  color: AetherDropColors.electricCyan,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(LucideIcons.x, size: 18, color: Colors.white70),
            tooltip: 'Close Modal',
            onPressed: _cancelOrCloseTransfer,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1. INCOMING REQUEST POPUP VIEW
  // ---------------------------------------------------------------------------

  Widget _buildIncomingRequestView() {
    final TransferManifest manifest = widget.incomingManifest!;
    final String senderName = manifest.senderName;
    final String senderAvatar = manifest.senderAvatar;
    final String displayTitle = manifest.displayTitle;
    final String formattedSize = manifest.formattedTotalBytes;
    final bool isFolder = manifest.payloadType.isFolder;

    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        children: <Widget>[
          // Glowing Sender Avatar with Rank Ring
          AvatarBadge(
            avatarId: senderAvatar,
            level: 12,
            size: 78,
            isOnline: true,
            animateRing: true,
          ),
          const SizedBox(height: 18),

          // Title & Lore
          Text(
            '$senderName wants to beam',
            style: AetherDropTheme.bodyStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AetherDropColors.textSecondaryDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            displayTitle,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AetherDropTheme.titleStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),

          // Size and Payload Chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AetherDropColors.electricCyan.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: AetherDropColors.electricCyan.withValues(alpha: 0.45),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  isFolder ? LucideIcons.folder : LucideIcons.file,
                  size: 15,
                  color: AetherDropColors.electricCyan,
                ),
                const SizedBox(width: 8),
                Text(
                  '${manifest.totalItems} item${manifest.totalItems == 1 ? '' : 's'} • $formattedSize',
                  style: AetherDropTheme.monoStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AetherDropColors.electricCyan,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Auto-accept toggle
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF131824),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
                width: 1,
              ),
            ),
            child: Row(
              children: <Widget>[
                const Icon(
                  LucideIcons.flame,
                  size: 18,
                  color: AetherDropColors.liquidGold,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Auto-accept from trusted streak friends',
                    style: AetherDropTheme.bodyStyle(
                      fontSize: 12.5,
                      color: Colors.white,
                    ),
                  ),
                ),
                Switch(
                  value: _autoAcceptStreakFriends,
                  onChanged: _toggleAutoAccept,
                  activeThumbColor: AetherDropColors.electricCyan,
                  activeTrackColor: AetherDropColors.electricCyan.withValues(alpha: 0.35),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Accept & Decline Action Buttons
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton(
                  onPressed: _declineTransfer,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(
                      color: AetherDropColors.crimsonPulse.withValues(alpha: 0.6),
                      width: 1.2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'DECLINE',
                    style: AetherDropTheme.monoStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: AetherDropColors.crimsonPulse,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _acceptTransfer,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AetherDropColors.electricCyan,
                    foregroundColor: AetherDropColors.deepMatteObsidian,
                    elevation: 12,
                    shadowColor: AetherDropColors.electricCyan.withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const Icon(LucideIcons.zap, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'ACCEPT WARP',
                        style: AetherDropTheme.monoStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                          color: AetherDropColors.deepMatteObsidian,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 2. ACTIVE PARTICLE WARP TUNNEL VIEW
  // ---------------------------------------------------------------------------

  Widget _buildActiveWarpTunnelView() {
    final UserProfile? currentUser = AuthService.instance.currentProfile;
    final String myAvatar = currentUser?.avatarId ?? 'starter_cyber_01';
    final int myLevel = currentUser?.level ?? 1;

    final String peerAvatar = _currentProgress?.peerAvatarId ??
        _manifest?.senderAvatar ??
        'starter_cyber_02';
    final String peerName = _currentProgress?.peerDisplayName ??
        _manifest?.senderName ??
        'Remote Node';

    final bool isSender = widget.isSender || (_currentProgress?.isSender ?? false);
    final String senderAvatar = isSender ? myAvatar : peerAvatar;
    final String receiverAvatar = isSender ? peerAvatar : myAvatar;
    final int senderLevel = isSender ? myLevel : 10;
    final int receiverLevel = isSender ? 10 : myLevel;

    final double speedMBps = _currentProgress?.speedMBps ?? 0.0;
    final double progress = (_currentProgress?.progress ?? 0.0).clamp(0.0, 1.0);
    final String percentage = _currentProgress?.percentageDisplay ?? '0%';
    final String volumeDisplay = _currentProgress?.volumeDisplay ?? '0 B / 0 B';
    final String fileCounter = _currentProgress?.fileCounterDisplay ?? 'Streaming...';
    final String currentFileName = _currentProgress?.currentFileName ??
        (_manifest?.files.isNotEmpty == true ? _manifest!.files.first.name : '');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        children: <Widget>[
          // Interactive 60fps Particle Warp Tunnel
          SizedBox(
            height: 180,
            child: Stack(
              children: <Widget>[
                // CustomPainter Particle Stream
                Positioned.fill(
                  child: CustomPaint(
                    painter: _WarpTunnelPainter(
                      particles: _particles,
                      speedMBps: speedMBps,
                    ),
                  ),
                ),

                // Floating Reactions Layer
                Positioned.fill(
                  child: Stack(
                    children: _activeReactions.map((_FloatingReaction r) {
                      return Positioned(
                        left: r.xRatio * 580,
                        top: r.yRatio * 160,
                        child: Opacity(
                          opacity: r.opacity.clamp(0.0, 1.0),
                          child: Transform.scale(
                            scale: r.scale,
                            child: Text(
                              r.emoji,
                              style: const TextStyle(fontSize: 28),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                // Sender Avatar Node (Left)
                Positioned(
                  left: 12,
                  top: 45,
                  child: Column(
                    children: <Widget>[
                      AvatarBadge(
                        avatarId: senderAvatar,
                        level: senderLevel,
                        size: 64,
                        isOnline: true,
                        animateRing: true,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isSender ? 'YOU' : peerName,
                        style: AetherDropTheme.monoStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                // Receiver Avatar Node (Right)
                Positioned(
                  right: 12,
                  top: 45,
                  child: Column(
                    children: <Widget>[
                      AvatarBadge(
                        avatarId: receiverAvatar,
                        level: receiverLevel,
                        size: 64,
                        isOnline: true,
                        animateRing: true,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isSender ? peerName : 'YOU',
                        style: AetherDropTheme.monoStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Massive Digital Futuristic Speedometer
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: <Widget>[
              Text(
                speedMBps.toStringAsFixed(1),
                style: AetherDropTheme.monoStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  color: AetherDropColors.electricCyan,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'MB/s',
                style: AetherDropTheme.monoStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AetherDropColors.plasmaViolet,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // File counter, current file name, and volume
          Text(
            currentFileName.isNotEmpty ? currentFileName : fileCounter,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AetherDropTheme.titleStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$volumeDisplay • ETA ${_currentProgress?.etaDisplay ?? '--'}',
            style: AetherDropTheme.monoStyle(
              fontSize: 12,
              color: AetherDropColors.textSecondaryDark,
            ),
          ),
          const SizedBox(height: 16),

          // Cyber Progress Bar
          Row(
            children: <Widget>[
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    height: 10,
                    color: const Color(0xFF1E293B),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: progress,
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: <Color>[
                                AetherDropColors.electricCyan,
                                AetherDropColors.plasmaViolet,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Text(
                percentage,
                style: AetherDropTheme.monoStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AetherDropColors.electricCyan,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),

          // Interactive Real-Time Reaction Buttons (`⚡`, `🚀`, `🔥`, `💎`)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF111622),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                _buildReactionButton('⚡', 'Electric'),
                _buildReactionButton('🚀', 'Rocket'),
                _buildReactionButton('🔥', 'Streak'),
                _buildReactionButton('💎', 'Diamond'),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Abort Button
          OutlinedButton(
            onPressed: _cancelOrCloseTransfer,
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: Colors.white.withValues(alpha: 0.12),
                width: 1,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'CANCEL WARP',
              style: AetherDropTheme.monoStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: AetherDropColors.textMutedDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReactionButton(String emoji, String tooltip) {
    return InkWell(
      onTap: () {
        WebRTCEngine.instance.sendReaction(emoji);
        _triggerReactionBurst(emoji);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
        child: Text(
          emoji,
          style: const TextStyle(fontSize: 22),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. COMPLETED CELEBRATION VIEW (+WXP Gained!)
  // ---------------------------------------------------------------------------

  Widget _buildCompletedCelebrationView() {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        children: <Widget>[
          // Glowing Celebration Trophy Emblem
          Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AetherDropColors.electricCyan.withValues(alpha: 0.16),
              border: Border.all(
                color: AetherDropColors.electricCyan,
                width: 2,
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: AetherDropColors.electricCyan.withValues(alpha: 0.4),
                  blurRadius: 28,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              LucideIcons.checkCheck,
              size: 40,
              color: AetherDropColors.electricCyan,
            ),
          ),
          const SizedBox(height: 18),

          // Banner Title
          Text(
            '+$_xpEarned WXP GAINED!',
            style: AetherDropTheme.monoStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
              color: AetherDropColors.electricCyan,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'WARP TRANSMISSION 100% COMPLETE',
            style: AetherDropTheme.monoStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AetherDropColors.neonEmerald,
            ),
          ),
          const SizedBox(height: 18),

          // Co-op Streak Pill & Level Up celebration
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: AetherDropColors.liquidGold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: AetherDropColors.liquidGold.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Text('🔥', style: TextStyle(fontSize: 15)),
                    const SizedBox(width: 6),
                    Text(
                      'CO-OP STREAK: $_currentStreak DAYS',
                      style: AetherDropTheme.monoStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: AetherDropColors.liquidGold,
                      ),
                    ),
                  ],
                ),
              ),
              if (_didLevelUp) ...<Widget>[
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AetherDropColors.plasmaViolet.withValues(alpha: 0.20),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: AetherDropColors.plasmaViolet,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '🎉 LEVEL UP: LVL $_newLevel',
                    style: AetherDropTheme.monoStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: AetherDropColors.plasmaViolet,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 28),

          // Action Buttons: Open in Folder & Close
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _openDestinationFolder,
                  icon: const Icon(LucideIcons.folderOpen, size: 18),
                  label: Text(
                    'OPEN IN FOLDER',
                    style: AetherDropTheme.monoStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(
                      color: AetherDropColors.electricCyan,
                      width: 1.2,
                    ),
                    foregroundColor: AetherDropColors.electricCyan,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AetherDropColors.electricCyan,
                    foregroundColor: AetherDropColors.deepMatteObsidian,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'DONE',
                    style: AetherDropTheme.monoStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// PARTICLE ENGINE & PAINTER (60fps Warp Stream)
// -----------------------------------------------------------------------------

class _WarpParticle {
  _WarpParticle({
    required this.x,
    required this.y,
    required this.progress,
    required this.speed,
    required this.size,
    required this.color,
    required this.trailLength,
  });

  double x;
  double y;
  double progress;
  double speed;
  double size;
  Color color;
  double trailLength;
}

class _FloatingReaction {
  _FloatingReaction({
    required this.id,
    required this.emoji,
    required this.xRatio,
    required this.yRatio,
    required this.opacity,
    required this.scale,
    required this.speed,
  });

  final String id;
  final String emoji;
  final double xRatio;
  double yRatio;
  double opacity;
  final double scale;
  final double speed;
}

class _WarpTunnelPainter extends CustomPainter {
  const _WarpTunnelPainter({
    required this.particles,
    required this.speedMBps,
  });

  final List<_WarpParticle> particles;
  final double speedMBps;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset startPoint = Offset(50, size.height / 2);
    final Offset endPoint = Offset(size.width - 50, size.height / 2);

    // 1. Draw glowing quantum conduit center line
    final Paint conduitPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..shader = LinearGradient(
        colors: <Color>[
          AetherDropColors.electricCyan.withValues(alpha: 0.15),
          AetherDropColors.plasmaViolet.withValues(alpha: 0.55),
          AetherDropColors.electricCyan.withValues(alpha: 0.15),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final Path centerPath = Path()
      ..moveTo(startPoint.dx, startPoint.dy)
      ..quadraticBezierTo(
        size.width / 2,
        size.height / 2 + 15,
        endPoint.dx,
        endPoint.dy,
      );
    canvas.drawPath(centerPath, conduitPaint);

    // 2. Draw active streaming energy packets (particles)
    for (final _WarpParticle p in particles) {
      final double t = p.progress;
      final double curveFactor = math.sin(t * math.pi) * 35.0 * (p.y - 0.5);

      final double px = startPoint.dx + (endPoint.dx - startPoint.dx) * t;
      final double py = startPoint.dy + (endPoint.dy - startPoint.dy) * t + curveFactor;

      final double trailT = math.max(0.0, t - p.trailLength);
      final double trailCurve = math.sin(trailT * math.pi) * 35.0 * (p.y - 0.5);
      final double tx = startPoint.dx + (endPoint.dx - startPoint.dx) * trailT;
      final double ty = startPoint.dy + (endPoint.dy - startPoint.dy) * trailT + trailCurve;

      final double alpha = math.sin(t * math.pi);

      // Glowing trail line
      final Paint trailPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = p.size * 0.7
        ..strokeCap = StrokeCap.round
        ..shader = LinearGradient(
          colors: <Color>[
            p.color.withValues(alpha: 0.0),
            p.color.withValues(alpha: alpha * 0.8),
          ],
        ).createShader(Rect.fromPoints(Offset(tx, ty), Offset(px, py)));

      canvas.drawLine(Offset(tx, ty), Offset(px, py), trailPaint);

      // Energy packet head
      final Paint headPaint = Paint()
        ..color = p.color.withValues(alpha: alpha)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(px, py), p.size * 0.8, headPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _WarpTunnelPainter oldDelegate) => true;
}
