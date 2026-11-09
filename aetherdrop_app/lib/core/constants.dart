/// Core configuration constants for the AetherDrop P2P ecosystem.
library;

/// Paste your Supabase Project URL here (e.g. 'https://your-project.supabase.co').
const String supabaseUrl = 'https://gwllezqyrrmdqptlerxv.supabase.co/rest/v1/';

/// Paste your Supabase anon public key here.
const String supabaseAnonKey =
    'sb_publishable_nvtjAl-VGk4fcDYMbZTVbg_HFcsIhlc';

/// Binary chunk size (256 KB = 262,144 bytes) for maximum WebRTC DataChannel
/// throughput without buffer overflow.
const int chunkSize = 262144;

/// Free public Google and Cloudflare STUN servers for NAT hole-punching.
const List<String> stunServers = <String>[
  'stun:stun.l.google.com:19302',
  'stun:stun1.l.google.com:19302',
  'stun:stun.cloudflare.com:3478',
];

/// Centralized application constants for AetherDrop.
class AppConstants {
  AppConstants._();

  /// Application display name.
  static const String appName = 'AetherDrop';

  /// Application tagline.
  static const String appTagline =
      'Zero-Cost Ultra-Fast Peer-to-Peer Warp Transfer';

  /// Paste your Supabase Project URL here.
  static const String supabaseUrl = 'https://gwllezqyrrmdqptlerxv.supabase.co';

  /// Paste your Supabase anon public key here.
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd3bGxlenF5cnJtZHFwdGxlcnh2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTQxOTU3ODMsImV4cCI6MjEwOTc3MTc4M30.GelKdXYYV_kFidx0S7a1pA07U8kqh5LnQtq5XpA7Ols';

  /// Free public STUN server URIs for global NAT traversal.
  static const List<String> stunServerUrls = <String>[
    'stun:stun.l.google.com:19302',
    'stun:stun1.l.google.com:19302',
    'stun:stun.cloudflare.com:3478',
  ];

  /// Standard WebRTC `iceServers` configuration map ready for `RTCPeerConnection`.
  static const Map<String, dynamic> rtcConfiguration = <String, dynamic>{
    'iceServers': <Map<String, dynamic>>[
      <String, dynamic>{
        'urls': <String>[
          'stun:stun.l.google.com:19302',
          'stun:stun1.l.google.com:19302',
          'stun:stun.cloudflare.com:3478',
        ],
      },
    ],
    'sdpSemantics': 'unified-plan',
  };

  /// WebRTC primary ordered data channel label.
  static const String dataChannelLabel = 'aetherdrop-warp-pipe';

  /// 256 KB (262,144 bytes) binary chunk size for maximum WebRTC DataChannel
  /// throughput without buffer overflow.
  static const int chunkSize = 262144;

  /// Backpressure low-water threshold (1 MB = 1,048,576 bytes).
  static const int bufferedAmountLowThreshold = 1048576;

  /// Backpressure high-water pause threshold (4 MB = 4,194,304 bytes).
  static const int maxBufferedAmount = 4194304;

  /// Global presence channel for tracking online nodes.
  static const String presenceChannelName = 'online-nodes';

  /// Prefix for user-targeted signaling channels (`signal:<USER_ID>`).
  static const String signalChannelPrefix = 'signal:';

  /// Default sub-folder inside the user's Downloads directory.
  static const String downloadSubdirectory = 'AetherDrop';
}
