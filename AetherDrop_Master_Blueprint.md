# ⚡ AETHERDROP — The Complete Zero-Cost P2P Ecosystem Master Blueprint
**Native Flutter App (Android, iOS, Windows, macOS) + Dark Glassmorphic Promo Web Portal + Gamified Progression Engine + OpenCode Automation Prompts**

---

## 🌟 1. Executive Vision & Architecture Overview

**AetherDrop** is a next-generation, zero-cost, peer-to-peer (P2P) warp transfer application built from a single **Flutter** codebase for **Android (`.apk`)**, **iOS (`.ipa`)**, **Windows (`.exe`)**, and **macOS (`.dmg`)**, paired with an ultra-minimalist **Dark Glassmorphic Promotional Web Portal**.

### Why AetherDrop Costs $0.00 Forever
Traditional cloud transfer services upload your files to expensive remote storage buckets and charge monthly subscriptions. **AetherDrop never stores a single byte of your files in the cloud.**
1. **Identity & Discovery (Supabase Free Tier):** Handles passwordless Email login, stores user profiles (`email`, `display_name`, `avatar_id`, `xp`, `level`, `streak`), and broadcasts who is currently online.
2. **Signaling & Handshake (Supabase Realtime Channels):** When Person 1 searches for Person 2 by email and clicks **Send**, a lightweight JSON handshake (< 2 KB) exchanges network coordinates (ICE Candidates & SDP Offers) in milliseconds.
3. **The Direct Warp Pipe (WebRTC Data Channels):** Once connected, the server steps out of the way. Data streams **directly from Device A's disk/RAM to Device B's disk**:
   - **Same Wi-Fi / LAN:** Automatically detects local IP candidates (`192.168.x.x`) and transfers at full hardware router speed (**100 MB/s to 1 Gbps+**) without touching the internet.
   - **Across the World (WAN):** Uses **Google's Free Global STUN Servers** (`stun:stun.l.google.com:19302`) for NAT hole-punching and **Cloudflare Calls Free TURN Tier** (1,000 GB/month free relay) for strict carrier firewalls.
4. **Installer Hosting & Cross-OS Compilation (GitHub Releases + GitHub Actions):** Your promotional website sits on **Vercel (Free)**, and the download buttons (`.exe`, `.dmg`, `.apk`, `.ipa`) pull directly from **GitHub Releases (Free Unlimited Bandwidth)**. Better yet, **GitHub Actions** compiles the macOS `.dmg` and iOS `.ipa` on Apple cloud runners for free—even if you are coding on a Windows PC!

---

## 🎮 2. Interactive Gamification & Unique Features (Why People Will Love Using AetherDrop)

To make AetherDrop feel alive, addictive, and wildly more engaging than standard utility apps, the app integrates a **Cyber-Progression & Social Warp System**:

### A. Warp XP (WXP) & Tiered Avatar Evolution
Every action earns **Warp XP (WXP)**, verified and synced to the user's Supabase profile:
- **+50 WXP** per file or clipboard transfer completed.
- **+10 WXP** per 100 MB of data beamed.
- **+150 WXP** bonus for transferring an entire multi-file folder structure.
- **+200 WXP** daily login & first-transfer bonus.

As users level up, they unlock **24+ Exclusive Cyber Avatars, Animated Profile Rings, and Warp Beam Skins**:
| Level | Rank Title | Megabytes Required | Unlocks |
| :--- | :--- | :--- | :--- |
| **Lvl 1** | **Spark Node** | 0 MB (Starter) | 4 Starter Geometric Avatars + Matte Slate Ring |
| **Lvl 5** | **Pulse Runner** | 500 MB + 10 Transfers | Electric Cyan Neon Ring + *Cyber Kitsune* & *Void Bot* Avatars |
| **Lvl 10** | **Data Architect** | 5 GB + 50 Transfers | Plasma Violet Animated Border + *Holo-Samurai* Avatar + Custom Beam Sound |
| **Lvl 25** | **Quantum Conduit** | 50 GB + 200 Transfers | Liquid Gold Glass Frame + *Astral Phoenix* Avatar + Matrix Particle Trail |
| **Lvl 50** | **Singularity Core** | 250 GB + 500 Transfers | Event Horizon Black-Hole Halo + *Apex Omniscient* Avatar + Global Leaderboard Badge |

### B. Interactive Features That Set AetherDrop Apart
1. **⚡ Instant Ghost Clipboard (`Ctrl+V` / `Cmd+V` Anywhere):**
   - Copy text, code snippets, links, or a screenshot on your laptop -> click on a friend's avatar in AetherDrop -> press `Ctrl+V`. It immediately beams straight into their clipboard or pops up as a glowing interactive card with a 1-click **"Copy / Save"** button.
2. **🔥 Co-Op Warp Streaks:**
   - When two users send files/notes to each other on consecutive days, a **Cyan Streak Flame** (`🔥 7 Days`) ignites next to their connection card, multiplying WXP earned between those two friends by **1.5x**.
3. **🌌 Interactive Particle Warp Tunnel UI:**
   - Instead of a boring flat progress bar, active transfers render a 60fps HTML5/Flutter Canvas **Particle Stream** between Sender and Receiver avatars. Users can tap/click the stream to send live emoji reactions (`⚡`, `🚀`, `🔥`) that fly across the screen to the other person in real time while waiting for big folders to finish!
4. **📁 Recursive Folder Reconstruction:**
   - Drop a whole project folder containing 50 subfolders and 400 files. AetherDrop packages a lightweight JSON directory tree manifest first, streams the raw chunks sequentially over a single multi-channel pipe, and rebuilds the exact folder hierarchy on the receiver's device automatically.
