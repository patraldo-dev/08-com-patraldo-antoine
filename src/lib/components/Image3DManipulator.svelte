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
  
  let rotation = $state({ x: 0, y: 0, z: 0 });
  let position = $state({ x: 0, y: 0, z: 0 });
  let scale = $state({ x: 1, y: 1, z: 1 });
  let isDragging = $state(false);
  let previousMousePosition = { x: 0, y: 0 };
  
  let transform = $derived({
    rotation,
    position,
    scale
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
    
    const textureLoader = new THREE.TextureLoader();
    textureLoader.load(
      url,
      (texture) => {
      texture.minFilter = THREE.LinearFilter;
      texture.magFilter = THREE.LinearFilter;
      texture.needsUpdate = true;
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
    
    canvas.addEventListener('touchstart', onTouchStart, { passive: false });
    canvas.addEventListener('touchmove', onTouchMove, { passive: false });
    canvas.addEventListener('touchend', onTouchEnd);
    
    window.addEventListener('resize', onWindowResize);
  }
  
  function onMouseDown(event) {
    isDragging = true;
    previousMousePosition = { x: event.clientX, y: event.clientY };
  }
  
  function onMouseMove(event) {
    if (!isDragging || !imageMesh) return;
    
    const deltaX = event.clientX - previousMousePosition.x;
    const deltaY = event.clientY - previousMousePosition.y;
    
    rotation = { 
      x: rotation.x + deltaY * 0.01,
      y: rotation.y + deltaX * 0.01,
      z: rotation.z
    };
    
    if (imageMesh) {
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
      previousMousePosition = { x: event.touches[0].clientX, y: event.touches[0].clientY };
    }
  }
  
  function onTouchMove(event) {
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
  }
  
  function onWindowResize() {
    if (!camera || !renderer || !container) return;
    
    camera.aspect = container.clientWidth / container.clientHeight;
    camera.updateProjectionMatrix();
    renderer.setSize(container.clientWidth, container.clientHeight);
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
  
  onMount(async () => {
    if (!browser) return;
    
    // Dynamically import Three.js only on the client
    THREE = await import('three');
    
    initializeScene();
    loadTexture(imageUrl);
    animate();
    setupEventListeners();
  });

onDestroy(() => {
  if (browser && window) {
    window.removeEventListener('resize', onWindowResize);
  }
  if (renderer) {
    // FULL texture cleanup to fix immutable warnings
    if (imageMesh && imageMesh.material) {
      if (imageMesh.material.map) {
        imageMesh.material.map.dispose();
      }
      imageMesh.material.dispose();
    }
    if (imageMesh && imageMesh.geometry) {
      imageMesh.geometry.dispose();
    }
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
  <div class="image-3d-container" bind:this={container}></div>
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
  }
  
  .loading {
    display: flex;
    align-items: center;
    justify-content: center;
    background: #f0f0f0;
  }
  
  :global(canvas) {
    display: block;
    width: 100% !important;
    height: 100% !important;
    touch-action: none;
  }
</style>
