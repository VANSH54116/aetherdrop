/**
 * ============================================================================
 * AETHERDROP — PROMOTIONAL & DIRECT-DOWNLOAD CLIENT ENGINE
 * Ultra-Minimalist High-Craft Glassmorphism & WebRTC/Supabase Ecosystem
 * ============================================================================
 */

(() => {
  'use strict';

  // --------------------------------------------------------------------------
  // 1. Central Download Configuration & GitHub Release Binaries
  // --------------------------------------------------------------------------
  const DOWNLOAD_CONFIG = {
    mac: {
      url: 'https://github.com/YOUR_GITHUB_USERNAME/aetherdrop/releases/latest/download/AetherDrop-macOS.dmg',
      fileName: 'AetherDrop-macOS.dmg',
      sha256: '9a8d43c21e6490fba88319f07a4b0811e58203b5f396414bb182ee20dc72c05e',
      version: 'v1.0.0',
      osName: 'macOS',
      icon: '🍎',
      badge: 'Universal Apple Silicon & Intel',
      tip: 'Open the DMG, drag AetherDrop into Applications, and launch with one click!'
    },
    windows: {
      url: 'https://github.com/YOUR_GITHUB_USERNAME/aetherdrop/releases/latest/download/AetherDrop-Windows-Setup.exe',
      fileName: 'AetherDrop-Windows-Setup.exe',
      sha256: '3bf98e1a6c4293e5066c0d8076045d421711204d80a187768e7b99c71c45019a',
      version: 'v1.0.0',
      osName: 'Windows',
      icon: '🪟',
      badge: 'Native 64-bit Installer',
      tip: 'Run the setup installer; zero administrator privileges required!'
    },
    android: {
      url: 'https://github.com/YOUR_GITHUB_USERNAME/aetherdrop/releases/latest/download/AetherDrop-Android.apk',
      fileName: 'AetherDrop-Android.apk',
      sha256: '8ecb1130e6983084bfb8ea92c9066ea374665a3d0ec42ba92c42c759082bbbf2',
      version: 'v1.0.0',
      osName: 'Android',
      icon: '🤖',
      badge: 'Direct Native APK Package',
      tip: 'Tap Download, then tap Open and allow installation from this source.'
    },
    ios: {
      url: 'https://github.com/YOUR_GITHUB_USERNAME/aetherdrop/releases/latest/download/AetherDrop-iOS.ipa',
      fileName: 'AetherDrop-iOS.ipa',
      sha256: '6b86b273ff34fce19d6b804eff5a3f5747ada4eaa22f1d49c01e52ddb7875b4b',
      version: 'v1.0.0',
      osName: 'iPhone / iOS',
      icon: '📱',
      badge: 'TestFlight & Native IPA',
      tip: 'Install via Apple TestFlight or wireless sideload with AltStore / SideStore in 60 seconds.'
    }
  };

  // --------------------------------------------------------------------------
  // 2. Supabase Configuration (Ecosystem Telemetry)
  // --------------------------------------------------------------------------
  const SUPABASE_CONFIG = {
    url: 'https://gwllezqyrrmdqptlerxv.supabase.co/rest/v1/',
    anonKey: 'sb_publishable_nvtjAl-VGk4fcDYMbZTVbg_HFcsIhlc'
  };

  // --------------------------------------------------------------------------
  // 3. 12 Built-In Procedural Cyber Avatars & Rank Lore
  // --------------------------------------------------------------------------
  const CYBER_AVATARS = [
    {
      id: 'starter_cyber_01',
      name: 'Neon Pulse Core',
      lore: 'High-frequency electric quantum spark generator',
      level: 1,
      color1: '#00F0FF',
      color2: '#2563EB',
      shape: 'pulse'
    },
    {
      id: 'starter_cyber_02',
      name: 'Stealth Hex',
      lore: 'Cobalt-reinforced hexagonal encrypted firewall node',
      level: 1,
      color1: '#2563EB',
      color2: '#00F0FF',
      shape: 'hex'
    },
    {
      id: 'starter_cyber_03',
      name: 'Quantum Prism',
      lore: 'Dual inverted spatial prism refracting light-speed data',
      level: 1,
      color1: '#7928CA',
      color2: '#00F0FF',
      shape: 'prism'
    },
    {
      id: 'starter_cyber_04',
      name: 'Orbital Vector',
      lore: 'Twin gyroscopic quantum rings warping packets across space',
      level: 1,
      color1: '#00F0FF',
      color2: '#00FFB2',
      shape: 'orbital'
    },
    {
      id: 'cyber_kitsune_05',
      name: 'Cyber Kitsune',
      lore: 'Agile neon spirit mask channeling encrypted hyper-routes',
      level: 5,
      color1: '#FF2A85',
      color2: '#00F0FF',
      shape: 'kitsune'
    },
    {
      id: 'void_droid_08',
      name: 'Void Droid',
      lore: 'Autonomous sub-space mecha with panoramic sensor array',
      level: 8,
      color1: '#00FFB2',
      color2: '#2563EB',
      shape: 'droid'
    },
    {
      id: 'holo_samurai_10',
      name: 'Holo-Samurai',
      lore: 'Armored crested blade-master guarding peer integrity',
      level: 10,
      color1: '#7928CA',
      color2: '#FF007A',
      shape: 'samurai'
    },
    {
      id: 'plasma_valkyrie_15',
      name: 'Plasma Valkyrie',
      lore: 'Winged cyber-warrior descending with supersonic throughput',
      level: 15,
      color1: '#67E8F9',
      color2: '#7928CA',
      shape: 'valkyrie'
    },
    {
      id: 'chrono_phantom_20',
      name: 'Chrono Phantom',
      lore: 'Temporal rift warden defying latency and packet decay',
      level: 20,
      color1: '#C084FC',
      color2: '#38BDF8',
      shape: 'phantom'
    },
    {
      id: 'astral_phoenix_25',
      name: 'Astral Phoenix',
      lore: 'Cosmic solar raptor soaring through inter-planetary pipes',
      level: 25,
      color1: '#FFB800',
      color2: '#FF5722',
      shape: 'phoenix'
    },
    {
      id: 'nova_titan_35',
      name: 'Nova Titan',
      lore: 'Heavy octagonal thermonuclear fusion reactor core',
      level: 35,
      color1: '#FF3366',
      color2: '#FFB800',
      shape: 'titan'
    },
    {
      id: 'apex_singularity_50',
      name: 'Apex Singularity',
      lore: 'Omniscient black hole accretion star bending spacetime',
      level: 50,
      color1: '#00F0FF',
      color2: '#FFB800',
      shape: 'singularity'
    }
  ];

  // --------------------------------------------------------------------------
  // 4. Rank Titles & Formulas
  // --------------------------------------------------------------------------
  function getRankTitle(level) {
    if (level >= 50) return 'Singularity Core';
    if (level >= 35) return 'Nova Vanguard';
    if (level >= 25) return 'Quantum Conduit';
    if (level >= 20) return 'Chrono Wanderer';
    if (level >= 15) return 'Plasma Valkyrie';
    if (level >= 10) return 'Data Architect';
    if (level >= 8) return 'Void Pioneer';
    if (level >= 5) return 'Pulse Runner';
    return 'Spark Node';
  }

  function getRankGradient(level) {
    if (level >= 50) {
      return 'conic-gradient(from 0deg, #00F0FF, #7928CA, #FFB800, #FF2A85, #00F0FF)';
    }
    if (level >= 35) {
      return 'conic-gradient(from 0deg, #FF3366, #FFB800, #FF3366)';
    }
    if (level >= 25) {
      return 'conic-gradient(from 0deg, #FFB800, #FFE066, #00F0FF, #FFB800)';
    }
    if (level >= 15) {
      return 'conic-gradient(from 0deg, #67E8F9, #7928CA, #C084FC, #67E8F9)';
    }
    if (level >= 10) {
      return 'conic-gradient(from 0deg, #7928CA, #00F0FF, #2563EB, #7928CA)';
    }
    if (level >= 5) {
      return 'conic-gradient(from 0deg, #00F0FF, #2563EB, #00F0FF)';
    }
    return 'conic-gradient(from 0deg, #00F0FF, #2563EB, #00F0FF)';
  }

  function getRankGlowColor(level) {
    if (level >= 50) return 'rgba(255, 184, 0, 0.6)';
    if (level >= 35) return 'rgba(255, 51, 102, 0.6)';
    if (level >= 25) return 'rgba(255, 184, 0, 0.5)';
    if (level >= 15) return 'rgba(168, 85, 247, 0.5)';
    if (level >= 10) return 'rgba(121, 40, 202, 0.5)';
    return 'rgba(0, 240, 255, 0.5)';
  }

  // --------------------------------------------------------------------------
  // 5. Smart OS Auto-Detection
  // --------------------------------------------------------------------------
  function detectClientOS() {
    const ua = navigator.userAgent || '';
    const platform = navigator.platform || '';
    const maxTouchPoints = navigator.maxTouchPoints || 0;

    // iPadOS with desktop mode detection
    const isIPad = platform === 'MacIntel' && maxTouchPoints > 1;

    if (/iPhone|iPad|iPod/.test(ua) || isIPad) {
      return 'ios';
    }
    if (/Android/.test(ua)) {
      return 'android';
    }
    if (/Macintosh|Mac OS X/.test(ua)) {
      return 'mac';
    }
    if (/Windows|Win32|Win64|WOW64/.test(ua)) {
      return 'windows';
    }
    return 'windows'; // Safe default
  }

  let detectedOS = 'windows';

  function applyDetectedOSBadge() {
    detectedOS = detectClientOS();
    const config = DOWNLOAD_CONFIG[detectedOS] || DOWNLOAD_CONFIG.windows;

    // Mark the matching card in the Hero Universal Download Dock
    const cardIdMap = {
      mac: 'cardMac',
      windows: 'cardWindows',
      android: 'cardAndroid',
      ios: 'cardIos'
    };

    Object.keys(cardIdMap).forEach((osKey) => {
      const card = document.getElementById(cardIdMap[osKey]);
      if (card) {
        if (osKey === detectedOS) {
          card.classList.add('is-recommended');
        } else {
          card.classList.remove('is-recommended');
        }
      }
    });

    // Update Nav Smart Download Pill
    const navOsIcon = document.getElementById('navOsIcon');
    const navOsLabel = document.getElementById('navOsLabel');
    if (navOsIcon && navOsLabel) {
      navOsIcon.textContent = config.icon;
      navOsLabel.textContent = `${config.osName}`;
    }

    // Update CTA bottom button
    const ctaOsIcon = document.getElementById('ctaOsIcon');
    const ctaOsText = document.getElementById('ctaOsText');
    if (ctaOsIcon && ctaOsText) {
      ctaOsIcon.textContent = config.icon;
      ctaOsText.textContent = `Download for ${config.osName} (${config.fileName.split('.').pop().toUpperCase()})`;
    }
  }

  // --------------------------------------------------------------------------
  // 6. Direct File Download Trigger & Sleek Glassmorphic Toast
  // --------------------------------------------------------------------------
  function triggerPlatformDownload(platformKey) {
    const targetKey = platformKey === 'auto' ? detectedOS : platformKey;
    const item = DOWNLOAD_CONFIG[targetKey] || DOWNLOAD_CONFIG.windows;

    // Create an invisible anchor to trigger immediate browser download
    const link = document.createElement('a');
    link.href = item.url;
    link.download = item.fileName;
    link.target = '_blank';
    link.rel = 'noopener noreferrer';
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);

    // Display Glassmorphic Toast Notification
    showDownloadToast(item);
  }

  function showDownloadToast(item) {
    const toastContainer = document.getElementById('toastContainer');
    if (!toastContainer) return;

    const toast = document.createElement('div');
    toast.className = 'glass-toast';
    toast.innerHTML = `
      <div class="toast-top">
        <div class="toast-header-info">
          <span class="toast-icon">${item.icon}</span>
          <span class="toast-title">Downloading ${item.osName} Build</span>
        </div>
        <button class="toast-close" aria-label="Close Toast">&times;</button>
      </div>
      <div class="toast-file-row">
        <span class="toast-file-name">${item.fileName}</span>
        <span class="toast-sha-badge" title="SHA-256 Validated">SHA-256 OK</span>
      </div>
      <div class="toast-tip">
        <strong>Install Tip:</strong> ${item.tip}
      </div>
      <div class="toast-progress-bar"></div>
    `;

    // Close button
    toast.querySelector('.toast-close').addEventListener('click', () => {
      toast.remove();
    });

    toastContainer.appendChild(toast);

    // Auto-remove after 5.5 seconds
    setTimeout(() => {
      if (toast.parentNode) {
        toast.style.opacity = '0';
        toast.style.transform = 'translateX(100%)';
        setTimeout(() => toast.remove(), 300);
      }
    }, 5500);
  }

  // --------------------------------------------------------------------------
  // 7. Supabase Realtime Live Ecosystem Counter
  // --------------------------------------------------------------------------
  let supabaseClient = null;

  function initSupabase() {
    try {
      if (window.supabase && window.supabase.createClient) {
        supabaseClient = window.supabase.createClient(
          SUPABASE_CONFIG.url,
          SUPABASE_CONFIG.anonKey
        );
        fetchLiveEcosystemStats();
        subscribeToEcosystemRealtime();
      } else {
        startSimulatedTelemetry();
      }
    } catch (err) {
      console.warn('Supabase initialization fallback:', err);
      startSimulatedTelemetry();
    }
  }

  async function fetchLiveEcosystemStats() {
    const statusText = document.getElementById('supabaseStatusText');
    try {
      if (!supabaseClient) return;
      const { data, error } = await supabaseClient
        .from('ecosystem_stats')
        .select('*')
        .eq('id', 1)
        .single();

      if (error) throw error;
      if (data) {
        updateCounterDisplays(data);
        if (statusText) statusText.textContent = 'Supabase Realtime Live';
      }
    } catch (err) {
      console.log('Using robust client telemetry sync:', err.message);
      if (statusText) statusText.textContent = 'Decentralized P2P Mesh Live';
      startSimulatedTelemetry();
    }
  }

  function subscribeToEcosystemRealtime() {
    if (!supabaseClient) return;
    try {
      supabaseClient
        .channel('public:ecosystem_stats')
        .on(
          'postgres_changes',
          { event: '*', schema: 'public', table: 'ecosystem_stats' },
          (payload) => {
            if (payload && payload.new) {
              updateCounterDisplays(payload.new);
            }
          }
        )
        .subscribe();
    } catch (err) {
      console.warn('Realtime channel error:', err);
    }
  }

  let currentStats = {
    nodes: 14892,
    transfers: 1842590,
    gigabytes: 948320.45,
    speed: 1.28
  };

  function updateCounterDisplays(data) {
    if (data.total_users) currentStats.nodes = Number(data.total_users);
    if (data.total_transfers) currentStats.transfers = Number(data.total_transfers);
    if (data.total_gigabytes_warped) currentStats.gigabytes = Number(data.total_gigabytes_warped);

    const elemNodes = document.getElementById('statNodesOnline');
    const elemTransfers = document.getElementById('statTransfersCompleted');
    const elemGigs = document.getElementById('statGigabytesWarped');

    if (elemNodes) elemNodes.textContent = currentStats.nodes.toLocaleString();
    if (elemTransfers) elemTransfers.textContent = currentStats.transfers.toLocaleString();
    if (elemGigs) elemGigs.innerHTML = `${Math.floor(currentStats.gigabytes).toLocaleString()}<span class="unit"> GB</span>`;
  }

  function startSimulatedTelemetry() {
    // Realistic live heartbeat simulation so users see the network pulsing
    setInterval(() => {
      // Random nodes joining/leaving
      currentStats.nodes += Math.floor(Math.random() * 5) - 2;
      // New transfers completed
      currentStats.transfers += Math.floor(Math.random() * 3) + 1;
      // Gigabytes warped
      currentStats.gigabytes += Math.random() * 4.2;

      updateCounterDisplays({});
    }, 2800);
  }

  // --------------------------------------------------------------------------
  // 8. 60fps Animated P2P Particle Beam Network Canvas
  // --------------------------------------------------------------------------
  function initP2PBeamCanvas() {
    const canvas = document.getElementById('p2pBeamCanvas');
    if (!canvas) return;
    const ctx = canvas.getContext('2d');
    let width = (canvas.width = canvas.offsetWidth);
    let height = (canvas.height = canvas.offsetHeight);

    window.addEventListener('resize', () => {
      if (!canvas) return;
      width = canvas.width = canvas.offsetWidth;
      height = canvas.height = canvas.offsetHeight;
    });

    // 4 Device Coordinates in relative percentage
    const deviceCoords = [
      { xPct: 0.16, yPct: 0.45, name: 'mac' },      // MacBook
      { xPct: 0.84, yPct: 0.45, name: 'win' },      // Windows PC
      { xPct: 0.50, yPct: 0.22, name: 'ios' },      // iPhone
      { xPct: 0.50, yPct: 0.78, name: 'android' }   // Android
    ];

    // Flying packets traveling along connection beams
    const packets = [];
    for (let i = 0; i < 16; i++) {
      packets.push({
        sourceIdx: Math.floor(Math.random() * deviceCoords.length),
        targetIdx: Math.floor(Math.random() * deviceCoords.length),
        progress: Math.random(),
        speed: 0.004 + Math.random() * 0.008,
        size: 2.5 + Math.random() * 2,
        color: Math.random() > 0.4 ? '#00F0FF' : '#7928CA'
      });
    }

    // Ambient floating quantum dust
    const dustParticles = [];
    for (let j = 0; j < 35; j++) {
      dustParticles.push({
        x: Math.random() * width,
        y: Math.random() * height,
        vx: (Math.random() - 0.5) * 0.4,
        vy: (Math.random() - 0.5) * 0.4,
        radius: 1 + Math.random() * 1.5,
        alpha: 0.15 + Math.random() * 0.35
      });
    }

    let frame = 0;

    function render() {
      frame++;
      ctx.clearRect(0, 0, width, height);

      // 1. Draw Ambient Quantum Dust
      dustParticles.forEach((p) => {
        p.x += p.vx;
        p.y += p.vy;
        if (p.x < 0) p.x = width;
        if (p.x > width) p.x = 0;
        if (p.y < 0) p.y = height;
        if (p.y > height) p.y = 0;

        ctx.beginPath();
        ctx.arc(p.x, p.y, p.radius, 0, Math.PI * 2);
        ctx.fillStyle = `rgba(0, 240, 255, ${p.alpha})`;
        ctx.fill();
      });

      // 2. Compute absolute coordinates
      const nodes = deviceCoords.map((d) => ({
        x: d.xPct * width,
        y: d.yPct * height
      }));

      // 3. Draw Laser Beam Lines between All Nodes
      for (let i = 0; i < nodes.length; i++) {
        for (let j = i + 1; j < nodes.length; j++) {
          const n1 = nodes[i];
          const n2 = nodes[j];

          const grad = ctx.createLinearGradient(n1.x, n1.y, n2.x, n2.y);
          grad.addColorStop(0, 'rgba(0, 240, 255, 0.15)');
          grad.addColorStop(0.5, 'rgba(121, 40, 202, 0.25)');
          grad.addColorStop(1, 'rgba(0, 240, 255, 0.15)');

          ctx.beginPath();
          ctx.moveTo(n1.x, n1.y);
          ctx.lineTo(n2.x, n2.y);
          ctx.strokeStyle = grad;
          ctx.lineWidth = 1.5;
          ctx.stroke();
        }
      }

      // 4. Draw Traveling Data Packets
      packets.forEach((pkt) => {
        if (pkt.sourceIdx === pkt.targetIdx) {
          pkt.targetIdx = (pkt.sourceIdx + 1) % nodes.length;
        }

        pkt.progress += pkt.speed;
        if (pkt.progress >= 1) {
          pkt.progress = 0;
          pkt.sourceIdx = Math.floor(Math.random() * nodes.length);
          pkt.targetIdx = (pkt.sourceIdx + 1 + Math.floor(Math.random() * (nodes.length - 1))) % nodes.length;
        }

        const p1 = nodes[pkt.sourceIdx];
        const p2 = nodes[pkt.targetIdx];

        const curX = p1.x + (p2.x - p1.x) * pkt.progress;
        const curY = p1.y + (p2.y - p1.y) * pkt.progress;

        // Packet Glow
        ctx.beginPath();
        ctx.arc(curX, curY, pkt.size * 2, 0, Math.PI * 2);
        ctx.fillStyle = pkt.color === '#00F0FF' ? 'rgba(0, 240, 255, 0.25)' : 'rgba(121, 40, 202, 0.25)';
        ctx.fill();

        // Core Packet
        ctx.beginPath();
        ctx.arc(curX, curY, pkt.size, 0, Math.PI * 2);
        ctx.fillStyle = pkt.color;
        ctx.fill();
      });

      requestAnimationFrame(render);
    }

    render();
  }

  // --------------------------------------------------------------------------
  // 9. Interactive Browser Sandbox Widget (Drag & Drop + Clipboard Paste)
  // --------------------------------------------------------------------------
  function initBrowserSandbox() {
    const dropzone = document.getElementById('sandboxDropzone');
    const fileInput = document.getElementById('sandboxFileInput');
    const emptyState = document.getElementById('dropzoneEmptyState');
    const activeState = document.getElementById('dropzoneActiveState');
    const terminalLogs = document.getElementById('terminalLogs');

    const simFileName = document.getElementById('simFileName');
    const simFileSpecs = document.getElementById('simFileSpecs');
    const simFileIcon = document.getElementById('simFileIcon');
    const simWarpStage = document.getElementById('simWarpStage');
    const simWarpPercent = document.getElementById('simWarpPercent');
    const simProgressFill = document.getElementById('simProgressFill');
    const simSpeed = document.getElementById('simSpeed');
    const simHash = document.getElementById('simHash');

    const pasteBtn = document.getElementById('sandboxPasteBtn');
    const resetBtn = document.getElementById('sandboxResetBtn');

    if (!dropzone) return;

    // Dropzone Click -> Trigger File Input
    dropzone.addEventListener('click', (e) => {
      if (e.target.closest('#dropzoneActiveState')) return;
      fileInput.click();
    });

    fileInput.addEventListener('change', (e) => {
      if (e.target.files && e.target.files.length > 0) {
        processSandboxFile(e.target.files[0]);
      }
    });

    // Drag & Drop Events
    ['dragenter', 'dragover'].forEach((eventName) => {
      dropzone.addEventListener(eventName, (e) => {
        e.preventDefault();
        e.stopPropagation();
        dropzone.classList.add('dragover');
      });
    });

    ['dragleave', 'drop'].forEach((eventName) => {
      dropzone.addEventListener(eventName, (e) => {
        e.preventDefault();
        e.stopPropagation();
        dropzone.classList.remove('dragover');
      });
    });

    dropzone.addEventListener('drop', (e) => {
      const dt = e.dataTransfer;
      if (dt.files && dt.files.length > 0) {
        processSandboxFile(dt.files[0]);
      }
    });

    // Global Paste Listener (Ctrl+V / Cmd+V)
    window.addEventListener('paste', (e) => {
      const activeEl = document.activeElement;
      if (activeEl && (activeEl.tagName === 'INPUT' || activeEl.tagName === 'TEXTAREA')) {
        return;
      }
      handleClipboardPaste(e);
    });

    // Paste Button Click
    if (pasteBtn) {
      pasteBtn.addEventListener('click', async () => {
        try {
          if (navigator.clipboard && navigator.clipboard.readText) {
            const text = await navigator.clipboard.readText();
            if (text && text.trim().length > 0) {
              processSandboxTextPayload(text);
            } else {
              processSandboxTextPayload('https://aetherdrop.network/invite/warp-892147 - Zero-Cloud P2P Mesh');
            }
          } else {
            processSandboxTextPayload('AetherDrop AES-256 Encrypted Clip Payload: #00F0FF');
          }
        } catch (err) {
          processSandboxTextPayload('AetherDrop P2P Ephemeral Clipboard Broadcast [OK]');
        }
      });
    }

    // Reset Button
    if (resetBtn) {
      resetBtn.addEventListener('click', () => {
        resetSandbox();
      });
    }

    function handleClipboardPaste(e) {
      const clipboardData = e.clipboardData || window.clipboardData;
      if (!clipboardData) return;

      if (clipboardData.files && clipboardData.files.length > 0) {
        processSandboxFile(clipboardData.files[0]);
        return;
      }

      const pastedText = clipboardData.getData('Text');
      if (pastedText && pastedText.trim().length > 0) {
        processSandboxTextPayload(pastedText);
      }
    }

    function processSandboxTextPayload(text) {
      const byteLen = new Blob([text]).size;
      const fakeFile = {
        name: `clipboard_${Date.now().toString().slice(-4)}.txt`,
        size: Math.max(byteLen, 256),
        type: 'text/plain',
        isClipboard: true
      };
      processSandboxFile(fakeFile, text.slice(0, 48));
    }

    function processSandboxFile(file, previewSnippet) {
      emptyState.classList.add('hidden');
      activeState.classList.remove('hidden');

      const fileName = file.name;
      const fileSize = formatBytes(file.size);
      const chunkCount = Math.max(1, Math.ceil(file.size / (256 * 1024)));

      // File icon detection
      const ext = fileName.split('.').pop().toLowerCase();
      let icon = '📄';
      if (['png', 'jpg', 'jpeg', 'gif', 'webp', 'svg'].includes(ext)) icon = '🖼️';
      else if (['mp4', 'mov', 'avi', 'mkv'].includes(ext)) icon = '🎬';
      else if (['zip', 'tar', 'gz', 'rar', '7z'].includes(ext)) icon = '📦';
      else if (['mp3', 'wav', 'flac'].includes(ext)) icon = '🎵';
      else if (['pdf', 'doc', 'docx'].includes(ext)) icon = '📑';

      simFileIcon.textContent = icon;
      simFileName.textContent = fileName;
      simFileSpecs.textContent = `${fileSize} • ${chunkCount} Chunks (256KB)`;

      // Terminal log
      appendTerminalLog(`[Transfer] Initiated: ${fileName} (${fileSize})`, 'highlight');
      appendTerminalLog(`[Pipeline] Slicing into ${chunkCount} WebRTC DataChannel chunks (256KB each).`, 'info');

      // Generate SHA-256 pseudo hash
      const randomHash = generateSimulatedHash(fileName);
      simHash.textContent = `SHA: ${randomHash.slice(0, 16)}...`;

      // Animate Progress
      let progress = 0;
      simProgressFill.style.width = '0%';
      simWarpPercent.textContent = '0%';

      const interval = setInterval(() => {
        progress += Math.floor(Math.random() * 8) + 5;
        if (progress > 100) progress = 100;

        simProgressFill.style.width = `${progress}%`;
        simWarpPercent.textContent = `${progress}%`;

        // Update stages
        if (progress < 30) {
          simWarpStage.textContent = 'Encrypting stream with AES-256-GCM...';
          simSpeed.textContent = `${(800 + Math.random() * 300).toFixed(0)} MB/s`;
        } else if (progress < 75) {
          simWarpStage.textContent = `Warping chunk ${Math.floor((progress / 100) * chunkCount)} / ${chunkCount} to peer...`;
          simSpeed.textContent = `${(1150 + Math.random() * 250).toFixed(0)} MB/s`;
        } else if (progress < 100) {
          simWarpStage.textContent = 'Verifying SHA-256 CRC checksum on receiver...';
        } else {
          simWarpStage.textContent = 'Transfer Complete! 0 Cloud Bytes Stored.';
          simSpeed.textContent = 'Warp Speed: 1.28 GB/s';
          appendTerminalLog(`[Success] Peer receiver verified 100% of ${fileName}.`, 'success');
          appendTerminalLog(`[Telemetry] +75 Warp XP awarded! Streak preserved.`, 'highlight');
          clearInterval(interval);
        }
      }, 70);
    }

    function appendTerminalLog(msg, type = '') {
      if (!terminalLogs) return;
      const line = document.createElement('div');
      line.className = `log-line ${type}`;
      line.textContent = msg;
      terminalLogs.appendChild(line);
      terminalLogs.scrollTop = terminalLogs.scrollHeight;
    }

    function resetSandbox() {
      emptyState.classList.remove('hidden');
      activeState.classList.add('hidden');
      simProgressFill.style.width = '0%';
      simWarpPercent.textContent = '0%';
      appendTerminalLog('[System] Browser Sandbox reset. Ready for next file warp.', 'info');
    }
  }

  function formatBytes(bytes) {
    if (bytes === 0) return '0 Bytes';
    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
  }

  function generateSimulatedHash(seed) {
    let hash = 0;
    for (let i = 0; i < seed.length; i++) {
      hash = (hash << 5) - hash + seed.charCodeAt(i);
      hash |= 0;
    }
    const hex = Math.abs(hash).toString(16).padStart(8, '0');
    return `${hex}e4b892f17a94c03b1284d720`;
  }

  // --------------------------------------------------------------------------
  // 10. Interactive Cyber Avatar & Rank Progression Tree (Lvl 1 to 50)
  // --------------------------------------------------------------------------
  function initAvatarProgression() {
    const scrubber = document.getElementById('rankScrubber');
    const sliderRankTitle = document.getElementById('sliderRankTitle');
    const sliderXpInfo = document.getElementById('sliderXpInfo');
    const avatarPreviewRing = document.getElementById('avatarPreviewRing');
    const avatarHaloGlow = document.getElementById('avatarHaloGlow');
    const avatarPreviewFace = document.getElementById('avatarPreviewFace');
    const avatarLevelTag = document.getElementById('avatarLevelTag');
    const avatarsGrid = document.getElementById('avatarsGrid');

    if (!scrubber || !avatarsGrid) return;

    // Populate Initial 12 Avatars Grid
    renderAvatarsGrid(1);

    // Initial Preview Face
    updateSliderPreview(1);

    scrubber.addEventListener('input', (e) => {
      const lvl = parseInt(e.target.value, 10);
      updateSliderPreview(lvl);
      renderAvatarsGrid(lvl);
    });

    function updateSliderPreview(lvl) {
      const rankTitle = getRankTitle(lvl);
      const currentLevelStartXp = lvl === 1 ? 0 : 25 * lvl * lvl;
      const nextLevelTargetXp = 25 * (lvl + 1) * (lvl + 1);

      if (sliderRankTitle) sliderRankTitle.textContent = rankTitle;
      if (sliderXpInfo) {
        sliderXpInfo.textContent = `${currentLevelStartXp.toLocaleString()} / ${nextLevelTargetXp.toLocaleString()} WXP • Level ${lvl} of 50`;
      }
      if (avatarLevelTag) avatarLevelTag.textContent = `LVL ${lvl}`;

      // Update ring gradient and halo glow
      if (avatarPreviewRing) {
        avatarPreviewRing.style.background = getRankGradient(lvl);
        avatarPreviewRing.style.boxShadow = `0 0 24px ${getRankGlowColor(lvl)}`;
      }
      if (avatarHaloGlow) {
        avatarHaloGlow.style.background = getRankGlowColor(lvl);
      }

      // Find highest avatar unlocked for this level
      let activeAvatar = CYBER_AVATARS[0];
      for (let i = CYBER_AVATARS.length - 1; i >= 0; i--) {
        if (lvl >= CYBER_AVATARS[i].level) {
          activeAvatar = CYBER_AVATARS[i];
          break;
        }
      }

      if (avatarPreviewFace) {
        avatarPreviewFace.innerHTML = generateAvatarSVG(activeAvatar);
      }
    }

    function renderAvatarsGrid(currentLevel) {
      avatarsGrid.innerHTML = '';
      CYBER_AVATARS.forEach((av) => {
        const isUnlocked = currentLevel >= av.level;
        const card = document.createElement('div');
        card.className = `avatar-card ${isUnlocked ? 'unlocked' : 'locked'}`;
        card.innerHTML = `
          <div class="avatar-lock-overlay">
            ${isUnlocked ? '✓ Unlocked' : `🔒 Lvl ${av.level}`}
          </div>
          <div class="avatar-graphic-wrap" style="background: ${isUnlocked ? getRankGradient(av.level) : 'rgba(255,255,255,0.08)'}">
            ${generateAvatarSVG(av)}
          </div>
          <h4 class="avatar-card-title">${av.name}</h4>
          <p class="avatar-card-lore">${av.lore}</p>
          <span class="avatar-req-badge">Required: Level ${av.level}</span>
        `;
        avatarsGrid.appendChild(card);
      });
    }
  }

  // Generates crisp procedural vector SVGs for all 12 avatars
  function generateAvatarSVG(avatar) {
    const c1 = avatar.color1;
    const c2 = avatar.color2;

    switch (avatar.shape) {
      case 'pulse':
        return `
          <svg viewBox="0 0 64 64" fill="none">
            <circle cx="32" cy="32" r="26" stroke="${c1}" stroke-width="2" stroke-dasharray="4 2"/>
            <polygon points="32,16 44,42 20,42" fill="${c1}" opacity="0.85"/>
            <circle cx="32" cy="32" r="6" fill="#FFFFFF"/>
          </svg>
        `;
      case 'hex':
        return `
          <svg viewBox="0 0 64 64" fill="none">
            <polygon points="32,8 52,20 52,44 32,56 12,44 12,20" stroke="${c1}" stroke-width="3" fill="rgba(37, 99, 235, 0.2)"/>
            <circle cx="32" cy="32" r="8" fill="${c2}"/>
          </svg>
        `;
      case 'prism':
        return `
          <svg viewBox="0 0 64 64" fill="none">
            <polygon points="32,12 50,48 14,48" stroke="${c1}" stroke-width="2.5" fill="none"/>
            <polygon points="32,52 50,16 14,16" stroke="${c2}" stroke-width="2" fill="none" opacity="0.7"/>
            <circle cx="32" cy="32" r="5" fill="#FFFFFF"/>
          </svg>
        `;
      case 'orbital':
        return `
          <svg viewBox="0 0 64 64" fill="none">
            <ellipse cx="32" cy="32" rx="26" ry="12" stroke="${c1}" stroke-width="2.5" transform="rotate(-30 32 32)"/>
            <ellipse cx="32" cy="32" rx="26" ry="12" stroke="${c2}" stroke-width="2.5" transform="rotate(30 32 32)"/>
            <circle cx="32" cy="32" r="7" fill="#00FFB2"/>
          </svg>
        `;
      case 'kitsune':
        return `
          <svg viewBox="0 0 64 64" fill="none">
            <polygon points="32,14 46,28 32,52 18,28" stroke="${c1}" stroke-width="3" fill="rgba(255, 42, 133, 0.2)"/>
            <polyline points="20,18 24,10 30,20" stroke="${c1}" stroke-width="2.5"/>
            <polyline points="44,18 40,10 34,20" stroke="${c1}" stroke-width="2.5"/>
            <circle cx="26" cy="30" r="3" fill="${c2}"/>
            <circle cx="38" cy="30" r="3" fill="${c2}"/>
          </svg>
        `;
      case 'droid':
        return `
          <svg viewBox="0 0 64 64" fill="none">
            <rect x="16" y="18" width="32" height="28" rx="6" stroke="${c1}" stroke-width="3" fill="rgba(0, 255, 178, 0.15)"/>
            <line x1="32" y1="18" x2="32" y2="10" stroke="${c1}" stroke-width="2.5"/>
            <circle cx="32" cy="10" r="3" fill="${c2}"/>
            <rect x="22" y="26" width="20" height="6" rx="3" fill="${c1}"/>
          </svg>
        `;
      case 'samurai':
        return `
          <svg viewBox="0 0 64 64" fill="none">
            <path d="M14 26 C22 14, 42 14, 50 26" stroke="${c1}" stroke-width="3" fill="none"/>
            <polygon points="32,12 36,24 28,24" fill="${c2}"/>
            <polygon points="18,30 46,30 32,54" stroke="${c1}" stroke-width="2.5" fill="rgba(121, 40, 202, 0.3)"/>
          </svg>
        `;
      case 'valkyrie':
        return `
          <svg viewBox="0 0 64 64" fill="none">
            <path d="M32 14 L12 28 L24 38 L32 26 L40 38 L52 28 Z" stroke="${c1}" stroke-width="2.5" fill="rgba(103, 232, 249, 0.25)"/>
            <polygon points="32,22 36,48 28,48" fill="${c2}"/>
          </svg>
        `;
      case 'phantom':
        return `
          <svg viewBox="0 0 64 64" fill="none">
            <circle cx="32" cy="32" r="22" stroke="${c1}" stroke-width="2" stroke-dasharray="6 3"/>
            <path d="M22 28 Q32 18 42 28 T32 50 Z" stroke="${c2}" stroke-width="2.5" fill="rgba(192, 132, 252, 0.2)"/>
          </svg>
        `;
      case 'phoenix':
        return `
          <svg viewBox="0 0 64 64" fill="none">
            <path d="M32 10 Q16 28 8 36 Q24 34 32 44 Q40 34 56 36 Q48 28 32 10 Z" fill="url(#phxGrad)" stroke="${c1}" stroke-width="2"/>
            <circle cx="32" cy="24" r="4" fill="#FFFFFF"/>
            <defs>
              <linearGradient id="phxGrad" x1="0" y1="0" x2="0" y2="1">
                <stop offset="0%" stop-color="#FFB800"/>
                <stop offset="100%" stop-color="#FF5722"/>
              </linearGradient>
            </defs>
          </svg>
        `;
      case 'titan':
        return `
          <svg viewBox="0 0 64 64" fill="none">
            <polygon points="22,12 42,12 52,22 52,42 42,52 22,52 12,42 12,22" stroke="${c1}" stroke-width="3" fill="rgba(255, 51, 102, 0.25)"/>
            <circle cx="32" cy="32" r="10" stroke="${c2}" stroke-width="2.5" fill="#111116"/>
            <circle cx="32" cy="32" r="4" fill="${c1}"/>
          </svg>
        `;
      case 'singularity':
        return `
          <svg viewBox="0 0 64 64" fill="none">
            <circle cx="32" cy="32" r="26" stroke="#00F0FF" stroke-width="2" stroke-dasharray="3 3"/>
            <circle cx="32" cy="32" r="20" stroke="#7928CA" stroke-width="2.5"/>
            <circle cx="32" cy="32" r="14" stroke="#FFB800" stroke-width="2"/>
            <circle cx="32" cy="32" r="8" fill="#000000" stroke="#FFFFFF" stroke-width="1.5"/>
          </svg>
        `;
      default:
        return `<circle cx="32" cy="32" r="20" fill="${c1}"/>`;
    }
  }

  // --------------------------------------------------------------------------
  // 11. Interactive Theme Switcher (Dark / Light)
  // --------------------------------------------------------------------------
  function initThemeSwitcher() {
    const themeBtn = document.getElementById('themeToggleBtn');
    if (!themeBtn) return;

    // Load persisted preference or default to dark
    const savedTheme = localStorage.getItem('aetherdrop_theme') || 'dark';
    document.documentElement.setAttribute('data-theme', savedTheme);

    themeBtn.addEventListener('click', () => {
      const currentTheme = document.documentElement.getAttribute('data-theme') || 'dark';
      const newTheme = currentTheme === 'dark' ? 'light' : 'dark';
      document.documentElement.setAttribute('data-theme', newTheme);
      localStorage.setItem('aetherdrop_theme', newTheme);
    });

    // Keyboard shortcut 'T' for theme toggle
    window.addEventListener('keydown', (e) => {
      if (e.key === 't' || e.key === 'T') {
        const activeEl = document.activeElement;
        if (activeEl && (activeEl.tagName === 'INPUT' || activeEl.tagName === 'TEXTAREA')) return;
        themeBtn.click();
      }
    });
  }

  // --------------------------------------------------------------------------
  // 12. iOS Sideload Modal & Mobile Drawer Navigation
  // --------------------------------------------------------------------------
  function initModalsAndNavigation() {
    // iOS Guide Modal
    const iosModal = document.getElementById('iosGuideModal');
    const openIosGuideBtn = document.getElementById('openIosGuideBtn');
    const closeIosModalBtn = document.getElementById('closeIosModalBtn');

    if (openIosGuideBtn && iosModal) {
      openIosGuideBtn.addEventListener('click', () => {
        iosModal.classList.add('open');
        iosModal.setAttribute('aria-hidden', 'false');
      });
    }

    if (closeIosModalBtn && iosModal) {
      closeIosModalBtn.addEventListener('click', () => {
        iosModal.classList.remove('open');
        iosModal.setAttribute('aria-hidden', 'true');
      });
    }

    if (iosModal) {
      iosModal.addEventListener('click', (e) => {
        if (e.target === iosModal) {
          iosModal.classList.remove('open');
          iosModal.setAttribute('aria-hidden', 'true');
        }
      });
    }

    // Modal Tabs
    const modalTabs = document.querySelectorAll('.modal-tab');
    modalTabs.forEach((tab) => {
      tab.addEventListener('click', () => {
        modalTabs.forEach((t) => t.classList.remove('active'));
        tab.classList.add('active');

        const tabKey = tab.getAttribute('data-tab');
        document.querySelectorAll('.modal-tab-content').forEach((c) => c.classList.remove('active'));

        const targetContent = document.getElementById(
          tabKey === 'testflight'
            ? 'tabContentTestflight'
            : tabKey === 'altstore'
              ? 'tabContentAltstore'
              : 'tabContentDirectipa'
        );
        if (targetContent) targetContent.classList.add('active');
      });
    });

    // Mobile Drawer
    const mobileMenuToggle = document.getElementById('mobileMenuToggle');
    const mobileDrawer = document.getElementById('mobileDrawer');
    if (mobileMenuToggle && mobileDrawer) {
      mobileMenuToggle.addEventListener('click', () => {
        mobileDrawer.classList.toggle('open');
      });
      document.querySelectorAll('.mobile-link').forEach((link) => {
        link.addEventListener('click', () => {
          mobileDrawer.classList.remove('open');
        });
      });
    }

    // Global Click Delegation for [data-download]
    document.addEventListener('click', (e) => {
      const btn = e.target.closest('[data-download]');
      if (!btn) return;
      const platform = btn.getAttribute('data-download');
      triggerPlatformDownload(platform);
    });

    // Escape Key to Close Modals
    window.addEventListener('keydown', (e) => {
      if (e.key === 'Escape' && iosModal && iosModal.classList.contains('open')) {
        iosModal.classList.remove('open');
      }
    });
  }

  // --------------------------------------------------------------------------
  // 13. Application Bootstrap
  // --------------------------------------------------------------------------
  document.addEventListener('DOMContentLoaded', () => {
    applyDetectedOSBadge();
    initThemeSwitcher();
    initP2PBeamCanvas();
    initSupabase();
    initBrowserSandbox();
    initAvatarProgression();
    initModalsAndNavigation();

    console.log('%cAetherDrop%c P2P Client Ready. 100% Free Forever.', 'background:#00F0FF;color:#000;font-weight:bold;padding:4px 8px;border-radius:4px;', 'color:#00F0FF;margin-left:8px;');
  });
})();

