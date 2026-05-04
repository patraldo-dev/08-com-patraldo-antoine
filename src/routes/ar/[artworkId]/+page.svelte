<!-- Isolated AR page — does NOT touch Image3DManipulator or Artwork3DShowcase -->
<script>
  export const ssr = false;
  import { goto } from '$app/navigation';
  import { onMount } from 'svelte';
  import { browser } from '$app/environment';
  import { CF_IMAGES_ACCOUNT_HASH } from '$lib/config.js';

  const { params } = $props();

  let imageUrl = $derived(
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

    const scene = new THREE.Scene();
    const camera = new THREE.PerspectiveCamera(75, window.innerWidth / window.innerHeight, 0.1, 1000);
    scene.add(new THREE.AmbientLight(0xffffff, 1.5));
    scene.add(new THREE.DirectionalLight(0xffffff, 0.8));

    const textureLoader = new THREE.TextureLoader();
    const texture = await new Promise((res, rej) => textureLoader.load(imageUrl, res, undefined, rej));
    const aspect = texture.image.height / texture.image.width;
    const geo = new THREE.PlaneGeometry(0.5, 0.5 * aspect);
    const mat = new THREE.MeshBasicMaterial({ map: texture, side: THREE.DoubleSide, transparent: true });
    const mesh = new THREE.Mesh(geo, mat);
    mesh.matrixAutoUpdate = false;
    mesh.visible = false;
    scene.add(mesh);

    const reticleGeo = new THREE.RingGeometry(0.03, 0.05, 32);
    reticleGeo.rotateX(-Math.PI / 2);
    const reticleMat = new THREE.MeshBasicMaterial({ color: 0x333333 });
    const reticle = new THREE.Mesh(reticleGeo, reticleMat);
    reticle.matrixAutoUpdate = false;
    reticle.visible = false;
    scene.add(reticle);

    const viewerSpace = await session.requestReferenceSpace('viewer');

    // Hit test is optional — may not be available on all devices
    let hitTestSource = null;
    try {
      hitTestSource = await session.requestHitTestSource({ space: viewerSpace });
    } catch (e) {
      console.warn('[AR] Hit test not available, placing artwork in front of camera');
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

    let placed = false;
    let lastHitPose = null;

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
        // Store placement as position + quaternion for manipulation
        const m = new THREE.Matrix4().fromArray(lastHitPose.transform.matrix);
        mesh.position.setFromMatrixPosition(m);
        mesh.quaternion.setFromRotationMatrix(m);
        mesh.matrixAutoUpdate = true;
        mesh.visible = true;
        reticle.visible = false;
        updateUI();
      }
    });

    // --- UI: close button + mode buttons after placing ---
    const uiContainer = document.createElement('div');
    uiContainer.id = 'ar-ui';
    uiContainer.style.cssText = 'position:fixed;top:0;left:0;right:0;bottom:0;z-index:10000;pointer-events:none;';
    document.body.appendChild(uiContainer);

    const closeBtn = document.createElement('button');
    closeBtn.style.cssText = 'position:fixed;top:env(safe-area-inset-top, 20px);right:20px;z-index:10001;background:rgba(0,0,0,0.7);color:#fff;border:none;padding:10px 16px;border-radius:8px;font-size:14px;cursor:pointer;pointer-events:auto;';
    closeBtn.onclick = () => session.end();
    uiContainer.appendChild(closeBtn);

    const hintEl = document.createElement('div');
    hintEl.style.cssText = 'position:fixed;top:calc(env(safe-area-inset-top, 20px) + 50px);left:50%;transform:translateX(-50%);background:rgba(0,0,0,0.7);color:#fff;padding:8px 16px;border-radius:8px;font-size:13px;text-align:center;pointer-events:none;max-width:85%;white-space:nowrap;';
    uiContainer.appendChild(hintEl);

    const controlsBar = document.createElement('div');
    controlsBar.style.cssText = 'position:fixed;bottom:calc(env(safe-area-inset-bottom, 0px) + 20px);left:50%;transform:translateX(-50%);display:none;flex-direction:row;gap:8px;pointer-events:auto;z-index:10001;flex-wrap:wrap;justify-content:center;max-width:95vw;';
    uiContainer.appendChild(controlsBar);

    const btnStyle = 'background:rgba(0,0,0,0.8);color:#fff;border:2px solid rgba(255,255,255,0.2);padding:12px 16px;border-radius:10px;font-size:14px;cursor:pointer;white-space:nowrap;';

    const wallBtn = document.createElement('button');
    wallBtn.style.cssText = btnStyle;
    wallBtn.textContent = '🧱 Wall';
    wallBtn.onclick = () => {
      mesh.rotation.set(0, mesh.rotation.y, 0);
      currentMode = 'wall';
      highlightBtn();
      hintEl.textContent = 'Drag to rotate on wall · Pinch to resize';
    };
    controlsBar.appendChild(wallBtn);

    const galleryBtn = document.createElement('button');
    galleryBtn.style.cssText = btnStyle;
    galleryBtn.textContent = '🖼️ Gallery';
    galleryBtn.onclick = () => {
      mesh.rotation.set(0, 0, 0);
      currentMode = 'gallery';
      highlightBtn();
      hintEl.textContent = 'Drag left/right to rotate · Pinch to resize';
    };
    controlsBar.appendChild(galleryBtn);

    const floorBtn = document.createElement('button');
    floorBtn.style.cssText = btnStyle;
    floorBtn.textContent = '📏 Floor';
    floorBtn.onclick = () => {
      mesh.rotation.set(-Math.PI / 2, mesh.rotation.y, 0);
      currentMode = 'floor';
      highlightBtn();
      hintEl.textContent = 'Drag to rotate on floor · Pinch to resize';
    };
    controlsBar.appendChild(floorBtn);

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
      updateUI();
    };
    controlsBar.appendChild(resetBtn);

    const allBtns = [wallBtn, galleryBtn, floorBtn, resetBtn];
    function highlightBtn() {
      allBtns.forEach((b, i) => {
        b.style.borderColor = (i === 0 && currentMode === 'wall') || (i === 1 && currentMode === 'gallery') || (i === 2 && currentMode === 'floor') ? '#2c5e3d' : 'rgba(255,255,255,0.2)';
      });
    }

    let currentMode = null;
    function updateUI() {
      closeBtn.textContent = placed ? '✕ Close AR' : 'Tap to place · ✕ Close AR';
      controlsBar.style.display = placed ? 'flex' : 'none';
      if (placed && !currentMode) {
        currentMode = 'wall';
        hintEl.textContent = 'Drag to rotate · Pinch to resize';
      }
      if (!placed) {
        hintEl.textContent = 'Point at a surface and tap to place';
      }
      highlightBtn();
    }
    updateUI();

    // --- Touch manipulation after placing ---
    let touchStartX = 0, touchStartY = 0, touchStartRotY = 0, touchStartRotX = 0;
    let initialPinchDist = 0, initialScale = 1;

    renderer.domElement.addEventListener('touchstart', (e) => {
      if (!placed) return;
      if (e.touches.length === 1) {
        touchStartX = e.touches[0].clientX;
        touchStartY = e.touches[0].clientY;
        touchStartRotY = mesh.rotation.y;
        touchStartRotX = mesh.rotation.x;
      } else if (e.touches.length === 2) {
        const dx = e.touches[0].clientX - e.touches[1].clientX;
        const dy = e.touches[0].clientY - e.touches[1].clientY;
        initialPinchDist = Math.sqrt(dx * dx + dy * dy);
        initialScale = mesh.scale.x;
      }
    }, { passive: true });

    renderer.domElement.addEventListener('touchmove', (e) => {
      if (!placed) return;
      if (e.touches.length === 1) {
        e.preventDefault();
        const dx = (e.touches[0].clientX - touchStartX) * 0.01;
        const dy = (e.touches[0].clientY - touchStartY) * 0.01;
        mesh.rotation.y = touchStartRotY + dx;
        if (currentMode === 'floor') {
          mesh.rotation.x = touchStartRotX + dy;
        }
      } else if (e.touches.length === 2) {
        e.preventDefault();
        const dx = e.touches[0].clientX - e.touches[1].clientX;
        const dy = e.touches[0].clientY - e.touches[1].clientY;
        const dist = Math.sqrt(dx * dx + dy * dy);
        const s = Math.max(0.1, Math.min(5, initialScale * (dist / initialPinchDist)));
        mesh.scale.set(s, s, s);
      }
    }, { passive: false });

    const cleanup = () => {
      renderer.setAnimationLoop(null);
      renderer.domElement.remove();
      closeBtn.remove();
      uiContainer.remove();
      renderer.dispose();
      // Full body reset — WebGL canvas can leak styles
      document.body.style.cssText = '';
      document.documentElement.style.cssText = '';
      document.body.style.touchAction = '';
      document.body.style.overflow = '';
      document.body.style.position = '';
      document.body.style.top = '';
      document.body.style.width = '';
      document.body.style.height = '';
      // Remove any leftover AR elements
      document.querySelectorAll('#ar-ui, [style*="z-index:9999"]').forEach(el => el.remove());
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
      <img src={imageUrl} alt="Artwork" />
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
