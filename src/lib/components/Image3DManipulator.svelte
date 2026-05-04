<script>
  import { onMount, onDestroy } from 'svelte';
  import { browser } from '$app/environment';

  let { imageUrl } = $props();

  let container;
  let scene;
  let camera;
  let renderer;
  let imageMesh;
  let THREE;
  let resizeObserver;

  let rotation = $state({ x: 0, y: 0, z: 0 });
  let position = $state({ x: 0, y: 0, z: 0 });
  let scale = $state({ x: 1, y: 1, z: 1 });
  let isDragging = $state(false);
  let previousMousePosition = { x: 0, y: 0 };
  let lastTouchDistance = $state(0);
  let isPinching = $state(false);

  let transform = $derived({
    rotation,
    position,
    scale
  });

  // Watch for imageUrl changes and reload texture
  $effect(() => {
    if (!THREE || !imageUrl || !scene) {
      console.log('3D Effect skipped:', { hasTHREE: !!THREE, hasImageUrl: !!imageUrl, hasScene: !!scene });
      return;
    }
    console.log('3D Effect: Loading new texture', imageUrl);
    loadTexture(imageUrl);
  });
  
  function initializeScene() {
    if (!THREE) return;
    
    scene = new THREE.Scene();
    scene.background = new THREE.Color(0xf0f0f0);
    
    camera = new THREE.PerspectiveCamera(
      75,
      container.clientWidth / container.clientHeight,
      0.1,
      1000
    );
    camera.position.z = 5;
    
    renderer = new THREE.WebGLRenderer({ antialias: true });
    renderer.setSize(container.clientWidth, container.clientHeight);
    renderer.setPixelRatio(window.devicePixelRatio);
    container.appendChild(renderer.domElement);
    
    scene.add(new THREE.AmbientLight(0xffffff, 1.2));

    const gridHelper = new THREE.GridHelper(10, 10, 0xcccccc, 0xe0e0e0);
    scene.add(gridHelper);
  }
  
  function loadTexture(url) {
    if (!THREE) return;

    console.log('loadTexture called with:', url);

    // Clear previous mesh
    if (imageMesh) {
      scene.remove(imageMesh);
      imageMesh.geometry?.dispose();
      imageMesh.material?.dispose();
    }

    const textureLoader = new THREE.TextureLoader();
    textureLoader.load(
      url,
      (texture) => {
        console.log('Texture loaded successfully', texture.image);
        const geometry = new THREE.PlaneGeometry(3, 3 * texture.image.height / texture.image.width);
        const material = new THREE.MeshBasicMaterial({
          map: texture,
          side: THREE.DoubleSide
        });

        imageMesh = new THREE.Mesh(geometry, material);
        scene.add(imageMesh);
      },
      undefined,
      (error) => {
        console.error('Error loading texture:', error);
      }
    );
  }
  
  function setupEventListeners() {
    if (!renderer) return;

    const canvas = renderer.domElement;
    canvas.addEventListener('mousedown', onMouseDown);
    canvas.addEventListener('mousemove', onMouseMove);
    canvas.addEventListener('mouseup', onMouseUp);
    canvas.addEventListener('wheel', onMouseWheel);
    canvas.addEventListener('mouseleave', onMouseUp);
    canvas.addEventListener('contextmenu', (e) => e.preventDefault()); // Prevent right-click menu

    canvas.addEventListener('touchstart', onTouchStart, { passive: false });
    canvas.addEventListener('touchmove', onTouchMove, { passive: false });
    canvas.addEventListener('touchend', onTouchEnd);

    window.addEventListener('resize', onWindowResize);
  }
  
  function onMouseDown(event) {
    isDragging = true;
    previousMousePosition = { x: event.clientX, y: event.clientY };
    
    // Check if right-click for panning
    if (event.button === 2) {
      event.preventDefault();
    }
  }

  function onMouseMove(event) {
    if (!isDragging || !imageMesh) return;

    const deltaX = event.clientX - previousMousePosition.x;
    const deltaY = event.clientY - previousMousePosition.y;

    // Right-click for panning, left-click for rotation
    if (event.buttons === 2) {
      // Pan mode
      position = {
        x: position.x + deltaX * 0.01,
        y: position.y - deltaY * 0.01,
        z: position.z
      };
      imageMesh.position.set(position.x, position.y, position.z);
    } else {
      // Rotate mode (default)
      rotation = {
        x: rotation.x + deltaY * 0.01,
        y: rotation.y + deltaX * 0.01,
        z: rotation.z
      };
      imageMesh.rotation.x = rotation.x;
      imageMesh.rotation.y = rotation.y;
    }

    previousMousePosition = { x: event.clientX, y: event.clientY };
  }
  
  function onMouseUp() {
    isDragging = false;
  }
  
  function onMouseWheel(event) {
    if (!imageMesh) return;
    
    event.preventDefault();
    const zoomFactor = event.deltaY > 0 ? 0.95 : 1.05;
    
    scale = { 
      x: scale.x * zoomFactor,
      y: scale.y * zoomFactor,
      z: scale.z
    };
    
    if (imageMesh) {
      imageMesh.scale.set(scale.x, scale.y, scale.z);
    }
  }
  
  function onTouchStart(event) {
    if (event.touches.length === 1) {
      event.preventDefault();
      isDragging = true;
      isPinching = false;
      previousMousePosition = { x: event.touches[0].clientX, y: event.touches[0].clientY };
    } else if (event.touches.length === 2) {
      event.preventDefault();
      isDragging = false;
      isPinching = true;
      const dx = event.touches[0].clientX - event.touches[1].clientX;
      const dy = event.touches[0].clientY - event.touches[1].clientY;
      lastTouchDistance = Math.sqrt(dx * dx + dy * dy);
      
      // Store center point for two-finger pan
      previousMousePosition = {
        x: (event.touches[0].clientX + event.touches[1].clientX) / 2,
        y: (event.touches[0].clientY + event.touches[1].clientY) / 2
      };
    }
  }

  function onTouchMove(event) {
    if (!imageMesh) return;

    if (event.touches.length === 2 && isPinching) {
      event.preventDefault();
      const dx = event.touches[0].clientX - event.touches[1].clientX;
      const dy = event.touches[0].clientY - event.touches[1].clientY;
      const distance = Math.sqrt(dx * dx + dy * dy);
      
      // Two-finger pinch = zoom
      if (lastTouchDistance > 0) {
        const zoomFactor = distance / lastTouchDistance;
        scale = {
          x: scale.x * zoomFactor,
          y: scale.y * zoomFactor,
          z: scale.z
        };
        imageMesh.scale.set(scale.x, scale.y, scale.z);
      }
      lastTouchDistance = distance;
      
      // Two-finger drag = pan
      const centerX = (event.touches[0].clientX + event.touches[1].clientX) / 2;
      const centerY = (event.touches[0].clientY + event.touches[1].clientY) / 2;
      const deltaX = centerX - previousMousePosition.x;
      const deltaY = centerY - previousMousePosition.y;
      
      position = {
        x: position.x + deltaX * 0.01,
        y: position.y - deltaY * 0.01,
        z: position.z
      };
      imageMesh.position.set(position.x, position.y, position.z);
      
      previousMousePosition = { x: centerX, y: centerY };
      return;
    }

    if (!isDragging || event.touches.length !== 1 || !imageMesh) return;
    event.preventDefault();

    const deltaX = event.touches[0].clientX - previousMousePosition.x;
    const deltaY = event.touches[0].clientY - previousMousePosition.y;

    rotation = {
      x: rotation.x + deltaY * 0.01,
      y: rotation.y + deltaX * 0.01,
      z: rotation.z
    };

    if (imageMesh) {
      imageMesh.rotation.x = rotation.x;
      imageMesh.rotation.y = rotation.y;
    }

    previousMousePosition = { x: event.touches[0].clientX, y: event.touches[0].clientY };
  }
  
  function onTouchEnd() {
    isDragging = false;
    isPinching = false;
    lastTouchDistance = 0;
  }
  
  // FIXED: Prevents slider jumping
  function onWindowResize() {
    if (!camera || !renderer || !container || container.clientWidth === 0) return;
    
    const width = container.clientWidth;
    const height = container.clientHeight || 400;
    const currentSize = renderer.getSize(new THREE.Vector2());
    
    // Only resize if dimensions actually changed (prevents loops)
    if (Math.abs(width - currentSize.x) > 1 || Math.abs(height - currentSize.y) > 1) {
      camera.aspect = width / height;
      camera.updateProjectionMatrix();
      renderer.setSize(width, height);
    }
  }
  
  function animate() {
    if (!browser) return;
    requestAnimationFrame(animate);
    if (renderer && scene && camera) {
      renderer.render(scene, camera);
    }
  }
  
  function setRotation(x, y, z) {
    rotation = { x, y, z };
    if (imageMesh) {
      imageMesh.rotation.set(x, y, z);
    }
  }
  
  function setPosition(x, y, z) {
    position = { x, y, z };
    if (imageMesh) {
      imageMesh.position.set(x, y, z);
    }
  }
  
  function setScale(x, y, z) {
    scale = { x, y, z };
    if (imageMesh) {
      imageMesh.scale.set(x, y, z);
    }
  }
  
  function resetTransform() {
    rotation = { x: 0, y: 0, z: 0 };
    position = { x: 0, y: 0, z: 0 };
    scale = { x: 1, y: 1, z: 1 };
    
    if (imageMesh) {
      imageMesh.rotation.set(0, 0, 0);
      imageMesh.position.set(0, 0, 0);
      imageMesh.scale.set(1, 1, 1);
    }
  }
  
  let supportsAR = $state(false);
  let arActive = $state(false);

  async function startAR() {
    if (!THREE || !navigator.xr) return;
    try {
      const session = await navigator.xr.requestSession('immersive-ar', {
        requiredFeatures: ['hit-test'],
        optionalFeatures: ['dom-overlay'],
        domOverlay: { root: document.body }
      });
      arActive = true;

      const arRenderer = new THREE.WebGLRenderer({ alpha: true, antialias: true });
      arRenderer.setSize(window.innerWidth, window.innerHeight);
      arRenderer.setPixelRatio(window.devicePixelRatio);
      arRenderer.xr.enabled = true;
      document.body.appendChild(arRenderer.domElement);
      arRenderer.domElement.style.cssText = 'position:fixed;top:0;left:0;width:100%;height:100%;z-index:9999;';

      const arScene = new THREE.Scene();
      const arCamera = new THREE.PerspectiveCamera(75, window.innerWidth / window.innerHeight, 0.1, 1000);

      arScene.add(new THREE.AmbientLight(0xffffff, 1.5));
      arScene.add(new THREE.DirectionalLight(0xffffff, 0.8));

      // Load artwork as AR plane
      const textureLoader = new THREE.TextureLoader();
      const texture = await new Promise((res, rej) => textureLoader.load(imageUrl, res, undefined, rej));
      const aspect = texture.image.height / texture.image.width;
      const geo = new THREE.PlaneGeometry(0.5, 0.5 * aspect);
      const mat = new THREE.MeshBasicMaterial({ map: texture, side: THREE.DoubleSide, transparent: true });
      const arMesh = new THREE.Mesh(geo, mat);
      arScene.add(arMesh);

      // Hit test reticle
      const reticleGeo = new THREE.RingGeometry(0.03, 0.05, 32);
      reticleGeo.rotateX(-Math.PI / 2);
      const reticleMat = new THREE.MeshBasicMaterial({ color: 0x333333 });
      const reticle = new THREE.Mesh(reticleGeo, reticleMat);
      reticle.matrixAutoUpdate = false;
      reticle.visible = false;
      arScene.add(reticle);

      const viewerSpace = await session.requestReferenceSpace('viewer');
      const hitTestSource = await session.requestHitTestSource({ space: viewerSpace });
      const localSpace = await session.requestReferenceSpace('local-floor');

      arRenderer.xr.setReferenceSpace(localSpace);
      arRenderer.xr.setSession(session);

      let hitPose = null;
      session.addEventListener('xr-frame', (event) => {
        const frame = event.frame;
        const results = frame.getHitTestResults(hitTestSource);
        if (results.length > 0) {
          const refSpace = arRenderer.xr.getReferenceSpace();
          hitPose = results[0].getPose(refSpace);
          reticle.visible = true;
          reticle.matrix.fromArray(hitPose.transform.matrix);
        } else {
          reticle.visible = false;
          hitPose = null;
        }
      });

      arRenderer.setAnimationLoop(() => {
        if (hitPose && !arMesh.userData.placed) {
          arMesh.matrix.fromArray(hitPose.transform.matrix);
          arMesh.userData.placed = true;
        }
        arRenderer.render(arScene, arCamera);
      });

      // Close button overlay
      const closeBtn = document.createElement('button');
      closeBtn.textContent = '✕ Cerrar AR';
      closeBtn.style.cssText = 'position:fixed;top:20px;right:20px;z-index:10000;background:rgba(0,0,0,0.7);color:#fff;border:none;padding:12px 20px;border-radius:8px;font-size:16px;cursor:pointer;';
      closeBtn.onclick = async () => {
        await session.end();
        arRenderer.domElement.remove();
        closeBtn.remove();
        arRenderer.dispose();
        arActive = false;
      };
      document.body.appendChild(closeBtn);

      session.addEventListener('end', () => {
        arRenderer.setAnimationLoop(null);
        arRenderer.domElement.remove();
        closeBtn.remove();
        arRenderer.dispose();
        arActive = false;
      });
    } catch (e) {
      console.error('[AR] Failed:', e);
      arActive = false;
      alert('No se pudo iniciar AR: ' + e.message);
    }
  }

  onMount(async () => {
    if (!browser) return;
    
    try {
      console.log('[3D] Loading Three.js...');
      THREE = await import('three');
      console.log('[3D] Three.js loaded:', !!THREE);
      initializeScene();
      console.log('[3D] Scene initialized:', !!scene);
      loadTexture(imageUrl);
      console.log('[3D] Texture loading for:', imageUrl);
      setupEventListeners();
      animate();
      console.log('[3D] Animation started');

      // Check AR support
      if (navigator.xr) {
        supportsAR = await navigator.xr.isSessionSupported('immersive-ar');
        console.log('[3D] AR support:', supportsAR);
      }
    } catch (e) {
      console.error('[3D] Setup failed:', e);
    }
    
    // FIXED: ResizeObserver with throttling prevents slider jumping
    let resizeTimeout;
    resizeObserver = new ResizeObserver(() => {
      clearTimeout(resizeTimeout);
      resizeTimeout = setTimeout(onWindowResize, 100);
    });
    resizeObserver.observe(container);
  });
  
  onDestroy(() => {
    if (browser && window) {
      window.removeEventListener('resize', onWindowResize);
    }
    if (resizeObserver) {
      resizeObserver.disconnect();
    }
    if (renderer) {
      renderer.dispose();
    }
  });
  
  let methods = {
    get transform() {
      return transform;
    },
    setRotation,
    setPosition,
    setScale,
    resetTransform
  };
