import 'dart:async';
import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/gamification.dart';
import '../../core/theme.dart';
import '../../models/transfer_manifest.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../../services/clipboard_service.dart';
import '../../services/signaling_service.dart';
import '../../services/webrtc_engine.dart';
import '../widgets/avatar_badge.dart';
import '../widgets/glass_card.dart';
import 'transfer_warp_modal.dart';
import 'vault_avatars_screen.dart';

/// The central Home Radar screen providing Global Real-Time Search, Interactive
/// Peer Grid with Co-Op Streaks, 4 Ways to Send (Drag & Drop, Send Files/Folder,
/// Beam Clipboard with `Ctrl+V`/`Cmd+V`, Quick Note/Code), and incoming warp popups.
class HomeRadarScreen extends StatefulWidget {
  const HomeRadarScreen({
    required this.themeProvider,
    super.key,
  });

  final ThemeProvider themeProvider;

  @override
  State<HomeRadarScreen> createState() => _HomeRadarScreenState();
}

class _HomeRadarScreenState extends State<HomeRadarScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<UserProfile> _searchResults = <UserProfile>[];
  List<RecentPeer> _recentPeers = <RecentPeer>[];
  bool _isSearching = false;
  bool _isLoadingPeers = true;
  String? _selectedPeerId;

  // Stream Subscriptions
  StreamSubscription<TransferManifest>? _incomingInvitationSub;
  StreamSubscription<IncomingClipboardPayload>? _incomingClipboardSub;

  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _loadRecentPeers();
    _setupEngineListeners();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _incomingInvitationSub?.cancel();
    _incomingClipboardSub?.cancel();
    super.dispose();
  }

  void _setupEngineListeners() {
    // 1. Listen for incoming transfer invitations and open the Neon Cyan Warp Modal
    _incomingInvitationSub = WebRTCEngine.instance.incomingInvitationStream.listen(
      (TransferManifest manifest) {
        if (!mounted) return;
        TransferWarpModal.show(context, incomingManifest: manifest);
      },
    );

    // 2. Listen for incoming clipboard broadcasts (instant notes/code/screenshots)
    _incomingClipboardSub = WebRTCEngine.instance.incomingClipboardStream.listen(
      (IncomingClipboardPayload payload) {
        if (!mounted) return;
        _showIncomingClipboardNotification(payload);
      },
    );
  }

  void _showIncomingClipboardNotification(IncomingClipboardPayload payload) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF0F1420),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(
            color: AetherDropColors.electricCyan,
            width: 1.2,
          ),
        ),
        content: Row(
          children: <Widget>[
            AvatarBadge(
              avatarId: payload.senderAvatar,
              level: 8,
              size: 40,
              showLevelPill: false,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    '${payload.senderName} beamed clipboard!',
                    style: AetherDropTheme.titleStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    payload.type == ClipboardPayloadType.text
                        ? (payload.text != null && payload.text!.length > 40
                            ? '${payload.text!.substring(0, 40)}...'
                            : payload.text ?? 'Text Note')
                        : 'Screenshot PNG image',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AetherDropTheme.monoStyle(
                      fontSize: 11,
                      color: AetherDropColors.textSecondaryDark,
                    ),
                  ),
                ],
              ),
            ),
            if (payload.type == ClipboardPayloadType.text && payload.text != null)
              TextButton.icon(
                onPressed: () {
                  ClipboardService.instance.copyTextToClipboard(payload.text!);
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
                icon: const Icon(LucideIcons.copy, size: 14),
                label: const Text('COPY'),
                style: TextButton.styleFrom(
                  foregroundColor: AetherDropColors.electricCyan,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadRecentPeers() async {
    setState(() => _isLoadingPeers = true);
    final List<RecentPeer> peers =
        await SignalingService.instance.getRecentPeers();
    if (mounted) {
      setState(() {
        _recentPeers = peers;
        _isLoadingPeers = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = <UserProfile>[];
        _isSearching = false;
      });
      return;
    }

    _searchDebounce = Timer(const Duration(milliseconds: 250), () async {
      setState(() => _isSearching = true);
      final List<UserProfile> results =
          await SignalingService.instance.searchUsersByEmailOrName(query.trim());
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    });
  }

  void _selectPeer(String peerId) {
    setState(() {
      _selectedPeerId = _selectedPeerId == peerId ? null : peerId;
    });
    ClipboardService.instance.setSelectedPeer(_selectedPeerId);
  }

  // ---------------------------------------------------------------------------
  // 4 WAYS TO SEND ACTIONS
  // ---------------------------------------------------------------------------

  /// 1. Handle Drag & Drop of files/folders onto a person's card
  Future<void> _handleDropFiles(String targetUserId, List<String> paths) async {
    if (paths.isEmpty) return;

    final String first = paths.first;
    final bool isDir = await Directory(first).exists();

    if (isDir && paths.length == 1) {
      // Direct folder beam
      await WebRTCEngine.instance.sendFolder(
        targetUserId: targetUserId,
        folderPath: first,
      );
    } else {
      // Direct files beam
      await WebRTCEngine.instance.sendFiles(
        targetUserId: targetUserId,
        filePaths: paths,
      );
    }

    if (mounted) {
      TransferWarpModal.show(context, isSender: true);
    }
  }

  /// 2a. Send Files button click
  Future<void> _sendFilesToPeer(String targetUserId) async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
      );
      if (result == null || result.paths.isEmpty) return;

      final List<String> validPaths =
          result.paths.whereType<String>().toList();
      if (validPaths.isEmpty) return;

      await WebRTCEngine.instance.sendFiles(
        targetUserId: targetUserId,
        filePaths: validPaths,
      );

      if (mounted) {
        TransferWarpModal.show(context, isSender: true);
      }
    } catch (e) {
      _showError('Error selecting files: $e');
    }
  }

  /// 2b. Send Folder button click
  Future<void> _sendFolderToPeer(String targetUserId) async {
    try {
      final String? selectedDirectory =
          await FilePicker.platform.getDirectoryPath();
      if (selectedDirectory == null || selectedDirectory.isEmpty) return;

      await WebRTCEngine.instance.sendFolder(
        targetUserId: targetUserId,
        folderPath: selectedDirectory,
      );

      if (mounted) {
        TransferWarpModal.show(context, isSender: true);
      }
    } catch (e) {
      _showError('Error selecting folder: $e');
    }
  }

  /// 3. Beam Clipboard (`Ctrl+V` / `Cmd+V` or tap button)
  Future<void> _beamClipboardToPeer(String targetUserId) async {
    final bool sent = await ClipboardService.instance.pasteAndBeam(
      targetUserId: targetUserId,
    );

    if (sent) {
      if (mounted) {
        TransferWarpModal.show(context, isSender: true);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AetherDropColors.elevatedObsidian,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(
                color: AetherDropColors.liquidGold,
                width: 1,
              ),
            ),
            content: Row(
              children: <Widget>[
                const Icon(
                  LucideIcons.clipboardX,
                  size: 18,
                  color: AetherDropColors.liquidGold,
                ),
                const SizedBox(width: 12),
                Text(
                  'Your clipboard is currently empty.',
                  style: AetherDropTheme.bodyStyle(
                    fontSize: 13,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }
  }

  /// 4. Quick Note / Code snippet modal
  void _openQuickNoteDialog(String targetUserId, String targetDisplayName) {
    final TextEditingController textController = TextEditingController();

    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      barrierLabel: 'Quick Note',
      transitionDuration: const Duration(milliseconds: 220),
      transitionBuilder: (BuildContext context, Animation<double> a1, Animation<double> a2, Widget child) {
        return Transform.scale(
          scale: 0.94 + 0.06 * Curves.easeOutCubic.transform(a1.value),
          child: Opacity(
            opacity: a1.value,
            child: child,
          ),
        );
      },
      pageBuilder: (BuildContext context, _, __) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 540,
              margin: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF0F1420),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: AetherDropColors.electricCyan.withValues(alpha: 0.45),
                  width: 1.2,
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: AetherDropColors.electricCyan.withValues(alpha: 0.15),
                    blurRadius: 32,
                  ),
                  const BoxShadow(
                    color: Colors.black,
                    blurRadius: 40,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          const Icon(
                            LucideIcons.code,
                            size: 18,
                            color: AetherDropColors.electricCyan,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'QUICK NOTE / CODE BEAM',
                            style: AetherDropTheme.monoStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                              color: AetherDropColors.electricCyan,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.x, size: 18),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Beam formatted text, source code, API keys, or URLs directly to $targetDisplayName.',
                    style: AetherDropTheme.bodyStyle(
                      fontSize: 12.5,
                      color: AetherDropColors.textSecondaryDark,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 180,
                    decoration: BoxDecoration(
                      color: const Color(0xFF090D14),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.10),
                        width: 1,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    child: TextField(
                      controller: textController,
                      maxLines: null,
                      expands: true,
                      style: AetherDropTheme.monoStyle(
                        fontSize: 13,
                        color: Colors.white,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Type or paste code snippet, markdown, or credentials here...',
                        hintStyle: TextStyle(
                          color: AetherDropColors.textMutedDark,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          'CANCEL',
                          style: AetherDropTheme.monoStyle(
                            fontSize: 12,
                            color: AetherDropColors.textSecondaryDark,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final String text = textController.text.trim();
                          if (text.isEmpty) return;
                          Navigator.of(context).pop();
                          await ClipboardService.instance.beamCustomText(
                            targetUserId: targetUserId,
                            text: text,
                          );
                          if (mounted) {
                            TransferWarpModal.show(this.context, isSender: true);
                          }
                        },
                        icon: const Icon(LucideIcons.zap, size: 16),
                        label: Text(
                          'BEAM NOW',
                          style: AetherDropTheme.monoStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                          backgroundColor: AetherDropColors.electricCyan,
                          foregroundColor: AetherDropColors.deepMatteObsidian,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AetherDropColors.crimsonPulse,
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final UserProfile profile = AuthService.instance.currentProfile ??
        UserProfile(
          id: 'temp_node',
          email: 'node@aetherdrop.net',
          displayName: 'Warp Explorer',
          lastSeen: DateTime.now(),
        );

    final LevelProgress progress =
        Gamification.getProgressToNextLevel(profile.xp);
    final String rankTitle = Gamification.getRankTitle(profile.level);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1080),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  // 1. Top Header Bar
                  _buildHeaderBar(context, profile, progress, rankTitle, isDark),
                  const SizedBox(height: 24),

                  // 2. Global Instant Search Bar
                  _buildSearchBar(),
                  const SizedBox(height: 24),

                  // Search Results (if searching)
                  if (_searchResults.isNotEmpty) ...<Widget>[
                    _buildSearchResultsSection(),
                    const SizedBox(height: 24),
                  ],

                  // 3. Interactive Peer Grid / Radar View
                  _buildPeerGridSection(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1. TOP HEADER BAR
  // ---------------------------------------------------------------------------

  Widget _buildHeaderBar(
    BuildContext context,
    UserProfile profile,
    LevelProgress progress,
    String rankTitle,
    bool isDark,
  ) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
      child: Row(
        children: <Widget>[
          // Avatar with glowing rank ring
          AvatarBadge(
            avatarId: profile.avatarId,
            level: profile.level,
            size: 64,
            isOnline: true,
            animateRing: true,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const VaultAvatarsScreen(),
                ),
              );
            },
          ),
          const SizedBox(width: 18),

          // Display Name, Email, Rank, and XP Progress
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Flexible(
                      child: Text(
                        profile.displayName,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AetherDropColors.electricCyan.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: AetherDropColors.electricCyan.withValues(alpha: 0.5),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'LVL ${profile.level} — $rankTitle'.toUpperCase(),
                        style: AetherDropTheme.monoStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AetherDropColors.electricCyan,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  profile.email,
                  style: AetherDropTheme.monoStyle(
                    fontSize: 12,
                    color: AetherDropColors.textSecondaryDark,
                  ),
                ),
                const SizedBox(height: 8),
                // WXP Progress Bar
                Row(
                  children: <Widget>[
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: progress.progress,
                          minHeight: 6,
                          backgroundColor: const Color(0xFF1E293B),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AetherDropColors.electricCyan,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${profile.xp} WXP (${progress.percentageText})',
                      style: AetherDropTheme.monoStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AetherDropColors.electricCyan,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Button to open the Avatar & Rank Vault
          OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const VaultAvatarsScreen(),
                ),
              );
            },
            icon: const Icon(LucideIcons.shieldAlert, size: 16),
            label: Text(
              'VAULT',
              style: AetherDropTheme.monoStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              side: BorderSide(
                color: AetherDropColors.electricCyan.withValues(alpha: 0.5),
                width: 1,
              ),
              foregroundColor: AetherDropColors.electricCyan,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Theme Toggle
          IconButton(
            tooltip: isDark ? 'Light Glass Mode' : 'Dark Glass Mode',
            onPressed: widget.themeProvider.toggleTheme,
            icon: Icon(
              isDark ? LucideIcons.sun : LucideIcons.moon,
              color: AetherDropColors.electricCyan,
            ),
          ),

          // Sign Out
          IconButton(
            tooltip: 'Sign Out Node',
            onPressed: () async {
              await SignalingService.instance.disconnect();
              await AuthService.instance.signOut();
            },
            icon: const Icon(
              LucideIcons.logOut,
              size: 20,
              color: AetherDropColors.textMutedDark,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 2. GLOBAL INSTANT SEARCH BAR
  // ---------------------------------------------------------------------------

  Widget _buildSearchBar() {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: <Widget>[
          const Icon(
            LucideIcons.search,
            size: 20,
            color: AetherDropColors.electricCyan,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: AetherDropTheme.bodyStyle(
                fontSize: 14.5,
                color: Colors.white,
              ),
              decoration: InputDecoration(
                hintText: 'Search anyone globally by email or name...',
                hintStyle: AetherDropTheme.bodyStyle(
                  fontSize: 14,
                  color: AetherDropColors.textMutedDark,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (_isSearching)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AetherDropColors.electricCyan,
              ),
            )
          else if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(LucideIcons.x, size: 18),
              onPressed: () {
                _searchController.clear();
                _onSearchChanged('');
              },
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SEARCH RESULTS
  // ---------------------------------------------------------------------------

  Widget _buildSearchResultsSection() {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'MATCHING NODES (${_searchResults.length})',
            style: AetherDropTheme.monoStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
              color: AetherDropColors.electricCyan,
            ),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final double cardWidth = constraints.maxWidth > 720
                  ? (constraints.maxWidth - 16) / 2
                  : constraints.maxWidth;

              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: _searchResults.map((UserProfile peer) {
                  final bool isOnline =
                      SignalingService.instance.isUserOnline(peer.id);
                  return SizedBox(
                    width: cardWidth,
                    child: _buildPersonWarpCard(
                      peer: peer,
                      streakCount: 0,
                      isOnline: isOnline,
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. INTERACTIVE PEER GRID / RADAR VIEW
  // ---------------------------------------------------------------------------

  Widget _buildPeerGridSection() {
    final int onlineCount = SignalingService.instance.onlineUserIds.length;

    return GlassCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Section Title & Online Nodes Counter
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const Icon(
                    LucideIcons.radar,
                    size: 18,
                    color: AetherDropColors.electricCyan,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'RECENT CO-OP RADAR & STREAKS',
                    style: AetherDropTheme.monoStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.4,
                      color: AetherDropColors.electricCyan,
                    ),
                  ),
                ],
              ),
              Row(
                children: <Widget>[
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AetherDropColors.neonEmerald,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$onlineCount Online Ready',
                    style: AetherDropTheme.monoStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AetherDropColors.neonEmerald,
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: const Icon(LucideIcons.refreshCw, size: 15),
                    tooltip: 'Refresh Peers',
                    onPressed: _loadRecentPeers,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (_isLoadingPeers)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AetherDropColors.electricCyan,
                ),
              ),
            )
          else if (_recentPeers.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 36),
                child: Column(
                  children: <Widget>[
                    Icon(
                      LucideIcons.users,
                      size: 42,
                      color: AetherDropColors.textMutedDark.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No peer connections in your radar history yet.',
                      style: AetherDropTheme.titleStyle(
                        fontSize: 14.5,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Search any friend by email above to ignite your Co-Op Streak!',
                      style: AetherDropTheme.bodyStyle(
                        fontSize: 12.5,
                        color: AetherDropColors.textSecondaryDark,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final double cardWidth = constraints.maxWidth > 720
                    ? (constraints.maxWidth - 16) / 2
                    : constraints.maxWidth;

                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: _recentPeers.map((RecentPeer peer) {
                    final bool isOnline =
                        SignalingService.instance.isUserOnline(peer.profile.id);
                    return SizedBox(
                      width: cardWidth,
                      child: _buildPersonWarpCard(
                        peer: peer.profile,
                        streakCount: peer.streakCount,
                        isOnline: isOnline,
                      ),
                    );
                  }).toList(),
                );
              },
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // PERSON WARP CARD (WITH 4 WAYS TO SEND + DRAG & DROP)
  // ---------------------------------------------------------------------------

  Widget _buildPersonWarpCard({
    required UserProfile peer,
    required int streakCount,
    required bool isOnline,
  }) {
    final bool isSelected = _selectedPeerId == peer.id;

    return DropTarget(
      onDragDone: (DropDoneDetails details) {
        final List<String> paths =
            details.files.map((file) => file.path).toList();
        _handleDropFiles(peer.id, paths);
      },
      child: InkWell(
        onTap: () => _selectPeer(peer.id),
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: isSelected
                ? AetherDropColors.electricCyan.withValues(alpha: 0.10)
                : const Color(0xFF111622),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected
                  ? AetherDropColors.electricCyan
                  : Colors.white.withValues(alpha: 0.08),
              width: isSelected ? 1.8 : 1.0,
            ),
            boxShadow: isSelected
                ? <BoxShadow>[
                    BoxShadow(
                      color: AetherDropColors.electricCyan.withValues(alpha: 0.22),
                      blurRadius: 18,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // Peer Top Info: Avatar, Name, Email, Streak Pill & Online Status
              Row(
                children: <Widget>[
                  AvatarBadge(
                    avatarId: peer.avatarId,
                    level: peer.level,
                    size: 52,
                    isOnline: isOnline,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          peer.displayName,
                          style: AetherDropTheme.titleStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          peer.email,
                          style: AetherDropTheme.monoStyle(
                            fontSize: 11.5,
                            color: AetherDropColors.textSecondaryDark,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        // Online / Offline Badge
                        Row(
                          children: <Widget>[
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isOnline
                                    ? AetherDropColors.neonEmerald
                                    : AetherDropColors.textMutedDark,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isOnline ? '⚡ Online Ready' : 'Offline',
                              style: AetherDropTheme.monoStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: isOnline
                                    ? AetherDropColors.neonEmerald
                                    : AetherDropColors.textMutedDark,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Co-Op Streak Flame Pill
                  if (streakCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AetherDropColors.liquidGold.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: AetherDropColors.liquidGold.withValues(alpha: 0.5),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '🔥 $streakCount Day${streakCount == 1 ? '' : 's'}',
                        style: AetherDropTheme.monoStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: AetherDropColors.liquidGold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),

              // Drag & Drop Hint Banner
              Container(
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.05),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    'Drag & Drop any files or folders directly here',
                    style: AetherDropTheme.monoStyle(
                      fontSize: 10,
                      color: AetherDropColors.textMutedDark,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 4 Ways to Send Action Bar
              Row(
                children: <Widget>[
                  // 1. Send Files
                  Expanded(
                    child: _buildActionPill(
                      icon: LucideIcons.fileUp,
                      label: 'Files',
                      color: AetherDropColors.electricCyan,
                      onTap: () => _sendFilesToPeer(peer.id),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // 2. Send Folder
                  Expanded(
                    child: _buildActionPill(
                      icon: LucideIcons.folderUp,
                      label: 'Folder',
                      color: AetherDropColors.hyperCobalt,
                      onTap: () => _sendFolderToPeer(peer.id),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // 3. Beam Clipboard
                  Expanded(
                    child: _buildActionPill(
                      icon: LucideIcons.clipboardPaste,
                      label: 'Clipboard',
                      color: AetherDropColors.plasmaViolet,
                      onTap: () => _beamClipboardToPeer(peer.id),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // 4. Quick Note / Code
                  Expanded(
                    child: _buildActionPill(
                      icon: LucideIcons.code,
                      label: 'Code',
                      color: AetherDropColors.neonEmerald,
                      onTap: () => _openQuickNoteDialog(peer.id, peer.displayName),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionPill({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: color.withValues(alpha: 0.35),
            width: 1,
          ),
        ),
        child: Column(
          children: <Widget>[
            Icon(icon, size: 14, color: color),
            const SizedBox(height: 3),
            Text(
              label,
              style: AetherDropTheme.monoStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
