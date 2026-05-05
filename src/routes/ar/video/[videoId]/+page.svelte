<!-- AR Video page — CF Stream videos as VideoTexture in WebXR -->
<script>
  import { onMount } from 'svelte';
  import { browser } from '$app/environment';

  const { params } = $props();

  let status = $state('loading'); // loading | ready | unsupported | error
  let errorMsg = $state('');
  let THREE = null;
  let videoInfo = null;
  let posterUrl = '';

  onMount(async () => {
    if (!browser || !navigator.xr) {
      status = 'unsupported';
      return;
    }
    try {
      const res = await fetch(`/api/stream-video/${params.videoId}`);
      if (!res.ok) throw new Error('Video not found');
      videoInfo = await res.json();
      posterUrl = videoInfo.thumbnail || '';
    } catch (e) {
      errorMsg = 'Failed to load video info: ' + e.message;
      status = 'error';
      return;
    }
    try {
      THREE = await import('three');
    } catch {
      errorMsg = 'Failed to load 3D engine';
      status = 'error';
      return;
    }
    try {
      const supported = await navigator.xr.isSessionSupported('immersive-ar');
      if (!supported) { status = 'unsupported'; return; }
    } catch {
      status = 'unsupported';
      return;
    }
    status = 'ready';
  });

  async function launchAR() {
    if (!THREE || !videoInfo) return;
    status = 'loading';
    try {
      await startAR(THREE);
      status = 'ar-active';
    } catch (e) {
      console.error('[AR Video] Error:', e);
      errorMsg = e.message || 'AR failed to start';
      status = 'error';
    }
  }

  async function startAR(THREE) {
    const session = await navigator.xr.requestSession('immersive-ar', {
      optionalFeatures: ['hit-test', 'dom-overlay', 'local-floor'],
      domOverlay: { root: document.body }
    });

    const renderer = new THREE.WebGLRenderer({ alpha: true, antialias: true });
    renderer.setSize(window.innerWidth, window.innerHeight);
    renderer.setPixelRatio(window.devicePixelRatio);
    renderer.xr.enabled = true;
    document.body.appendChild(renderer.domElement);
    renderer.domElement.style.cssText = 'position:fixed;top:0;left:0;width:100%;height:100%;z-index:9999;';

    const handleResize = () => {
      camera.aspect = window.innerWidth / window.innerHeight;
      camera.updateProjectionMatrix();
      renderer.setSize(window.innerWidth, window.innerHeight);
    };
    window.addEventListener('resize', handleResize);

    const scene = new THREE.Scene();
    const camera = new THREE.PerspectiveCamera(75, window.innerWidth / window.innerHeight, 0.1, 1000);
    scene.add(new THREE.AmbientLight(0xffffff, 1.5));
    scene.add(new THREE.DirectionalLight(0xffffff, 0.8));

    // --- Video element ---
    const video = document.createElement('video');
    video.crossOrigin = 'anonymous';
    video.loop = true;
    video.muted = true; // required for autoplay in WebXR
    video.playsInline = true;
    video.preload = 'auto';

    // Use direct MP4 (most reliable for VideoTexture)
    const videoUrl = videoInfo.videoUrl || videoInfo.streamUrl;
    video.src = videoUrl;
    video.load();

    // Wait for video to be ready (with timeout)
    const readyPromise = new Promise((res, rej) => {
      video.oncanplaythrough = () => res();
      video.onerror = () => rej(new Error('Failed to load video stream'));
    });
    const timeoutPromise = new Promise((_, rej) =>
      setTimeout(() => rej(new Error('Video load timed out (15s)')), 15000)
    );
    await Promise.race([readyPromise, timeoutPromise]);
    if (video.paused) await video.play();

    const texture = new THREE.VideoTexture(video);
    texture.colorSpace = THREE.SRGBColorSpace;
    texture.minFilter = THREE.LinearFilter;
    texture.magFilter = THREE.LinearFilter;

    // Height-to-width ratio for the plane geometry
    const heightToWidthRatio = (videoInfo.aspectRatio === '9:16')
      ? 16 / 9    // portrait: taller than wide
      : (videoInfo.aspectRatio === '4:3')
        ? 3 / 4
        : (videoInfo.aspectRatio === '1:1')
          ? 1
          : 9 / 16; // default landscape 16:9

    const geo = new THREE.PlaneGeometry(0.5, 0.5 * heightToWidthRatio);
    const mat = new THREE.MeshBasicMaterial({ map: texture, side: THREE.DoubleSide });
    const mesh = new THREE.Mesh(geo, mat);
    mesh.matrixAutoUpdate = false;
    mesh.visible = false;
    scene.add(mesh);

    // Reticle
    const reticleGeo = new THREE.RingGeometry(0.03, 0.05, 32);
    reticleGeo.rotateX(-Math.PI / 2);
    const reticleMat = new THREE.MeshBasicMaterial({ color: 0x333333 });
    const reticle = new THREE.Mesh(reticleGeo, reticleMat);
    reticle.matrixAutoUpdate = false;
    reticle.visible = false;
    scene.add(reticle);

    const viewerSpace = await session.requestReferenceSpace('viewer');

    // FIX: hoist all state variables before any callbacks reference them
    let placed = false;
    let lastHitPose = null;
    let currentMode = null; // hoisted — was declared after highlightBtn
    let hideTimer = null;   // hoisted — was declared after showControls

    let hitTestSource = null;
    try {
      hitTestSource = await session.requestHitTestSource({ space: viewerSpace });
    } catch (e) {
      console.warn('[AR] Hit test not available');
    }

    let localSpace;
    for (const type of ['local-floor', 'local', 'viewer']) {
      try {
        localSpace = await session.requestReferenceSpace(type);
        break;
      } catch (e) {
        console.warn('[AR] Reference space', type, 'not supported');
      }
    }
    if (!localSpace) {
      await session.end();
      throw new Error('No supported reference space');
    }

    await renderer.xr.setSession(session);

    renderer.setAnimationLoop((time, frame) => {
      if (!frame) return;
      if (hitTestSource) {
        const results = frame.getHitTestResults(hitTestSource);
        if (results.length > 0) {
          const pose = results[0].getPose(localSpace);
          if (pose) {
            lastHitPose = pose;
            reticle.visible = !placed;
            reticle.matrix.fromArray(pose.transform.matrix);
            if (!placed) {
              mesh.visible = true;
              mesh.matrix.fromArray(pose.transform.matrix);
            }
          }
        } else if (!placed) {
          reticle.visible = false;
          if (!mesh.visible) {
            mesh.visible = true;
            mesh.matrixAutoUpdate = true;
            mesh.position.set(0, -0.5, -1.2);
          }
        }
      }
      renderer.render(scene, camera);
    });

    session.addEventListener('select', () => {
      if (!placed && lastHitPose) {
        placed = true;
        const m = new THREE.Matrix4().fromArray(lastHitPose.transform.matrix);
        mesh.position.setFromMatrixPosition(m);
        mesh.quaternion.setFromRotationMatrix(m);
        mesh.matrixAutoUpdate = true;
        mesh.visible = true;
        reticle.visible = false;
        // FIX: guard against double-play — video may already be playing
        if (video.paused) video.play();
        updateUI();
      }
    });

    // Auto-place if no hit-test
    if (!hitTestSource) {
      mesh.visible = true;
      mesh.matrixAutoUpdate = true;
      mesh.position.set(0, -0.5, -1.2);
      placed = true;
      reticle.visible = false;
      updateUI();
    }

    // --- Touch overlay ---
    const touchOverlay = document.createElement('div');
    touchOverlay.style.cssText = 'position:fixed;top:0;left:0;width:100%;height:100%;z-index:10000;display:none;';
    document.body.appendChild(touchOverlay);

    // --- UI ---
    const uiContainer = document.createElement('div');
    uiContainer.id = 'ar-ui-video';
    uiContainer.style.cssText = 'position:fixed;top:0;left:0;right:0;bottom:0;z-index:10002;pointer-events:none;transition:opacity 0.5s;';
    document.body.appendChild(uiContainer);

    const closeBtn = document.createElement('button');
    closeBtn.style.cssText = 'position:fixed;top:env(safe-area-inset-top, 20px);right:20px;z-index:10003;background:rgba(0,0,0,0.7);color:#fff;border:none;padding:10px 16px;border-radius:8px;font-size:14px;cursor:pointer;pointer-events:auto;';
    closeBtn.onclick = () => session.end();
    uiContainer.appendChild(closeBtn);

    const hintEl = document.createElement('div');
    hintEl.style.cssText = 'position:fixed;top:calc(env(safe-area-inset-top, 20px) + 50px);left:50%;transform:translateX(-50%);background:rgba(0,0,0,0.7);color:#fff;padding:8px 16px;border-radius:8px;font-size:13px;text-align:center;pointer-events:none;max-width:85%;white-space:nowrap;transition:opacity 0.5s;';
    uiContainer.appendChild(hintEl);

    const controlsBar = document.createElement('div');
    controlsBar.style.cssText = 'position:fixed;bottom:calc(env(safe-area-inset-bottom, 0px) + 20px);left:50%;transform:translateX(-50%);display:none;flex-direction:row;gap:8px;pointer-events:auto;z-index:10003;flex-wrap:wrap;justify-content:center;max-width:95vw;transition:opacity 0.5s;';
    uiContainer.appendChild(controlsBar);

    const triggerBtn = document.createElement('button');
    triggerBtn.style.cssText = 'position:fixed;bottom:calc(env(safe-area-inset-bottom, 0px) + 30px);right:20px;z-index:10003;width:50px;height:50px;border-radius:50%;background:rgba(44,94,61,0.4);color:rgba(255,255,255,0.6);border:2px solid rgba(255,255,255,0.2);font-size:22px;cursor:pointer;display:none;pointer-events:auto;transition:opacity 0.3s;';
    triggerBtn.textContent = '⚙';
    triggerBtn.onclick = () => showControls();
    uiContainer.appendChild(triggerBtn);

    const btnStyle = 'background:rgba(0,0,0,0.8);color:#fff;border:2px solid rgba(255,255,255,0.2);padding:12px 16px;border-radius:10px;font-size:14px;cursor:pointer;white-space:nowrap;';

    const playPauseBtn = document.createElement('button');
    playPauseBtn.style.cssText = btnStyle;
    playPauseBtn.textContent = '⏸️ Pause';
    playPauseBtn.onclick = () => {
      if (video.paused) {
        video.play();
        playPauseBtn.textContent = '⏸️ Pause';
      } else {
        video.pause();
        playPauseBtn.textContent = '▶️ Play';
      }
      showControls();
    };
    controlsBar.appendChild(playPauseBtn);

    const wallBtn = document.createElement('button');
    wallBtn.style.cssText = btnStyle;
    wallBtn.textContent = '🧱 Wall';
    wallBtn.onclick = () => {
      mesh.rotation.set(0, mesh.rotation.y, 0);
      currentMode = 'wall';
      highlightBtn();
      showControls();
    };
    controlsBar.appendChild(wallBtn);

    const galleryBtn = document.createElement('button');
    galleryBtn.style.cssText = btnStyle;
    galleryBtn.textContent = '🖼️ Gallery';
    galleryBtn.onclick = () => {
      mesh.rotation.set(0, 0, 0);
      currentMode = 'gallery';
      highlightBtn();
      showControls();
    };
    controlsBar.appendChild(galleryBtn);

    const resetBtn = document.createElement('button');
    resetBtn.style.cssText = btnStyle;
    resetBtn.textContent = '🔄 Reset';
    resetBtn.onclick = () => {
      placed = false;
      mesh.visible = false;
      mesh.scale.set(1, 1, 1);
      mesh.matrixAutoUpdate = false;
      currentMode = null;
      reticle.visible = true;
      clearTimeout(hideTimer);
      updateUI();
    };
    controlsBar.appendChild(resetBtn);

    const allBtns = [playPauseBtn, wallBtn, galleryBtn, resetBtn];

    function highlightBtn() {
      allBtns.forEach((b, i) => {
        const active = (i === 1 && currentMode === 'wall') || (i === 2 && currentMode === 'gallery');
        b.style.borderColor = active ? '#2c5e3d' : 'rgba(255,255,255,0.2)';
        b.style.background = active ? 'rgba(44,94,61,0.8)' : 'rgba(0,0,0,0.8)';
      });
    }

    function showControls() {
      uiContainer.style.opacity = '1';
      hintEl.style.opacity = '1';
      controlsBar.style.opacity = '1';
      triggerBtn.style.display = 'none';
      clearTimeout(hideTimer);
      hideTimer = setTimeout(hideControls, 4000);
    }

    function hideControls() {
      uiContainer.style.opacity = '0.3';
      hintEl.style.opacity = '0';
      controlsBar.style.opacity = '0';
      triggerBtn.style.display = 'block';
    }

    function updateUI() {
      closeBtn.textContent = placed ? '✕ Close AR' : 'Tap to place · ✕ Close AR';
      controlsBar.style.display = placed ? 'flex' : 'none';
      touchOverlay.style.display = placed ? 'block' : 'none';
      triggerBtn.style.display = 'none';
      uiContainer.style.opacity = '1';
      hintEl.style.opacity = '1';
      controlsBar.style.opacity = '1';
      if (placed && !currentMode) {
        currentMode = 'wall';
        hintEl.textContent = 'Drag to rotate · Pinch to resize · ⏸️ to pause';
        clearTimeout(hideTimer);
        hideTimer = setTimeout(hideControls, 4000);
      }
      if (!placed) {
        hintEl.textContent = 'Point at a surface and tap to place video';
      }
      highlightBtn();
    }

    updateUI();

    // --- Touch gestures ---
    let isDragging = false, isPinching = false;
    let touchStartX = 0, touchStartY = 0;
    let touchStartRotX = 0, touchStartRotY = 0, touchStartRotZ = 0;
    let lastPinchDist = 0, lastPinchAngle = 0;
    let lastPinchCenter = { x: 0, y: 0 };

    function angleBetweenTouches(t1, t2) {
      return Math.atan2(t2.clientY - t1.clientY, t2.clientX - t1.clientX);
    }

    touchOverlay.addEventListener('touchstart', (e) => {
      if (placed && uiContainer.style.opacity !== '1') showControls();
      if (e.touches.length === 1) {
        e.preventDefault();
        isDragging = true;
        isPinching = false;
        touchStartX = e.touches[0].clientX;
        touchStartY = e.touches[0].clientY;
        touchStartRotX = mesh.rotation.x;
        touchStartRotY = mesh.rotation.y;
        touchStartRotZ = mesh.rotation.z;
      } else if (e.touches.length === 2) {
        e.preventDefault();
        isDragging = false;
        isPinching = true;
        const dx = e.touches[0].clientX - e.touches[1].clientX;
        const dy = e.touches[0].clientY - e.touches[1].clientY;
        lastPinchDist = Math.sqrt(dx * dx + dy * dy);
        lastPinchAngle = angleBetweenTouches(e.touches[0], e.touches[1]);
        lastPinchCenter = {
          x: (e.touches[0].clientX + e.touches[1].clientX) / 2,
          y: (e.touches[0].clientY + e.touches[1].clientY) / 2
        };
      }
    }, { passive: false });

    touchOverlay.addEventListener('touchmove', (e) => {
      if (!placed) return;
      e.preventDefault();
      if (e.touches.length === 2 && isPinching) {
        const dx = e.touches[0].clientX - e.touches[1].clientX;
        const dy = e.touches[0].clientY - e.touches[1].clientY;
        const dist = Math.sqrt(dx * dx + dy * dy);
        const angle = angleBetweenTouches(e.touches[0], e.touches[1]);
        if (lastPinchDist > 0) {
          const factor = dist / lastPinchDist;
          mesh.scale.multiplyScalar(factor);
          const s = Math.max(0.05, Math.min(5, mesh.scale.x));
          mesh.scale.set(s, s, s);
        }
        lastPinchDist = dist;
        mesh.rotation.z += angle - lastPinchAngle;
        lastPinchAngle = angle;
        const cx = (e.touches[0].clientX + e.touches[1].clientX) / 2;
        const cy = (e.touches[0].clientY + e.touches[1].clientY) / 2;
        mesh.position.x += (cx - lastPinchCenter.x) * 0.002;
        mesh.position.y -= (cy - lastPinchCenter.y) * 0.002;
        lastPinchCenter = { x: cx, y: cy };
        return;
      }
      if (!isDragging || e.touches.length !== 1) return;
      const dx = e.touches[0].clientX - touchStartX;
      const dy = e.touches[0].clientY - touchStartY;
      mesh.rotation.x = touchStartRotX + dy * 0.01;
      mesh.rotation.y = touchStartRotY + dx * 0.01;
      mesh.rotation.z = touchStartRotZ;
    }, { passive: false });

    touchOverlay.addEventListener('touchend', () => {
      isDragging = false;
      isPinching = false;
      lastPinchDist = 0;
    });

    // --- Cleanup ---
    const cleanup = () => {
      video.pause();
      video.src = '';
      renderer.setAnimationLoop(null);
      renderer.domElement.remove();
      uiContainer.remove();
      touchOverlay.remove();
      renderer.dispose();
      texture.dispose();
      geo.dispose();
      mat.dispose();
      reticleGeo.dispose();
      reticleMat.dispose();
      window.removeEventListener('resize', handleResize);
      // FIX: surgical style reset — don't nuke all body styles
      ['overflow', 'position', 'top', 'width', 'height', 'touchAction'].forEach(p => {
        document.body.style.removeProperty(p);
      });
      document.documentElement.style.cssText = '';
      document.querySelectorAll('#ar-ui-video, [style*="z-index:9999"]').forEach(el => el.remove());
      window.location.replace('/');
    };

    session.addEventListener('end', () => cleanup());
  }