</script>

{#if browser}
  <div class="image-3d-wrapper">
    <div class="image-3d-container" bind:this={container}></div>
    {#if supportsAR && !arActive}
      <button class="ar-button" onclick={startAR}>
        🥽 Ver en AR
      </button>
    {/if}
  </div>
{:else}
  <div class="image-3d-container loading">
    <p>Loading 3D viewer...</p>
  </div>
{/if}

<style>
  .image-3d-container {
    width: 100%;
    height: 100%;
    position: relative;
    overflow: hidden;
    min-height: 400px; /* Prevents collapse */
  }
  
  @media (max-width: 768px) {
    .image-3d-container {
      min-height: 300px;
    }
  }
  
  .loading {
    display: flex;
    align-items: center;
    justify-content: center;
    background: #f0f0f0;
    min-height: 400px;
  }
  
  .image-3d-wrapper {
    position: relative;
  }

  .ar-button {
    position: absolute;
    bottom: 16px;
    right: 16px;
    background: #c9a87c;
    color: #09090b;
    border: none;
    padding: 10px 18px;
    border-radius: 8px;
    font-size: 14px;
    font-weight: 600;
    cursor: pointer;
    z-index: 10;
    transition: opacity 0.2s;
  }
  .ar-button:hover { opacity: 0.85; }

  :global(canvas) {
    display: block;
    width: 100% !important;
    height: 100% !important;
    touch-action: none;
    position: relative !important;
    z-index: 1 !important;
  }
</style>

