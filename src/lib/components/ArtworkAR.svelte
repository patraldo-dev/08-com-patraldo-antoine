<script>
  import { onMount, onDestroy } from 'svelte';
  import { browser } from '$app/environment';

  let { imageUrl, title = '', artworks = [], onClose } = $props();

  let container;
  let THREE;
  let renderer;
  let scene;
  let camera;
  let xrSession = $state(null);
  let xrSupported = $state(false);
  let xrActive = $state(false);
  let mode = $state('wall'); // 'wall' | 'float' | 'gallery'
  let galleryIndex = $state(0);
  let loading = $state(false);
  let error = $state('');
  let reticle;
  let hitTestSource;
  let referenceSpace;
  let meshes = [];
  let animationFrameId;

  onMount(async () => {
    if (!browser) return;
    xrSupported = navigator.xr ? await navigator.xr.isSessionSupported('immersive-ar') : false;
  });

  async function startAR() {
    if (!xrSupported) { error = 'WebXR no disponible en este navegador'; return; }
    loading = true;
    try {
      THREE = await import('three');
      const { XRControllerModelFactory } = await import('three/addons/webxr/XRControllerModelFactory.js');

      // Setup renderer
      renderer = new THREE.WebGLRenderer({ antialias: true, alpha: true });
      renderer.setPixelRatio(window.devicePixelRatio);
      renderer.setSize(window.innerWidth, window.innerHeight);
      renderer.xr.enabled = true;
      renderer.xr.referenceSpaceType = 'local-floor';
      container.appendChild(renderer.domElement);

      // Scene
      scene = new THREE.Scene();
      camera = new THREE.PerspectiveCamera(70, window.innerWidth / window.innerHeight, 0.01, 20);

      // Lighting
      const ambient = new THREE.AmbientLight(0xffffff, 0.8);
      scene.add(ambient);
      const dirLight = new THREE.DirectionalLight(0xffffff, 1.2);
      dirLight.position.set(0, 5, 5);
      scene.add(dirLight);

      // Reticle (hit test indicator)
      const reticleGeo = new THREE.RingGeometry(0.08, 0.12, 32);
      reticleGeo.rotateX(-Math.PI / 2);
      const reticleMat = new THREE.MeshBasicMaterial({ color: 0xc9a87c, transparent: true, opacity: 0.7 });
      reticle = new THREE.Mesh(reticleGeo, reticleMat);
      reticle.matrixAutoUpdate = false;
      reticle.visible = false;
      scene.add(reticle);

      // Start session
      const session = await navigator.xr.requestSession('immersive-ar', {
        requiredFeatures: ['hit-test'],
        optionalFeatures: ['dom-overlay', 'light-estimation'],
        domOverlay: container ? { root: container } : undefined
      });

      xrSession = session;
      xrActive = true;
      renderer.xr.setSession(session);

      session.addEventListener('end', () => {
        xrActive = false;
        xrSession = null;
        cleanup();
      });

      referenceSpace = await renderer.xr.getReferenceSpace();

      // Hit test
      session.addEventListener('select', onSelect);
      const viewerSpace = await session.requestReferenceSpace('viewer');
      hitTestSource = await session.requestHitTestSource({ space: viewerSpace });

      // Load artwork(s) based on mode
      if (mode === 'gallery' && artworks.length > 0) {
        await loadGallery();
      } else {
        await loadSingleArtwork(imageUrl);
      }

      // Render loop
      renderer.setAnimationLoop(onXRFrame);
      loading = false;
    } catch (e) {
      console.error('AR start error:', e);
      error = e.message || 'Error al iniciar AR';
      loading = false;
    }
  }

  async function loadSingleArtwork(url) {
    if (!THREE || !url) return;
    clearMeshes();

    const texture = await new THREE.TextureLoader().loadAsync(url);
    const aspect = texture.image.height / texture.image.width;
    const height = 1.5; // ~1.5m wall height
    const width = height / aspect;

    const geo = new THREE.PlaneGeometry(width, height);
    const mat = new THREE.MeshStandardMaterial({ map: texture, roughness: 0.3, metalness: 0.1 });
    const mesh = new THREE.Mesh(geo, mat);

    // Frame
    const frameDepth = 0.05;
    const frameBorder = 0.08;
    const frameGeo = new THREE.BoxGeometry(width + frameBorder * 2, height + frameBorder * 2, frameDepth);
    const frameMat = new THREE.MeshStandardMaterial({ color: 0x2a1f14, roughness: 0.6 });
    const frame = new THREE.Mesh(frameGeo, frameMat);
    frame.position.z = -frameDepth / 2;
    mesh.add(frame);

    // White mat border
    const matGeo = new THREE.PlaneGeometry(width + 0.04, height + 0.04);
    const matMat = new THREE.MeshStandardMaterial({ color: 0xfafaf5, roughness: 0.9 });
    const matMesh = new THREE.Mesh(matGeo, matMat);
    matMesh.position.z = 0.001;
    mesh.add(matMesh);

    mesh.visible = false; // Show on tap
    mesh.userData.isPlaceable = true;
    scene.add(mesh);
    meshes.push(mesh);
  }

  async function loadGallery() {
    if (!THREE) return;
    clearMeshes();

    const textureLoader = new THREE.TextureLoader();
    const count = Math.min(artworks.length, 8);
    const radius = 3;

    for (let i = 0; i < count; i++) {
      const art = artworks[i];
      const url = art.thumbnailUrl || art.imageUrl;
      if (!url) continue;

      try {
        const texture = await textureLoader.loadAsync(url);
        const aspect = texture.image.height / texture.image.width;
        const h = 1.2;
        const w = h / aspect;

        const geo = new THREE.PlaneGeometry(w, h);
        const mat = new THREE.MeshStandardMaterial({ map: texture, roughness: 0.3 });
        const mesh = new THREE.Mesh(geo, mat);

        // Frame
        const fGeo = new THREE.BoxGeometry(w + 0.1, h + 0.1, 0.04);
        const fMat = new THREE.MeshStandardMaterial({ color: 0x2a1f14, roughness: 0.6 });
        const frame = new THREE.Mesh(fGeo, fMat);
        frame.position.z = -0.02;
        mesh.add(frame);

        // Arrange in circle
        const angle = (i / count) * Math.PI * 2;
        mesh.position.set(
          Math.sin(angle) * radius,
          1.2 + Math.sin(i * 1.5) * 0.3, // Slight vertical variation
          Math.cos(angle) * radius
        );
        mesh.lookAt(0, 1.2, 0);
        mesh.userData.title = art.title || '';
        mesh.userData.index = i;
        scene.add(mesh);
        meshes.push(mesh);
      } catch (e) {
        console.warn('Failed to load gallery artwork:', i, e);
      }
    }
  }

  function onSelect(event) {
    if (mode === 'gallery') {
      // In gallery mode, select looks at what user tapped toward
      // For now, cycle through artworks
      galleryIndex = (galleryIndex + 1) % artworks.length;
      return;
    }

    // Wall/float mode: place the artwork
    if (hitTestSource && xrSession && referenceSpace) {
      const frame = event.frame;
      const results = frame.getHitTestResults(hitTestSource);
      if (results.length > 0 && meshes.length > 0) {
        const hit = results[0];
        const refSpace = renderer.xr.getReferenceSpace();
        const pose = hit.getPose(refSpace);
        if (pose) {
          const mesh = meshes[0];
          mesh.visible = true;
          if (mode === 'wall') {
            mesh.position.setFromMatrixPosition(pose.transform.matrix);
            // Snap to upright
            mesh.rotation.set(0, 0, 0);
            // Face the camera roughly
            mesh.lookAt(
              mesh.position.x,
              mesh.position.y,
              mesh.position.z - 1
            );
            mesh.rotation.x = 0; // Keep upright
            mesh.rotation.z = 0;
          } else if (mode === 'float') {
            mesh.position.setFromMatrixPosition(pose.transform.matrix);
            mesh.position.y += 0.5; // Float 50cm above hit point
            mesh.lookAt(
              mesh.position.x,
              mesh.position.y,
              mesh.position.z - 1
            );
          }
          reticle.visible = false;
        }
      }
    }
  }

  function onXRFrame(time, frame) {
    if (!xrSession || !renderer) return;

    // Update reticle from hit test
    if (hitTestSource && reticle) {
      const results = frame.getHitTestResults(hitTestSource);
      if (results.length > 0) {
        const refSpace = renderer.xr.getReferenceSpace();
        const pose = results[0].getPose(refSpace);
        if (pose) {
          reticle.visible = true;
          reticle.matrix.fromArray(pose.transform.matrix);
        }
      } else {
        reticle.visible = false;
      }
    }

    // Subtle float animation in gallery mode
    if (mode === 'gallery' || mode === 'float') {
      const t = time * 0.001;
      meshes.forEach((m, i) => {
        if (mode === 'float') {
          m.position.y += Math.sin(t + i * 0.5) * 0.0003;
        }
        if (mode === 'gallery') {
          m.position.y += Math.sin(t * 0.5 + i * 0.7) * 0.0002;
        }
      });
    }

    renderer.render(scene, camera);
  }

  function stopAR() {
    if (xrSession) {
      xrSession.end();
    }
    cleanup();
    if (onClose) onClose();
  }

  function clearMeshes() {
    meshes.forEach(m => {
      scene?.remove(m);
      m.geometry?.dispose();
      if (m.material) {
        if (m.material.map) m.material.map.dispose();
        m.material.dispose();
      }
    });
    meshes = [];
  }

  function cleanup() {
    if (animationFrameId) cancelAnimationFrame(animationFrameId);
    if (renderer) {
      renderer.setAnimationLoop(null);
      renderer.dispose();
      if (renderer.domElement.parentNode) {
        renderer.domElement.parentNode.removeChild(renderer.domElement);
      }
    }
    clearMeshes();
    scene = null;
    camera = null;
    renderer = null;
    reticle = null;
  }

  onDestroy(() => {
    cleanup();
    if (xrSession) xrSession.end();
  });
