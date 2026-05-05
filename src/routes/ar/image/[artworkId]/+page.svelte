<!-- Isolated AR page — does NOT touch Image3DManipulator or Artwork3DShowcase -->
<script>
  import { goto } from '$app/navigation';
  import { onMount } from 'svelte';
  import { browser } from '$app/environment';
  import { CF_IMAGES_ACCOUNT_HASH } from '$lib/config.js';

  const { params } = $props();

  let previewUrl = $derived(
    `https://imagedelivery.net/${CF_IMAGES_ACCOUNT_HASH}/${params.artworkId}/thumbnail`
  );
  let textureUrl = $derived(
    `https://imagedelivery.net/${CF_IMAGES_ACCOUNT_HASH}/${params.artworkId}/gallery`
  );

  let status = $state('loading'); // loading | ready | unsupported | error
  let errorMsg = $state('');
  let THREE = null;

  onMount(async () => {
    if (!browser || !navigator.xr) {
      status = 'unsupported';
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
      if (!supported) {
        status = 'unsupported';
        return;
      }
    } catch {
      status = 'unsupported';
      return;
    }

    status = 'ready';
  });

  // User gesture required to start AR session
  async function launchAR() {
    if (!THREE) return;
    try {
      await startAR(THREE);
      status = 'ar-active';
    } catch (e) {
      console.error('[AR] Full error:', e);
      errorMsg = e.message || 'AR failed to start';
      // Make it clearer what failed
      if (e.message?.includes('hit-test')) {
        errorMsg = 'Hit test not supported on this device. ' + e.message;
      } else if (e.message?.includes('reference space')) {
        errorMsg = 'Reference space not supported. ' + e.message;
      } else if (e.message?.includes('not supported')) {
        errorMsg = 'Feature not supported: ' + e.message;
      }
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

    const textureLoader = new THREE.TextureLoader();
    const texture = await new Promise((res, rej) => textureLoader.load(textureUrl, res, undefined, rej));
    texture.colorSpace = THREE.SRGBColorSpace;
    const aspect = texture.image.height / texture.image.width;
    const geo = new THREE.PlaneGeometry(0.5, 0.5 * aspect);
    const mat = new THREE.MeshBasicMaterial({ map: texture, side: THREE.DoubleSide, transparent: true });
    const mesh = new THREE.Mesh(geo, mat);
    mesh.matrixAutoUpdate = false;
    mesh.visible = false;
    scene.add(mesh);

    // Tile mesh — hidden by default, uses repeating texture
    const tileTex = texture.clone();
    tileTex.needsUpdate = true;
    tileTex.wrapS = THREE.RepeatWrapping;
    tileTex.wrapT = THREE.RepeatWrapping;
    tileTex.repeat.set(3, 3);
    const tileGeo = new THREE.PlaneGeometry(2, 2 * aspect);
    const tileMat = new THREE.MeshBasicMaterial({ map: tileTex, side: THREE.DoubleSide });
    const tileMesh = new THREE.Mesh(tileGeo, tileMat);
    tileMesh.visible = false;
    scene.add(tileMesh);

    const reticleGeo = new THREE.RingGeometry(0.03, 0.05, 32);
    reticleGeo.rotateX(-Math.PI / 2);
    const reticleMat = new THREE.MeshBasicMaterial({ color: 0x333333 });
    const reticle = new THREE.Mesh(reticleGeo, reticleMat);
    reticle.matrixAutoUpdate = false;
    reticle.visible = false;
    scene.add(reticle);

    const viewerSpace = await session.requestReferenceSpace('viewer');

    // Hoist state variables (used in callbacks and UI below)
    let placed = false;
    let lastHitPose = null;
    let currentMode = null;
    let isTileMode = false;
    let isTattooMode = false;
    const activeMesh = () => isTileMode ? tileMesh : mesh;

    // Hit test is optional — may not be available on all devices
    let hitTestSource = null;
    try {
      hitTestSource = await session.requestHitTestSource({ space: viewerSpace });
    } catch (e) {
      console.warn('[AR] Hit test not available, placing artwork in front of camera');
    }

    // Auto-place if no hit-test available
    if (!hitTestSource) {
      mesh.visible = true;
      mesh.matrixAutoUpdate = true;
      mesh.position.set(0, -0.5, -1.2);
      placed = true;
      reticle.visible = false;
      updateUI();
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
      throw new Error('No supported reference space on this device');
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
          // No hit — show mesh floating in front of camera
          if (!mesh.visible) {
            mesh.visible = true;
            mesh.position.set(0, 0, -1);
            mesh.scale.set(0.5, 0.5, 0.5);
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
        updateUI();
      }
    });

    // Touch overlay — sits above canvas, BELOW UI controls
    const touchOverlay = document.createElement('div');
    touchOverlay.style.cssText = 'position:fixed;top:0;left:0;width:100%;height:100%;z-index:10000;display:none;';
    document.body.appendChild(touchOverlay);

    // --- UI: close button + mode buttons after placing ---
    const uiContainer = document.createElement('div');
    uiContainer.id = 'ar-ui';
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

    // Semi-transparent trigger button (always visible after placing)
    const triggerBtn = document.createElement('button');
    triggerBtn.style.cssText = 'position:fixed;bottom:calc(env(safe-area-inset-bottom, 0px) + 30px);right:20px;z-index:10003;width:50px;height:50px;border-radius:50%;background:rgba(44,94,61,0.4);color:rgba(255,255,255,0.6);border:2px solid rgba(255,255,255,0.2);font-size:22px;cursor:pointer;display:none;pointer-events:auto;transition:opacity 0.3s;';
    triggerBtn.textContent = '⚙';
    triggerBtn.onclick = () => showControls();
    uiContainer.appendChild(triggerBtn);

    // Opacity slider (right side, visible in tattoo mode)
    const sliderContainer = document.createElement('div');
    sliderContainer.style.cssText = 'position:fixed;right:16px;top:50%;transform:translateY(-50%);z-index:10003;display:none;flex-direction:column;align-items:center;gap:4px;pointer-events:auto;';
    uiContainer.appendChild(sliderContainer);

    const sliderLabel = document.createElement('span');
    sliderLabel.style.cssText = 'color:rgba(255,255,255,0.7);font-size:11px;background:rgba(0,0,0,0.5);padding:2px 6px;border-radius:4px;';
    sliderLabel.textContent = 'Opacity';
    sliderContainer.appendChild(sliderLabel);

    const opacitySlider = document.createElement('input');
    opacitySlider.type = 'range';
    opacitySlider.min = '0.1';
    opacitySlider.max = '1';
    opacitySlider.step = '0.05';
    opacitySlider.value = isTattooMode ? '0.75' : '1';
    opacitySlider.style.cssText = '-webkit-appearance:slider-vertical;width:30px;height:120px;writing-mode:bt-lr;-webkit-writing-mode:vertical-lr;accent-color:#2c5e3d;background:transparent;cursor:pointer;';
    opacitySlider.addEventListener('input', (e) => {
      mesh.material.opacity = parseFloat(e.target.value);
      sliderLabel.textContent = Math.round(e.target.value * 100) + '%';
    });
    sliderContainer.appendChild(opacitySlider);

    let hideTimer = null;
    function showControls() {
      uiContainer.style.opacity = '1';
      hintEl.style.opacity = '1';
      controlsBar.style.opacity = '1';
      triggerBtn.style.display = 'none';
      clearTimeout(hideTimer);
      hideTimer = setTimeout(hideControls, 4000);
      sliderContainer.style.display = 'flex';
      sliderContainer.style.opacity = '1';
      sliderLabel.textContent = Math.round(mesh.material.opacity * 100) + '%';
    }
    function hideControls() {
      uiContainer.style.opacity = '0.3';
      hintEl.style.opacity = '0';
      controlsBar.style.opacity = '0';
      triggerBtn.style.display = 'block';
      sliderContainer.style.display = 'flex';
      sliderContainer.style.opacity = '0.4';
    }

    const btnStyle = 'background:rgba(0,0,0,0.8);color:#fff;border:2px solid rgba(255,255,255,0.2);padding:12px 16px;border-radius:10px;font-size:14px;cursor:pointer;white-space:nowrap;';

    const wallBtn = document.createElement('button');
    wallBtn.style.cssText = btnStyle;
    wallBtn.textContent = '🧱 Wall';
    wallBtn.onclick = () => {
      isTileMode = false;
      isTattooMode = false;
      mesh.material.opacity = 1;
      mesh.material.transparent = false;
      mesh.visible = true;
      tileMesh.visible = false;
      activeMesh().rotation.set(0, activeMesh().rotation.y, 0);
      currentMode = 'wall';
      highlightBtn();
      showControls();
      hintEl.textContent = 'Drag to rotate · Pinch to resize · Two-finger twist to spin';
    };
    controlsBar.appendChild(wallBtn);

    const galleryBtn = document.createElement('button');
    galleryBtn.style.cssText = btnStyle;
    galleryBtn.textContent = '🖼️ Gallery';
    galleryBtn.onclick = () => {
      isTileMode = false;
      isTattooMode = false;
      mesh.material.opacity = 1;
      mesh.material.transparent = false;
      mesh.visible = true;
      tileMesh.visible = false;
      activeMesh().rotation.set(0, 0, 0);
      currentMode = 'gallery';
      highlightBtn();
      showControls();
      hintEl.textContent = 'Drag to rotate · Pinch to resize';
    };
    controlsBar.appendChild(galleryBtn);

    const floorBtn = document.createElement('button');
    floorBtn.style.cssText = btnStyle;
    floorBtn.textContent = '📏 Floor';
    floorBtn.onclick = () => {
      isTileMode = false;
      isTattooMode = false;
      mesh.material.opacity = 1;
      mesh.material.transparent = false;
      mesh.visible = true;
      tileMesh.visible = false;
      activeMesh().rotation.set(-Math.PI / 2, activeMesh().rotation.y, 0);
      currentMode = 'floor';
      highlightBtn();
      showControls();
      hintEl.textContent = 'Drag to rotate on floor · Two-finger twist to spin';
    };
    controlsBar.appendChild(floorBtn);

    const tileBtn = document.createElement('button');
    tileBtn.style.cssText = btnStyle;
    tileBtn.textContent = '🔲 Tiles';
    tileBtn.onclick = () => {
      isTileMode = !isTileMode;
      isTattooMode = false;
      if (isTileMode) {
        tileMesh.position.copy(mesh.position);
        tileMesh.quaternion.copy(mesh.quaternion);
        tileMesh.scale.copy(mesh.scale);
        tileMesh.visible = true;
        mesh.visible = false;
      } else {
        mesh.position.copy(tileMesh.position);
        mesh.quaternion.copy(tileMesh.quaternion);
        mesh.scale.copy(tileMesh.scale);
        mesh.visible = true;
        tileMesh.visible = false;
      }
      highlightBtn();
      showControls();
    };
    controlsBar.appendChild(tileBtn);

    const tattooBtn = document.createElement('button');
    tattooBtn.style.cssText = btnStyle;
    tattooBtn.textContent = '💅 Tattoo';
    tattooBtn.onclick = () => {
      isTattooMode = !isTattooMode;
      isTileMode = false;
      if (isTattooMode) {
        mesh.material.opacity = 0.75;
        mesh.material.transparent = true;
        mesh.visible = true;
        tileMesh.visible = false;
        opacitySlider.value = '0.75';
      } else {
        mesh.material.opacity = 1;
        opacitySlider.value = '1';
      }
      highlightBtn();
      showControls();
    };
    controlsBar.appendChild(tattooBtn);

    const resetBtn = document.createElement('button');
    resetBtn.style.cssText = btnStyle;
    resetBtn.textContent = '🔄 Reset';
    resetBtn.onclick = () => {
      placed = false;
      mesh.visible = false;
      tileMesh.visible = false;
      isTileMode = false;
      isTattooMode = false;
      mesh.material.opacity = 1;
      mesh.scale.set(1, 1, 1);
      tileMesh.scale.set(1, 1, 1);
      mesh.matrixAutoUpdate = false;
      currentMode = null;
      reticle.visible = true;
      clearTimeout(hideTimer);
      updateUI();
    };
    controlsBar.appendChild(resetBtn);

    const allBtns = [wallBtn, galleryBtn, floorBtn, tileBtn, tattooBtn, resetBtn];
    function highlightBtn() {
      allBtns.forEach((b, i) => {
        const active = (i === 0 && currentMode === 'wall') || (i === 1 && currentMode === 'gallery') || (i === 2 && currentMode === 'floor') || (i === 3 && isTileMode) || (i === 4 && isTattooMode);
        b.style.borderColor = active ? '#2c5e3d' : 'rgba(255,255,255,0.2)';
        b.style.background = active ? 'rgba(44,94,61,0.8)' : 'rgba(0,0,0,0.8)';
      });
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
        hintEl.textContent = 'Drag to rotate · Pinch to resize';
        clearTimeout(hideTimer);
        hideTimer = setTimeout(hideControls, 4000);
      }
      if (!placed) {
        hintEl.textContent = 'Point at a surface and tap to place';
      }
      highlightBtn();
    }
    updateUI();

    // --- Touch manipulation (same pattern as Image3DManipulator + twist for Z) ---
    let isDragging = false, isPinching = false;
    let touchStartX = 0, touchStartY = 0;
    let touchStartRotX = 0, touchStartRotY = 0, touchStartRotZ = 0;
    let touchStartPosX = 0, touchStartPosY = 0;
    let lastPinchDist = 0;
    let lastPinchAngle = 0;
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
        touchStartRotX = activeMesh().rotation.x;
        touchStartRotY = activeMesh().rotation.y;
        touchStartRotZ = activeMesh().rotation.z;
        touchStartPosX = activeMesh().position.x;
        touchStartPosY = activeMesh().position.y;
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
      const m = activeMesh();

      if (e.touches.length === 2 && isPinching) {
        const dx = e.touches[0].clientX - e.touches[1].clientX;
        const dy = e.touches[0].clientY - e.touches[1].clientY;
        const dist = Math.sqrt(dx * dx + dy * dy);
        const angle = angleBetweenTouches(e.touches[0], e.touches[1]);

        // Pinch = zoom
        if (lastPinchDist > 0) {
          const factor = dist / lastPinchDist;
          m.scale.multiplyScalar(factor);
          const s = Math.max(0.05, Math.min(5, m.scale.x));
          m.scale.set(s, s, s);
        }
        lastPinchDist = dist;

        // Twist = rotate Z (spin on surface)
        const angleDelta = angle - lastPinchAngle;
        m.rotation.z = m.rotation.z + angleDelta;
        lastPinchAngle = angle;

        // Two-finger drag = pan
        const cx = (e.touches[0].clientX + e.touches[1].clientX) / 2;
        const cy = (e.touches[0].clientY + e.touches[1].clientY) / 2;
        const pdx = cx - lastPinchCenter.x;
        const pdy = cy - lastPinchCenter.y;
        m.position.x = m.position.x + pdx * 0.002;
        m.position.y = m.position.y - pdy * 0.002;
        lastPinchCenter = { x: cx, y: cy };
        return;
      }

      if (!isDragging || e.touches.length !== 1) return;

      const dx = e.touches[0].clientX - touchStartX;
      const dy = e.touches[0].clientY - touchStartY;

      // 1 finger: rotate X + Y
      m.rotation.x = touchStartRotX + dy * 0.01;
      m.rotation.y = touchStartRotY + dx * 0.01;
      m.rotation.z = touchStartRotZ;
    }, { passive: false });

    touchOverlay.addEventListener('touchend', () => {
      isDragging = false;
      isPinching = false;
      lastPinchDist = 0;
    });

    const cleanup = () => {
      renderer.setAnimationLoop(null);
      renderer.domElement.remove();
      closeBtn.remove();
      uiContainer.remove();
      renderer.dispose();
      // Clean only styles we may have set
      ['overflow', 'position', 'top', 'width', 'height', 'touchAction'].forEach(p => {
        document.body.style.removeProperty(p);
      });
      document.documentElement.style.cssText = '';
      texture.dispose();
      tileTex.dispose();
      geo.dispose();
      tileGeo.dispose();
      mat.dispose();
      tileMat.dispose();
      reticleGeo.dispose();
      reticleMat.dispose();
      // Remove event listeners
      window.removeEventListener('resize', handleResize);
      // Remove any leftover AR elements
      document.querySelectorAll('#ar-ui, [style*="z-index:9999"]').forEach(el => el.remove());
      touchOverlay.remove();
      // Force full page reload to reset all state
      window.location.replace('/');
    };
    session.addEventListener('end', () => {
      cleanup();
    });
  }