</script>

<svelte:head>
  <title>AR Video — Antoine Patraldo</title>
  <!-- No hls.js script tag here — loaded dynamically only when needed -->
</svelte:head>

{#if status === 'ar-active'}
  <!-- AR canvas covers everything -->
{:else if status === 'loading'}
  <div class="ar-page">
    <div class="spinner"></div>
    <p>Loading video AR...</p>
  </div>
{:else if status === 'ready'}
  <div class="ar-page">
    <div class="ar-preview">
      {#if posterUrl}
        <img src={posterUrl} alt="Video preview" />
      {:else}
        <div class="video-placeholder">🎬</div>
      {/if}
      <p class="video-label">Video — {videoInfo?.duration ? `${Math.round(videoInfo.duration)}s` : ''}</p>
    </div>
    <button class="launch-btn" onclick={launchAR}>
      👁️ Launch AR Video
    </button>
    <a href="/" class="back-link">← Back</a>
  </div>
{:else if status === 'unsupported'}
  <div class="ar-page">
    <h2>AR Not Supported</h2>
    <p>Your device doesn't support WebXR AR. Try on a mobile device.</p>
    <a href="/" class="back-link">← Back</a>
  </div>
{:else if status === 'error'}
  <div class="ar-page">
    <h2>AR Error</h2>
    <p>{errorMsg}</p>
    <a href="/" class="back-link">← Back</a>
  </div>
{/if}

<style>
  .ar-page {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    min-height: 100vh;
    gap: 1.5rem;
    padding: 2rem;
    font-family: 'Inter', sans-serif;
    color: #333;
  }
  .ar-preview img {
    max-width: 300px;
    max-height: 300px;
    border-radius: 12px;
    box-shadow: 0 8px 32px rgba(0,0,0,0.15);
  }
  .video-placeholder {
    width: 200px;
    height: 200px;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 4rem;
    background: #f0f0f0;
    border-radius: 12px;
  }
  .video-label {
    margin: 0.5rem 0 0;
    color: #666;
    font-size: 0.9rem;
  }
  .spinner {
    width: 40px;
    height: 40px;
    border: 3px solid #e0e0e0;
    border-top-color: #2c5e3d;
    border-radius: 50%;
    animation: spin 0.8s linear infinite;
  }
  @keyframes spin { to { transform: rotate(360deg); } }
  .ar-page h2 { margin: 0; font-size: 1.5rem; color: #2c5e3d; }
  .ar-page p { margin: 0; color: #666; text-align: center; max-width: 400px; }
  .launch-btn {
    background: #2c5e3d;
    color: white;
    border: none;
    padding: 1rem 2rem;
    border-radius: 12px;
    font-size: 1.1rem;
    font-weight: 600;
    cursor: pointer;
    box-shadow: 0 4px 16px rgba(44, 94, 61, 0.3);
  }
  .launch-btn:hover { opacity: 0.9; }
  .back-link {
    background: transparent;
    color: #666;
    border: 1px solid #ddd;
    padding: 0.75rem 1.5rem;
    border-radius: 8px;
    font-size: 1rem;
    cursor: pointer;
    text-decoration: none;
  }
  .back-link:hover { background: #f5f5f5; }
</style>