5. **📌 Floating Desktop Drop-Pill (Windows & macOS):**
   - Minimize AetherDrop into a tiny, translucent glass pill on the corner of your screen. Drag any file onto the pill, and your top 3 pinned friends pop out as glowing orbs—drop the file on an orb to beam it instantly.

---

## 📂 3. Complete Master Folder Structure

Create a single master folder on your computer named `aetherdrop-ecosystem`. Both your Flutter native app and your promotional website will live inside this clean monorepo:

```text
aetherdrop-ecosystem/
├── supabase/
│   └── master_schema.sql              # Complete SQL for Auth, Profiles, XP, Avatars & Realtime
├── aetherdrop_app/                    # FLUTTER NATIVE APP (Android, iOS, Windows, macOS)
│   ├── pubspec.yaml                   # Dependencies (supabase_flutter, flutter_webrtc, etc.)
│   ├── assets/
│   │   ├── avatars/                   # Tier 1 to Tier 5 SVG/PNG Avatars
│   │   └── sounds/                    # Subtle futuristic UI & warp completion chimes
│   ├── lib/
│   │   ├── main.dart                  # App Entry, Dark Theme (#0A0A0A), Window Manager
│   │   ├── core/
│   │   │   ├── constants.dart         # Supabase URL, Anon Key, STUN/TURN configs
│   │   │   ├── theme.dart             # Glassmorphism styles, Electric Cyan (#00F0FF) palette
│   │   │   └── gamification.dart      # WXP Calculator, Level-Up Logic, Avatar Unlock Registry
│   │   ├── models/
│   │   │   ├── user_profile.dart      # Email, Name, Avatar, XP, Level, Online Status
│   │   │   └── transfer_manifest.dart # File/Folder metadata, chunk count, MIME types
│   │   ├── services/
│   │   │   ├── auth_service.dart      # First-time Email + Name + Avatar Onboarding
│   │   │   ├── signaling_service.dart # Supabase Realtime User Search, Presence & WebRTC SDP
│   │   │   ├── webrtc_engine.dart     # Ultra-fast 256KB Chunked File/Folder/Clipboard Streamer
│   │   │   └── clipboard_service.dart # Global Ctrl+V text & raw image buffer handler
│   │   └── ui/
│   │       ├── screens/
│   │       │   ├── onboarding_screen.dart   # 1-Step Email + Profile Name + Avatar Picker
│   │       │   ├── home_radar_screen.dart   # Email Search Bar, Recent Friends, Online Dots
│   │       │   ├── transfer_warp_modal.dart # Live Particle Stream, Speedometer (MB/s)
│   │       │   └── vault_avatars_screen.dart# Progression Tree, Unlocked Avatars, Badges
│   │       └── widgets/
│   │           ├── glass_card.dart          # Reusable Frosted Glass Container
│   │           ├── avatar_badge.dart        # Avatar with Glowing Level Ring
│   │           └── drop_zone_overlay.dart   # Drag & Drop File/Folder Detector
│   └── .github/workflows/
│       └── build_all_platforms.yml    # Automated Cloud Builder for .exe, .dmg, .apk, .ipa
└── aetherdrop_web/                    # PROMOTIONAL & DOWNLOAD WEBSITE
    ├── index.html                     # Ultra-minimalist Dark Glassmorphism Landing Page
    ├── styles.css                     # Responsive Grid, Neon Glows, Smooth Animations
    ├── app.js                         # OS Auto-Detector, Direct Installer Downloader, Live Stats
    └── vercel.json                    # Zero-config deployment rules
```

---

## 🛠️ 4. Step-by-Step Supabase Setup (Every Single Click Explained)

Follow these exact steps to configure your 100% free backend in under 10 minutes.