</script>

<svelte:head>
  <title>AR — Antoine Patraldo</title>
</svelte:head>

{#if status === 'ar-active'}
  <!-- AR canvas covers everything — show nothing from Svelte -->
{:else if status === 'loading'}
  <div class="ar-page">
    <div class="spinner"></div>
    <p>Loading AR...</p>
  </div>
{:else if status === 'ready'}
  <div class="ar-page">
    <div class="ar-preview">
      <img src={previewUrl} alt="Artwork" />
    </div>
    <button class="launch-btn" onclick={launchAR}>
      👁️ Launch AR View
    </button>
    <a href="/" class="back-link">← Back</a>
  </div>
{:else if status === 'unsupported'}
  <div class="ar-page">
    <h2>AR Not Supported</h2>
    <p>Your device doesn't support WebXR AR. Try on a mobile device with AR capabilities.</p>
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

  .spinner {
    width: 40px;
    height: 40px;
    border: 3px solid #e0e0e0;
    border-top-color: #2c5e3d;
    border-radius: 50%;
    animation: spin 0.8s linear infinite;
  }

  @keyframes spin {
    to { transform: rotate(360deg); }
  }

  .ar-page h2 {
    margin: 0;
    font-size: 1.5rem;
    color: #2c5e3d;
  }

  .ar-page p {
    margin: 0;
    color: #666;
    text-align: center;
    max-width: 400px;
  }

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

  .launch-btn:hover {
    opacity: 0.9;
  }

  .back-link, .ar-page a:not(.launch-btn) {
    background: transparent;
    color: #666;
    border: 1px solid #ddd;
    padding: 0.75rem 1.5rem;
    border-radius: 8px;
    font-size: 1rem;
    cursor: pointer;
  }

  .back-link:hover, .ar-page a:not(.launch-btn):hover {
    background: #f5f5f5;
  }
</style>
