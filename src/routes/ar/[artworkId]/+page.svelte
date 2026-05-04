<!-- Isolated AR page — does NOT touch Image3DManipulator or Artwork3DShowcase -->
<script>
  export const ssr = false;
  import { page } from '$app/stores';
  import { goto } from '$app/navigation';
  import { browser } from '$app/environment';
  import { CF_IMAGES_ACCOUNT_HASH } from '$lib/config.js';

  const { params } = $props();

  let imageUrl = $derived(
    `https://imagedelivery.net/${CF_IMAGES_ACCOUNT_HASH}/${params.artworkId}/public`
  );

  let status = $state('loading'); // loading | ready | unsupported | error
  let errorMsg = $state('');

  onMount(async () => {
    if (!browser || !navigator.xr) {
      status = 'unsupported';
      return;
    }

    let THREE;
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

    try {
      await startAR(THREE);
      status = 'ready';
    } catch (e) {
      errorMsg = e.message || 'AR failed to start';
      status = 'error';
    }
  });

  async function startAR(THREE) {
    const session = await navigator.xr.requestSession('immersive-ar', {
      requiredFeatures: ['hit-test'],
      optionalFeatures: ['dom-overlay', 'local-floor'],
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

    // Load artwork texture
    const textureLoader = new THREE.TextureLoader();
    const texture = await new Promise((res, rej) => textureLoader.load(imageUrl, res, undefined, rej));
    const aspect = texture.image.height / texture.image.width;
    const geo = new THREE.PlaneGeometry(0.5, 0.5 * aspect);
    const mat = new THREE.MeshBasicMaterial({ map: texture, side: THREE.DoubleSide, transparent: true });
    const mesh = new THREE.Mesh(geo, mat);
    mesh.matrixAutoUpdate = false;
    mesh.visible = false;
    scene.add(mesh);

    // Hit test reticle
    const reticleGeo = new THREE.RingGeometry(0.03, 0.05, 32);
    reticleGeo.rotateX(-Math.PI / 2);
    const reticleMat = new THREE.MeshBasicMaterial({ color: 0x333333 });
    const reticle = new THREE.Mesh(reticleGeo, reticleMat);
    reticle.matrixAutoUpdate = false;
    reticle.visible = false;
    scene.add(reticle);

    const viewerSpace = await session.requestReferenceSpace('viewer');
    const hitTestSource = await session.requestHitTestSource({ space: viewerSpace });

    // local-floor with fallback to local
    // Try local-floor, local, then fall back to viewer for hit test poses
    let localSpace;
    for (const type of ['local-floor', 'local', 'viewer']) {
      try {
        localSpace = await session.requestReferenceSpace(type);
        console.log('[AR] Using reference space:', type);
        break;
      } catch (e) {
        console.warn('[AR] Reference space', type, 'not supported:', e.message);
      }
    }
    if (!localSpace) {
      throw new Error('No supported reference space available on this device');
    }

    await renderer.xr.setSession(session);

    let placed = false;
    let lastHitPose = null;

    // Animation loop — gets frame directly (not 'xr-frame' event)
    renderer.setAnimationLoop((time, frame) => {
      if (!frame) return;
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
      } else {
        reticle.visible = false;
      }
      renderer.render(scene, camera);
    });

    // Tap to place
    session.addEventListener('select', () => {
      if (!placed && lastHitPose) {
        placed = true;
        mesh.matrix.fromArray(lastHitPose.transform.matrix);
        updateBtn();
      }
    });

    // Close button
    const closeBtn = document.createElement('button');
    closeBtn.style.cssText = 'position:fixed;top:20px;right:20px;z-index:10000;background:rgba(0,0,0,0.7);color:#fff;border:none;padding:12px 20px;border-radius:8px;font-size:16px;cursor:pointer;';
    function updateBtn() {
      closeBtn.textContent = placed ? '✕ Cerrar AR' : 'Toca para colocar · ✕ Cerrar AR';
    }
    updateBtn();
    closeBtn.onclick = () => session.end();
    document.body.appendChild(closeBtn);

    // Cleanup
    const cleanup = () => {
      renderer.setAnimationLoop(null);
      renderer.domElement.remove();
      closeBtn.remove();
      renderer.dispose();
    };
    session.addEventListener('end', () => {
      cleanup();
      goto('/');
    });
  }
</script>

<svelte:head>
  <title>AR — Antoine Patraldo</title>
</svelte:head>

{#if status === 'loading'}
  <div class="ar-loading">
    <div class="spinner"></div>
    <p>Initializing AR...</p>
  </div>
{:else if status === 'unsupported'}
  <div class="ar-message">
    <h2>AR Not Supported</h2>
    <p>Your device doesn't support WebXR AR. Try on a mobile device with AR capabilities.</p>
    <button onclick={() => goto('/')}>← Back</button>
  </div>
{:else if status === 'error'}
  <div class="ar-message">
    <h2>AR Error</h2>
    <p>{errorMsg}</p>
    <button onclick={() => goto('/')}>← Back</button>
  </div>
{/if}

<style>
  .ar-loading, .ar-message {
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

  .ar-message h2 {
    margin: 0;
    font-size: 1.5rem;
    color: #2c5e3d;
  }

  .ar-message p {
    margin: 0;
    color: #666;
    text-align: center;
    max-width: 400px;
  }

  .ar-message button {
    margin-top: 1rem;
    background: #2c5e3d;
    color: white;
    border: none;
    padding: 0.75rem 1.5rem;
    border-radius: 8px;
    font-size: 1rem;
    cursor: pointer;
  }
</style>