### Step 4.1: Create Your Free Supabase Account & Project
1. Open your browser and go to **[https://supabase.com](https://supabase.com)**.
2. Click the green **"Start your project"** button in the top-right corner.
3. Click **"Continue with GitHub"** (recommended) or sign up with your email address.
4. Once inside the Supabase Dashboard, click **"New Project"**.
5. Fill in the project creation form:
   - **Organization:** Select your personal organization.
   - **Name:** `AetherDrop-Core`
   - **Database Password:** Click **"Generate a password"** and copy it somewhere safe (you rarely need it directly, as we use API keys).
   - **Region:** Choose **Mumbai (ap-south-1)** (or the closest region to you for lowest signaling latency).
   - **Pricing Plan:** Keep it on **Free ($0/month)**.
6. Click **"Create new project"** and wait ~60 seconds while your database spins up.

### Step 4.2: Copy Your API Credentials
1. In the left sidebar of your Supabase Dashboard, click the **Project Settings (Gear Icon ⚙️)** at the very bottom.
2. Click **"API"** (or **"Data API"**) under the Configuration menu.
3. Keep this page open or copy two things into Notepad:
   - **Project URL:** Looks like `https://abcdefghijklmnop.supabase.co`
   - **Project API Keys (`anon` `public`):** A long string starting with `eyJhbGciOi...`

### Step 4.3: Configure Frictionless Email Login (No Password Needed)
You want users to open the app for the first time, enter their email, name, and avatar, and be logged in forever. Here are the two ways to configure this in Supabase:

#### **Method A: Instant Frictionless Email Entry (Zero Waiting for OTP — Best for Fast Testing & Competitions)**
1. In the left sidebar, click the **Authentication (Lock Icon 🔒)**.
2. Under **Configuration**, click **"Providers"** -> click **"Email"**.
3. Ensure **"Enable Email provider"** is turned **ON**.
4. Toggle **"Confirm email"** to **OFF**.
5. Click **"Save"**.
   - *How this works:* When a user enters `vansh@gmail.com` + their Name + Avatar on first launch, the app deterministic-hashes a background token for their email (`supabase.auth.signUp` / `signInWithPassword` behind the scenes) or logs them straight in without forcing them to leave the app to check their inbox!

#### **Method B: 6-Digit Email OTP Code (For Strict Production Security)**
1. If you want users to verify ownership of their email with a 6-digit code, keep **"Confirm email"** **ON**.
2. Go to **Authentication** -> **Email Templates** -> **Magic Link**.
3. Change the email body to show `{{ .Token }}` instead of `{{ .ConfirmationURL }}` so the user receives a clean 6-digit code they can type directly into AetherDrop.

### Step 4.4: Run the Complete Master SQL Schema
1. In the left sidebar of Supabase, click the **SQL Editor (Terminal Icon `>_`)**.
2. Click **"+ New query"**.
3. Copy and paste the **entire SQL block below** into the editor and click **"Run"** (or press `Ctrl+Enter`):

```sql
-- ============================================================================
-- AETHERDROP MASTER DATABASE SCHEMA (PROFILES, GAMIFICATION, CONTACTS & REALTIME)
-- ============================================================================

-- 1. Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. Create User Profiles Table (Searchable by Email + Gamification State)
CREATE TABLE public.profiles (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    email TEXT UNIQUE NOT NULL,
    display_name TEXT NOT NULL,
    avatar_id TEXT NOT NULL DEFAULT 'starter_cyber_01',
    frame_id TEXT NOT NULL DEFAULT 'frame_slate_01',
    xp BIGINT NOT NULL DEFAULT 0,
    level INT NOT NULL DEFAULT 1,
    total_bytes_sent BIGINT NOT NULL DEFAULT 0,
    total_files_sent INT NOT NULL DEFAULT 0,
    unlocked_avatars TEXT[] DEFAULT ARRAY['starter_cyber_01', 'starter_cyber_02', 'starter_cyber_03', 'starter_cyber_04'],
    unlocked_badges TEXT[] DEFAULT ARRAY['badge_first_node'],
    is_online BOOLEAN DEFAULT true,
    last_seen TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Create Fast Index for Instant Email & Name Search
CREATE INDEX idx_profiles_email ON public.profiles USING btree (lower(email));
CREATE INDEX idx_profiles_display_name ON public.profiles USING btree (lower(display_name));

-- 4. Create Connections / Recent Peers Table (Tracks Co-Op Warp Streaks)
CREATE TABLE public.peer_connections (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_a UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    user_b UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    streak_count INT DEFAULT 1,
    last_transfer_at TIMESTAMPTZ DEFAULT NOW(),
    total_shared_bytes BIGINT DEFAULT 0,
    UNIQUE(user_a, user_b)
);

-- 5. Create Global Ecosystem Stats Table (Powers the Promo Website Live Counter)
CREATE TABLE public.ecosystem_stats (
    id INT PRIMARY KEY DEFAULT 1,
    total_users BIGINT DEFAULT 1,
    total_transfers BIGINT DEFAULT 0,
    total_gigabytes_warped NUMERIC(12, 2) DEFAULT 0.00
);

INSERT INTO public.ecosystem_stats (id, total_users, total_transfers, total_gigabytes_warped)
VALUES (1, 1, 0, 0.00)
ON CONFLICT (id) DO NOTHING;

-- 6. Enable Row Level Security (RLS)
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.peer_connections ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ecosystem_stats ENABLE ROW LEVEL SECURITY;

-- 7. RLS Policies for Profiles
-- Anyone logged in (or promo site) can search/read profiles by email
CREATE POLICY "Public profiles are viewable by everyone"
ON public.profiles FOR SELECT
USING (true);

-- Users can insert their own profile on first launch
CREATE POLICY "Users can insert their own profile"
ON public.profiles FOR INSERT
WITH CHECK (auth.uid() = id);

-- Users can update their own profile (Name, Avatar, XP, Online status)
CREATE POLICY "Users can update own profile"
ON public.profiles FOR UPDATE
USING (auth.uid() = id);

-- 8. RLS Policies for Peer Connections
CREATE POLICY "Users can view their own peer connections"
ON public.peer_connections FOR SELECT
USING (auth.uid() = user_a OR auth.uid() = user_b);

CREATE POLICY "Users can insert or update peer connections"
ON public.peer_connections FOR ALL
USING (auth.uid() = user_a OR auth.uid() = user_b);

-- 9. RLS Policies for Ecosystem Stats
CREATE POLICY "Anyone can view ecosystem stats"
ON public.ecosystem_stats FOR SELECT
USING (true);

CREATE POLICY "Authenticated users can increment stats"
ON public.ecosystem_stats FOR UPDATE
USING (auth.role() = 'authenticated');

-- 10. Function to Award WXP & Automatically Calculate Level Ups
CREATE OR REPLACE FUNCTION public.record_transfer_and_award_xp(
    p_user_id UUID,
    p_bytes_sent BIGINT,
    p_files_count INT,
    p_is_folder BOOLEAN
) RETURNS JSONB AS $$
DECLARE
    v_xp_gained BIGINT;
    v_new_xp BIGINT;
    v_new_level INT;
    v_new_avatars TEXT[];
BEGIN
    -- Calculate XP: 50 base + 10 per 100MB + 150 bonus for folders
    v_xp_gained := 50 + (p_bytes_sent / 104857600) * 10 + (CASE WHEN p_is_folder THEN 150 ELSE 0 END);

    UPDATE public.profiles
    SET 
        xp = xp + v_xp_gained,
        total_bytes_sent = total_bytes_sent + p_bytes_sent,
        total_files_sent = total_files_sent + p_files_count,
        level = GREATEST(1, FLOOR(SQRT((xp + v_xp_gained) / 25.0))::INT),
        last_seen = NOW()
    WHERE id = p_user_id
    RETURNING xp, level, unlocked_avatars INTO v_new_xp, v_new_level, v_new_avatars;

    -- Auto-unlock Avatars based on new Level
    IF v_new_level >= 5 AND NOT ('cyber_kitsune_05' = ANY(v_new_avatars)) THEN
        UPDATE public.profiles SET unlocked_avatars = array_append(unlocked_avatars, 'cyber_kitsune_05') WHERE id = p_user_id;
    END IF;
    IF v_new_level >= 10 AND NOT ('holo_samurai_10' = ANY(v_new_avatars)) THEN
        UPDATE public.profiles SET unlocked_avatars = array_append(unlocked_avatars, 'holo_samurai_10') WHERE id = p_user_id;
    END IF;
    IF v_new_level >= 25 AND NOT ('astral_phoenix_25' = ANY(v_new_avatars)) THEN
        UPDATE public.profiles SET unlocked_avatars = array_append(unlocked_avatars, 'astral_phoenix_25') WHERE id = p_user_id;
    END IF;
    IF v_new_level >= 50 AND NOT ('apex_singularity_50' = ANY(v_new_avatars)) THEN
        UPDATE public.profiles SET unlocked_avatars = array_append(unlocked_avatars, 'apex_singularity_50') WHERE id = p_user_id;
    END IF;

    -- Update Global Stats for Promo Website
    UPDATE public.ecosystem_stats
    SET 
        total_transfers = total_transfers + 1,
        total_gigabytes_warped = total_gigabytes_warped + ROUND((p_bytes_sent::NUMERIC / 1073741824.0), 4)
    WHERE id = 1;

    RETURN jsonb_build_object('xp_gained', v_xp_gained, 'new_xp', v_new_xp, 'new_level', v_new_level);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 11. Enable Supabase Realtime on Profiles & Peer Connections
ALTER PUBLICATION supabase_realtime ADD TABLE public.profiles;
ALTER PUBLICATION supabase_realtime ADD TABLE public.peer_connections;
ALTER PUBLICATION supabase_realtime ADD TABLE public.ecosystem_stats;
```

---

## 💻 5. Local Machine Prerequisites (Before Launching OpenCode)

Before running the OpenCode prompts, make sure your computer has Flutter ready:
1. **Install Flutter SDK:** Download from [https://docs.flutter.dev/get-started/install](https://docs.flutter.dev/get-started/install) and add `flutter/bin` to your system `PATH`.
2. **Enable Desktop & Mobile Targets:** Open your terminal (PowerShell / Command Prompt) and run:
   ```bash
   flutter config --enable-windows-desktop
   flutter config --enable-macos-desktop
   flutter doctor
   ```
3. **Create Your Master Workspace Folder:**
   ```bash
   mkdir aetherdrop-ecosystem
   cd aetherdrop-ecosystem
   ```
4. **Launch OpenCode:** Inside `aetherdrop-ecosystem`, run `opencode` in your terminal and feed it the **6 Sequential Master Prompts** below one by one.

---

## 🤖 6. Sequential Master Prompts for OpenCode

Copy and paste these prompts into **OpenCode** in exact order. Each prompt is engineered to build production-grade, modular code without placeholders.

---

### 🔹 PROMPT 1: Workspace Setup, Flutter Initialization & Core Dark Glassmorphic Theme
*Copy and paste this into OpenCode first:*

```text
We are building "AetherDrop", a cross-platform, zero-cost Peer-to-Peer (P2P) ultra-fast file, folder, text, and clipboard transfer application for Android, iOS, Windows, and macOS using Flutter, plus a promotional web portal. Never use the word "blip" anywhere in our code, comments, or package names.

Execute the following steps right now in our current directory:
1. Run `flutter create --org com.aetherdrop --platforms=android,ios,windows,macos aetherdrop_app` to scaffold the native Flutter application.
2. Create a folder named `aetherdrop_web` for our promotional download website.
3. Inside `aetherdrop_app/pubspec.yaml`, add and configure these exact production packages:
   - `supabase_flutter: ^2.8.0` (Auth, User Search, Presence, WebRTC Signaling)
   - `flutter_webrtc: ^0.12.0` (Ultra-fast P2P DataChannel streaming)
   - `file_picker: ^8.1.0` (Selecting files and whole folders)
   - `desktop_drop: ^0.5.0` (Drag-and-drop files & folders on Windows/macOS)
   - `super_clipboard: ^0.8.0` (Reading/writing raw images, files, and rich text from Ctrl+V / Cmd+V)
   - `path_provider: ^2.1.4` (Resolving Downloads directory on all 4 OSes)
   - `archive: ^3.6.1` (Zero-loss folder tree streaming & extraction)
   - `shared_preferences: ^2.3.2` (Local session caching)
   - `google_fonts: ^6.2.1` (Space Grotesk & JetBrains Mono typography)
   - `lucide_icons: ^0.257.0` (Crisp minimalist icons)
   - `flutter_animate: ^4.5.0` (60fps micro-animations)
   - `window_manager: ^0.4.2` (Frameless custom glass titlebar on Windows & macOS)
4. Create `aetherdrop_app/lib/core/constants.dart` containing configuration constants for:
   - `supabaseUrl` and `supabaseAnonKey` (with clear variables where I will paste my keys)
   - Free public Google STUN servers (`stun:stun.l.google.com:19302`, `stun:stun1.l.google.com:19302`, `stun:stun.cloudflare.com:3478`)
   - Chunk size constant set to `262144` (256 KB binary chunks for maximum WebRTC DataChannel throughput without buffer overflow).
5. Create `aetherdrop_app/lib/core/theme.dart` implementing our signature Dark Glassmorphism design system:
   - Primary Background: Deep Matte Obsidian (`#0A0A0A`)
   - Glass Surface: Translucent Carbon (`rgba(255, 255, 255, 0.04)`) with `1px solid rgba(255, 255, 255, 0.10)` border and `BackdropFilter` blur (`sigmaX: 18, sigmaY: 18`).
   - Primary Accent: Electric Cyan (`#00F0FF`)
   - Secondary Accent: Hyper Cobalt (`#3B82F6`) and Plasma Violet (`#8B5CF6`)
   - Interactive Light/Dark theme toggle support (`ThemeProvider`) defaulting to Matte Black Dark Mode.
6. Create reusable UI widgets in `lib/ui/widgets/glass_card.dart` and `lib/ui/widgets/avatar_badge.dart` (which renders SVG/custom-painted cyber avatars with animated glowing rank borders based on the user's level).
Run `flutter pub get` and verify there are zero errors.
```

---

### 🔹 PROMPT 2: Frictionless Email Onboarding, User Search & Real-Time Presence
*Once Prompt 1 completes, paste Prompt 2 into OpenCode:*

```text
Now build the Authentication, First-Launch Onboarding, Global Email Search, and Real-Time Presence system inside `aetherdrop_app`.

1. Create `lib/models/user_profile.dart`:
   - Fields: `id`, `email`, `displayName`, `avatarId`, `frameId`, `xp`, `level`, `totalBytesSent`, `totalFilesSent`, `unlockedAvatars`, `unlockedBadges`, `isOnline`, `lastSeen`.
   - Include `fromJson` and `toJson` methods matching our Supabase `public.profiles` table.

2. Create `lib/core/gamification.dart`:
   - Define 12 built-in procedural/vector Cyber Avatars (rendered cleanly via Flutter `CustomPainter` + glowing icons so they require zero external image downloads and look ultra-crisp at any resolution):
     - Starter Tier (Lvl 1): `starter_cyber_01` (Neon Pulse Core), `starter_cyber_02` (Stealth Hex), `starter_cyber_03` (Quantum Prism), `starter_cyber_04` (Orbital Vector).
     - Unlockable Tiers: `cyber_kitsune_05` (Lvl 5), `void_droid_08` (Lvl 8), `holo_samurai_10` (Lvl 10), `plasma_valkyrie_15` (Lvl 15), `chrono_phantom_20` (Lvl 20), `astral_phoenix_25` (Lvl 25), `nova_titan_35` (Lvl 35), `apex_singularity_50` (Lvl 50).
   - Define helper methods: `getRankTitle(int level)`, `getProgressToNextLevel(int xp)`, and `getFrameGradient(int level)`.

3. Create `lib/services/auth_service.dart`:
   - On app startup, check if an active Supabase session exists.
   - Provide `completeFirstTimeOnboarding({required String email, required String displayName, required String avatarId})`:
     - Uses deterministic frictionless authentication with Supabase (`signUp` / `signInWithPassword` using a deterministic client secret derived from the normalized email, with fallback to OTP if enabled) so the user only enters their **Email**, **Display Name**, and selects a **Starter Avatar** once, and is logged in permanently.
     - Upserts the row into `public.profiles` and sets `is_online = true`.

4. Create `lib/ui/screens/onboarding_screen.dart`:
   - A breathtaking, minimalist 1-screen glassmorphic onboarding experience.
   - Step 1: Enter Email Address (with live validation glow).
   - Step 2: Enter Profile Name.
   - Step 3: Interactive carousel to pick 1 of the 4 Starter Cyber Avatars with live preview of how their profile card will look to friends.
   - "Initialize Warp Node" glowing cyan CTA button.

5. Create `lib/services/signaling_service.dart`:
   - Connects to a global Supabase Realtime Presence channel (`online-nodes`) to track which users are currently online in real time.
   - Provides `searchUsersByEmailOrName(String query)` querying `public.profiles` (`ilike` on `email` and `display_name`).
   - Provides `getRecentPeers()` joining `public.peer_connections` with `public.profiles` to show recent people the user has sent files to, along with their Co-Op Warp Streak count (`🔥 X Days`) and live green online indicator.
   - Listens on a user-specific Supabase Realtime Broadcast channel (`signal:USER_ID`) for incoming WebRTC offers, answers, ICE candidates, and instant transfer invitations.
```

---

### 🔹 PROMPT 3: The Ultra-Fast WebRTC P2P Engine (Files, Folders, Images & `Ctrl+V` Paste)
*Once Prompt 2 completes, paste Prompt 3 into OpenCode:*

```text
Now build the core Ultra-Fast P2P Transfer Engine in `aetherdrop_app` using `flutter_webrtc`. It must support sending single files, multiple files, entire nested folders, images, and instant `Ctrl+V` / `Cmd+V` clipboard text/screenshots directly peer-to-peer with zero cloud storage.

1. Create `lib/models/transfer_manifest.dart`:
   - Represents a transfer payload header sent as JSON over the WebRTC DataChannel before binary chunks begin.
   - Supports 4 payload types: `single_file`, `multi_file`, `folder_archive`, and `instant_clipboard` (text or PNG image bytes).
   - Includes `transferId`, `senderId`, `senderName`, `senderAvatar`, `totalBytes`, `totalItems`, and list of file entries with relative paths (so nested folders reconstruct their exact subfolder structure on the receiver's device).

2. Create `lib/services/webrtc_engine.dart`:
   - Manages `RTCPeerConnection` configured with Google's free STUN servers and optional TURN config.
   - Creates an ordered, high-throughput `RTCDataChannel` (`aetherdrop-warp-pipe`).
   - **High-Speed Backpressure Control:** Implement buffered amount monitoring (`dataChannel.bufferedAmountLowThreshold = 1048576` / 1 MB). Read files from disk using Dart `Stream<List<int>>` in `256 KB` chunks so even a 50 GB video file uses less than 15 MB of RAM and never crashes mobile or desktop devices!
   - **Folder Streaming:** When a user selects or drops a directory, recursively scan its relative file paths, stream each file sequentially with a lightweight binary frame header (`[fileIndex, chunkLength]`), and automatically recreate the exact directory tree inside the receiver's `Downloads/AetherDrop/` folder.
   - **Live Metrics Calculation:** Compute real-time transfer speed in `MB/s`, percentage completed (`0.0` to `1.0`), estimated time remaining (`ETA`), and emit updates via a `StreamController` at 60fps for the UI.
   - **Automatic WXP Reward:** When a transfer finishes (`100%`), call `supabase.rpc('record_transfer_and_award_xp', ...)` and update `public.peer_connections` to increment the Co-Op Streak between Sender and Receiver!

3. Create `lib/services/clipboard_service.dart`:
   - Listens for `Ctrl+V` (Windows/Android) and `Cmd+V` (macOS/iOS) keyboard shortcuts or a "Paste & Beam" button.
   - Uses `super_clipboard` to detect if the clipboard contains:
     - **Copied Image / Screenshot:** Reads the PNG binary buffer and beams it immediately to the selected peer with an inline image preview!
     - **Copied Text / Code / URL:** Beams it immediately so it pops up on the receiver's screen with a 1-click "Copy to Clipboard" or "Open URL" action.
     - **Copied File Paths:** Reads the file paths from the OS clipboard and triggers the file streamer.
```

---

### 🔹 PROMPT 4: The Main Radar UI, Particle Warp Tunnel & Gamified Avatar Vault
*Once Prompt 3 completes, paste Prompt 4 into OpenCode:*

```text
Now build the complete interactive user interface for `aetherdrop_app` and wire all services together in `lib/main.dart`.

1. Create `lib/ui/screens/home_radar_screen.dart`:
   - **Top Header Bar:** Displays the logged-in user's Avatar with glowing rank ring, Display Name, Email, current Level badge (`LVL X — Spark Node`), animated WXP progress bar, a button to open the **Avatar & Rank Vault**, and a sleek Dark/Light Glass theme toggle.
   - **Global Instant Search Bar:** "Search anyone globally by email or name..." As the user types an email (e.g., `person2@gmail.com`), it queries Supabase in real time and shows matching users with their Avatar, Level, and Online status (`⚡ Online Ready` or `Offline`).
   - **Interactive Peer Grid / Radar View:** Shows recent friends and search results as floating glassmorphic cards with their Co-Op Streak flame (`🔥`).
   - **4 Ways to Send to Any Person Card:**
     1. **Drag & Drop** any files or folders directly onto a person's card (`DropTarget` via `desktop_drop`).
     2. Click **"Send Files"** or **"Send Folder"** on their card.
     3. Press **`Ctrl+V` / `Cmd+V`** (or tap **"Beam Clipboard"**) while a person is selected to instantly beam text or screenshots.
     4. Tap **"Quick Note / Code"** to type and beam formatted text/code snippets instantly.

2. Create `lib/ui/screens/transfer_warp_modal.dart`:
   - **Incoming Request Popup:** When Person 1 initiates a transfer to Person 2, Person 2 sees an animated Neon Cyan glass modal: *"Vansh (Lvl 12) wants to beam `Project_Folder` (1.42 GB) — [Accept Warp] [Decline]"* (with an optional toggle: *"Auto-accept from trusted streak friends"*).
   - **The Live Particle Warp Tunnel:** While transferring, render a custom 60fps `CustomPainter` particle stream where glowing cyan and violet energy packets accelerate from Sender's Avatar to Receiver's Avatar.
   - Displays a massive, futuristic digital speedometer (`68.4 MB/s`), progress percentage, file count, and interactive quick-reaction buttons (`⚡`, `🚀`, `🔥`, `💎`) that float across both users' screens in real time over the WebRTC channel!
   - When finished, triggers a celebratory **"+WXP Gained!"** level-up banner and button to **"Open in Folder"**.

3. Create `lib/ui/screens/vault_avatars_screen.dart`:
   - A dedicated gamification hub showing:
     - All 12 Cyber Avatars (unlocked ones can be equipped with 1 click; locked ones show a translucent lock overlay and exact Level requirement, e.g., *"Unlocks at Level 10"*).
     - Lifetime stats: Total Gigabytes Warped, Total Files Sent, Highest Speed Achieved, Longest Co-Op Streak.
     - Milestone Badges (*First Warp*, *Folder Architect*, *Gigabyte Gladiator*, *Light Speed LAN*).

4. Wire `lib/main.dart` so all 4 platforms (Android, iOS, Windows, macOS) boot smoothly, initialize Supabase, check onboarding state, and render the complete app. Verify with `flutter analyze` and fix any warnings.
```

---

### 🔹 PROMPT 5: The Minimalist Dark Glassmorphic Promotional & Direct-Download Website
*Once Prompt 4 completes, paste Prompt 5 into OpenCode:*

```text
Now build the promotional and direct-download website inside `aetherdrop_web/` (`index.html`, `styles.css`, `app.js`, `vercel.json`). It must be ultra-minimalist, feature high-craft Dark Glassmorphism (`#0A0A0A` matte black, `#00F0FF` electric cyan accents, `#FFFFFF` crisp typography, plus an interactive Light/Dark mode switch), silky 60fps scroll/hover animations, and 100% responsiveness across phones, tablets, and laptops.

Include these exact features in `aetherdrop_web/`:
1. **Smart OS Auto-Detection & 4 Direct Native Download Buttons:**
   - Include a prominent **Universal Download Dock** in the Hero section and Sticky Navbar featuring 4 dedicated platform cards/buttons:
     - 🍎 **Download for macOS** (`.dmg` — Universal Apple Silicon & Intel)
     - 🪟 **Download for Windows** (`.exe` — Native 64-bit Installer)
     - 🤖 **Download for Android** (`.apk` — Direct Native Package)
     - 📱 **Download for iPhone / iOS** (`.ipa` — Native iOS Build + Sideload/TestFlight Guide Modal)
   - Automatically detect the visitor's current device via `navigator.userAgent` and add a glowing `"Recommended for your device"` badge to their matching OS button, while allowing them to click ANY of the 4 buttons at any time.
   - Configure a central `DOWNLOAD_CONFIG` object in `app.js` that maps each button directly to our GitHub Releases binary URLs:
     - `mac`: `https://github.com/YOUR_GITHUB_USERNAME/aetherdrop/releases/latest/download/AetherDrop-macOS.dmg`
     - `windows`: `https://github.com/YOUR_GITHUB_USERNAME/aetherdrop/releases/latest/download/AetherDrop-Windows-Setup.exe`
     - `android`: `https://github.com/YOUR_GITHUB_USERNAME/aetherdrop/releases/latest/download/AetherDrop-Android.apk`
     - `ios`: `https://github.com/YOUR_GITHUB_USERNAME/aetherdrop/releases/latest/download/AetherDrop-iOS.ipa`
   - When a user clicks any download button, trigger an immediate file download AND display a sleek glassmorphic toast notification showing the file name (`AetherDrop-Windows-Setup.exe`), SHA-256 verification badge, and a 1-step installation tip!

2. **Interactive Live Web Preview & Supabase Live Ecosystem Counter:**
   - Connect `app.js` to our Supabase `public.ecosystem_stats` table (using the public `anon` key) so the website displays real-time counters of **Total Nodes Online**, **Total Transfers Completed**, and **Total Gigabytes Warped Globally**.
   - Include an **Interactive Browser Sandbox Widget** right on the landing page where visitors can test dragging a file, pasting clipboard text (`Ctrl+V`), and previewing the **12 Unlockable Cyber Avatars & Level Progression Tree** directly in their browser before downloading!

3. **Architectural Sections:**
   - **Hero Section:** Animated P2P particle beam connecting a MacBook, Windows PC, iPhone, and Android phone + the 4 OS Download Buttons.
   - **How It Works (Zero Cloud Storage):** Visual comparison showing why AetherDrop is 100% free with unlimited file sizes vs. legacy cloud upload tools.
   - **Interactive Avatar & Rank Showcase:** Interactive slider where visitors can scrub from **Level 1 (Spark Node)** to **Level 50 (Singularity Core)** to see the avatars and glowing borders they will unlock as they transfer more files.
   - **Responsive Breakpoints:** Flawless mobile touch navigation, tablet bento grids, and wide desktop glass layouts.
```

---

### 🔹 PROMPT 6: Automated Cloud Builder (`.exe`, `.dmg`, `.apk`, `.ipa`) via GitHub Actions
*Once Prompt 5 completes, paste Prompt 6 into OpenCode:*

```text
Now create a complete GitHub Actions CI/CD workflow at `.github/workflows/build_all_platforms.yml` in the root of our repository so that whenever we push a release tag (e.g., `v1.0.0`) or trigger the workflow manually from GitHub, GitHub's free cloud servers automatically compile all 4 native installers—even if I am working on a Windows laptop without a Mac!

Configure `.github/workflows/build_all_platforms.yml` with 4 parallel jobs:
1. `build-android` (runs on `ubuntu-latest`):
   - Sets up Java 17 and Flutter stable.
   - Runs `flutter build apk --release`.
   - Renames output to `AetherDrop-Android.apk`.
2. `build-windows` (runs on `windows-latest`):
   - Sets up Flutter stable on Windows.
   - Runs `flutter build windows --release`.
   - Packages the release folder into a standalone executable/installer `AetherDrop-Windows-Setup.exe` (using Inno Setup pre-installed on GitHub Windows runners so it produces a single clean `.exe` installer!).
3. `build-macos` (runs on `macos-latest`):
   - Sets up Flutter stable on macOS.
   - Runs `flutter build macos --release`.
   - Packages `AetherDrop.app` into a native Apple disk image `AetherDrop-macOS.dmg` using `hdiutil`.
4. `build-ios` (runs on `macos-latest`):
   - Runs `flutter build ios --release --no-codesign`.
   - Packages the resulting `Runner.app` inside a `Payload/` directory and zips it into a valid `AetherDrop-iOS.ipa` file.
5. `publish-release`:
   - Collects `AetherDrop-Android.apk`, `AetherDrop-Windows-Setup.exe`, `AetherDrop-macOS.dmg`, and `AetherDrop-iOS.ipa` and automatically attaches all 4 files to the **Latest GitHub Release** so the download buttons on our promotional website (`aetherdrop_web`) work automatically with direct 1-click downloads!
```

---

## 🔗 7. Connecting Everything Together (Step-by-Step Integration Guide)

Once OpenCode finishes running the 6 prompts above, follow these exact steps to connect your Supabase backend, compile your apps, and put your promotional website live on the internet for $0.

### Step 7.1: Plug Your Supabase Keys into the App & Website
1. Open `aetherdrop_app/lib/core/constants.dart` in VS Code.
2. Replace `YOUR_SUPABASE_URL` and `YOUR_SUPABASE_ANON_KEY` with the exact **Project URL** and **`anon` `public` key** you copied from **Step 4.2**:
   ```dart
   class AppConstants {
     static const String supabaseUrl = 'https://xyzcompany.supabase.co';
     static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';
   }
   ```
3. Open `aetherdrop_web/app.js` and paste the exact same `supabaseUrl` and `supabaseAnonKey` at the top so the website's live global transfer counter syncs in real time with your app!

### Step 7.2: Test the Native App Locally on Your Windows PC & Android Phone
1. **Run on Windows Desktop Immediately:**
   ```bash
   cd aetherdrop_app
   flutter run -d windows
   ```
   - Enter your email (`person1@gmail.com`), pick a name and starter avatar, and you are inside the Radar screen!
2. **Run on Your Android Phone (USB or Wi-Fi Debugging):**
   - Plug in your Android phone (or run a second instance on your PC/emulator) and run:
   ```bash
   flutter run -d android
   ```
   - Log in with a second email (`person2@gmail.com`).
3. **Test Your First Warp Transfer:**
   - On Windows (`person1`), type `person2@gmail.com` in the search bar.
   - You will see Person 2 appear with a glowing **⚡ Online** indicator!
   - Drag any file, folder, or press **`Ctrl+V`** on Person 2's card. Watch the **Particle Warp Tunnel** animate at 60fps, complete the transfer at blazing local Wi-Fi speed, and award **+WXP** to your profile!

### Step 7.3: Generate `.exe`, `.dmg`, `.apk`, and `.ipa` Automatically for Free
How do you get a real macOS `.dmg` and iPhone `.ipa` when you are working on a Windows computer? **GitHub Actions does it for you on Apple's cloud servers for free!**
1. Create a free **public** repository on [https://github.com/new](https://github.com/new) named `aetherdrop`.
2. Push your `aetherdrop-ecosystem` folder to GitHub:
   ```bash
   git init
   git add .
   git commit -m "Initial launch of AetherDrop P2P Ecosystem"
   git branch -M main
   git remote add origin https://github.com/YOUR_GITHUB_USERNAME/aetherdrop.git
   git push -u origin main
   ```
3. Trigger the automated 4-platform cloud build by pushing a version tag:
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```
4. Go to your GitHub repository -> click the **"Actions"** tab. You will see GitHub building **Android (`.apk`)**, **Windows (`.exe`)**, **macOS (`.dmg`)**, and **iOS (`.ipa`)** simultaneously!
5. In ~6 minutes, click the **"Releases"** section on the right side of your GitHub repo. All 4 native installers will be published and ready for direct download:
   - `https://github.com/YOUR_GITHUB_USERNAME/aetherdrop/releases/latest/download/AetherDrop-Windows-Setup.exe`
   - `https://github.com/YOUR_GITHUB_USERNAME/aetherdrop/releases/latest/download/AetherDrop-macOS.dmg`
   - `https://github.com/YOUR_GITHUB_USERNAME/aetherdrop/releases/latest/download/AetherDrop-Android.apk`
   - `https://github.com/YOUR_GITHUB_USERNAME/aetherdrop/releases/latest/download/AetherDrop-iOS.ipa`

### Step 7.4: Deploy the Promotional Website (`aetherdrop_web`) for Free on Vercel
1. Open `aetherdrop_web/app.js` and ensure `YOUR_GITHUB_USERNAME` in `DOWNLOAD_CONFIG` matches your actual GitHub username.
2. Commit and push the change:
   ```bash
   git add aetherdrop_web/app.js
   git commit -m "Link direct installer download buttons to GitHub Releases"
   git push
   ```
3. Go to **[https://vercel.com](https://vercel.com)** and log in with GitHub.
4. Click **"Add New..."** -> **"Project"** -> Import your `aetherdrop` repository.
5. Set the **Root Directory** to `aetherdrop_web`.
6. Click **"Deploy"**.
7. In 15 seconds, your promotional website is live (e.g., `https://aetherdrop.vercel.app`)! When anyone visits on a Mac, Windows PC, iPhone, or Android device and clicks the download button for their OS, their browser immediately downloads the exact `.dmg`, `.exe`, `.apk`, or `.ipa` installer file!

---

## 🚀 8. Bonus Differentiation Ideas (To Make Your App Unforgettable)

Once your core app is running, you can ask OpenCode to add any of these 4 interactive features to push AetherDrop even further ahead:

1. **🎵 Audio/Visual "Sonic Handshake" (Ultrasonic / QR Pairing):**
   - If two people are sitting in the same classroom or room and don't even want to type an email, Person 1 clicks **"Emit Pulse"** (shows a glowing cyber QR code or ultrasonic audio tone) and Person 2 scans/listens to instantly link their accounts forever and gain **+500 Friendship WXP**.
2. **🖼️ Live Collaborative "Scratchpad Canvas" Inside Every Connection:**
   - Next to the file transfer button on a friend's card, add a **"Shared Cyber-Board"** tab where both users can paste multiple screenshots, hex color codes, and links onto an infinite dark glass canvas that stays synced while both are online.
3. **⚡ LAN Turbo Boost Indicator:**
   - When the WebRTC engine detects that both Person 1 and Person 2 share a local subnet candidate (`192.168.x.x`), trigger a special **"⚡ LOCAL WIFI HYPER-SPEED ACTIVE (0 DATA USED)"** neon badge in the UI so users see why their 2 GB movie just finished transferring in 12 seconds!
4. **🏆 Weekly Global & School/Team Leaderboards:**
   - Add a **"Top Nodes"** tab in the app querying `SELECT display_name, avatar_id, level, xp FROM public.profiles ORDER BY xp DESC LIMIT 20` so users can compete to reach **Level 50 (Singularity Core)** first and show off their rare animated avatars!