</script>

{#if xrSupported}
  <div class="ar-viewer" bind:this={container}>
    {#if !xrActive}
      <div class="ar-splash">
        <h3>🖼️ {title || 'Ver en AR'}</h3>
        <p class="ar-subtitle">Experiencia de Realidad Aumentada</p>

        <div class="mode-selector">
          <button class="mode-btn {mode === 'wall' ? 'active' : ''}" onclick={() => mode = 'wall'}>
            🧱 En mi pared
          </button>
          <button class="mode-btn {mode === 'float' ? 'active' : ''}" onclick={() => mode = 'float'}>
            🎈 Flotante
          </button>
          {#if artworks.length > 1}
            <button class="mode-btn {mode === 'gallery' ? 'active' : ''}" onclick={() => mode = 'gallery'}>
              🖼️ Galería ({artworks.length})
            </button>
          {/if}
        </div>

        <p class="mode-desc">
          {#if mode === 'wall'}
            Apunta a una pared y toca para colocar la obra a tamaño real
          {:else if mode === 'float'}
            Toca para soltar la obra en el aire — orbita a tu alrededor
          {:else}
            {artworks.length} obras dispuestas en círculo. Camina y explora.
          {/if}
        </p>

        <button class="start-btn" onclick={startAR} disabled={loading}>
          {loading ? '⏳ Cargando...' : '🚀 Iniciar AR'}
        </button>
        <button class="close-btn" onclick={onClose}>✕ Cerrar</button>
      </div>
    {/if}

    {#if error}
      <div class="ar-error">
        <p>⚠️ {error}</p>
        <button onclick={stopAR}>Cerrar</button>
      </div>
    {/if}

    {#if xrActive}
      <div class="ar-hud">
        <button class="hud-btn hud-stop" onclick={stopAR}>⏹</button>
        <div class="hud-mode">
          {mode === 'wall' ? '🧱 Pared' : mode === 'float' ? '🎈 Flotante' : '🖼️ Galería'}
        </div>
      </div>
    {/if}
  </div>
{:else}
  <div class="ar-unsupported">
    <p>📱 WebXR no disponible</p>
    <p class="ar-hint">Requiere Chrome Android o un navegador compatible con WebXR</p>
    <button onclick={onClose}>Cerrar</button>
  </div>
{/if}

<style>
  .ar-viewer {
    position: fixed;
    top: 0;
    left: 0;
    width: 100vw;
    height: 100vh;
    z-index: 9999;
    background: #000;
  }

  .ar-splash {
    position: absolute;
    top: 50%;
    left: 50%;
    transform: translate(-50%, -50%);
    text-align: center;
    color: #fff;
    font-family: system-ui, sans-serif;
    padding: 2rem;
    max-width: 400px;
  }

  .ar-splash h3 {
    font-size: 1.5rem;
    margin: 0 0 0.5rem;
    color: #c9a87c;
  }

  .ar-subtitle {
    opacity: 0.6;
    margin: 0 0 1.5rem;
    font-size: 0.9rem;
  }

  .mode-selector {
    display: flex;
    gap: 0.5rem;
    justify-content: center;
    flex-wrap: wrap;
    margin-bottom: 1rem;
  }

  .mode-btn {
    background: rgba(255,255,255,0.1);
    border: 1px solid rgba(255,255,255,0.2);
    color: #fff;
    padding: 0.5rem 1rem;
    border-radius: 8px;
    cursor: pointer;
    font-size: 0.85rem;
    transition: all 0.2s;
  }

  .mode-btn.active {
    background: #c9a87c;
    border-color: #c9a87c;
    color: #1a1a1a;
    font-weight: 600;
  }

  .mode-desc {
    font-size: 0.85rem;
    opacity: 0.7;
    margin-bottom: 1.5rem;
    line-height: 1.4;
  }

  .start-btn {
    background: #c9a87c;
    color: #1a1a1a;
    border: none;
    padding: 0.8rem 2rem;
    border-radius: 12px;
    font-size: 1.1rem;
    font-weight: 700;
    cursor: pointer;
    transition: transform 0.1s;
  }

  .start-btn:hover { transform: scale(1.05); }
  .start-btn:disabled { opacity: 0.5; cursor: not-allowed; transform: none; }

  .close-btn {
    display: block;
    margin: 1rem auto 0;
    background: none;
    border: 1px solid rgba(255,255,255,0.3);
    color: #fff;
    padding: 0.4rem 1rem;
    border-radius: 8px;
    cursor: pointer;
    font-size: 0.85rem;
  }

  .ar-hud {
    position: fixed;
    top: 16px;
    right: 16px;
    z-index: 10000;
    display: flex;
    align-items: center;
    gap: 8px;
  }

  .hud-btn {
    background: rgba(0,0,0,0.6);
    border: none;
    color: #fff;
    width: 44px;
    height: 44px;
    border-radius: 50%;
    font-size: 1.2rem;
    cursor: pointer;
  }

  .hud-mode {
    background: rgba(0,0,0,0.5);
    color: #c9a87c;
    padding: 6px 12px;
    border-radius: 20px;
    font-size: 0.8rem;
    font-weight: 600;
  }

  .ar-error {
    position: absolute;
    top: 50%;
    left: 50%;
    transform: translate(-50%, -50%);
    text-align: center;
    color: #fff;
    padding: 1.5rem;
  }

  .ar-error button {
    margin-top: 1rem;
    background: #c9a87c;
    border: none;
    color: #1a1a1a;
    padding: 0.5rem 1.5rem;
    border-radius: 8px;
    cursor: pointer;
  }

  .ar-unsupported {
    position: fixed;
    top: 0;
    left: 0;
    width: 100vw;
    height: 100vh;
    z-index: 9999;
    background: rgba(0,0,0,0.95);
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    color: #fff;
    text-align: center;
    padding: 2rem;
    font-family: system-ui, sans-serif;
  }

  .ar-unsupported p { margin: 0.5rem 0; }
  .ar-hint { font-size: 0.85rem; opacity: 0.6; }
  .ar-unsupported button {
    margin-top: 1rem;
    background: #c9a87c;
    border: none;
    color: #1a1a1a;
    padding: 0.6rem 1.5rem;
    border-radius: 8px;
    cursor: pointer;
  }
</style>
