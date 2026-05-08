<!-- src/lib/components/FloatingGallery.svelte -->
<script>
  import { onMount, onDestroy } from 'svelte';
  import { browser } from '$app/environment';
  import { CF_IMAGES_ACCOUNT_HASH } from '$lib/config.js';

  let { artworks = [] } = $props();

  // Pick artworks with white/light backgrounds (best for segment=foreground)
  const GALLERY_IDS = artworks.map(a => ({
    id: a.image_id,
    title: a.display_name || a.title,
  }));

  function segmentUrl(imageId, width = 400) {
    return `https://imagedelivery.net/${CF_IMAGES_ACCOUNT_HASH}/${imageId}/segment=foreground,width=${width}`;
  }

  let container;
  let THREE;
  let scene, camera, renderer;
  let meshes = [];
  let animationId;
  let mouseX = 0, mouseY = 0;
  let isVisible = false;

  const placements = GALLERY_IDS.map((_, i) => {
    const n = GALLERY_IDS.length;
    const angle = ((i / (n - 1)) - 0.5) * Math.PI * 0.6;
    return {
      angle,
      radius: 4,
      rotSpeed: 0.0006 + Math.random() * 0.001,
      bobSpeed: 0.3 + Math.random() * 0.3,
      bobAmp: 0.08 + Math.random() * 0.08,
      baseY: 0,
    };
  });

  onMount(async () => {
    if (!browser || GALLERY_IDS.length === 0) return;

    // Intersection observer — only render when visible
    const observer = new IntersectionObserver(([entry]) => {
      if (entry.isIntersecting && !isVisible) {
        isVisible = true;
        initScene();
      }
    }, { threshold: 0.1 });
    observer.observe(container);

    return () => observer.disconnect();
  });

  async function initScene() {
    THREE = await import('three');

    scene = new THREE.Scene();
    scene.background = new THREE.Color(0x0a0a0a);
    scene.fog = new THREE.Fog(0x0a0a0a, 10, 22);

    camera = new THREE.PerspectiveCamera(50, container.clientWidth / container.clientHeight, 0.1, 100);
    camera.position.set(0, 0.5, 7);

    renderer = new THREE.WebGLRenderer({ antialias: true, alpha: false });
    renderer.setSize(container.clientWidth, container.clientHeight);
    renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
    container.appendChild(renderer.domElement);

    // Lights
    scene.add(new THREE.AmbientLight(0xffffff, 1));
    const warm = new THREE.PointLight(0xd4c9a8, 1.2, 15);
    warm.position.set(3, 3, 3);
    scene.add(warm);

    const loader = new THREE.TextureLoader();
    loader.crossOrigin = 'anonymous';

    for (let i = 0; i < GALLERY_IDS.length; i++) {
      const art = GALLERY_IDS[i];
      const url = segmentUrl(art.id, 400);
      const placement = placements[i];

      loader.load(url, (texture) => {
        texture.colorSpace = THREE.SRGBColorSpace;
        const aspect = texture.image.height / texture.image.width;
        const planeH = 1.8 * aspect;
        const geometry = new THREE.PlaneGeometry(1.8, planeH);
        const material = new THREE.MeshBasicMaterial({
          map: texture,
          transparent: true,
          side: THREE.DoubleSide,
        });

        const mesh = new THREE.Mesh(geometry, material);
        const px = Math.sin(placement.angle) * placement.radius;
        const pz = Math.cos(placement.angle) * placement.radius - placement.radius;
        mesh.position.set(px, placement.baseY, pz);
        mesh.lookAt(0, mesh.position.y, 7);
        mesh.userData = { index: i, title: art.title, ...placement };

        scene.add(mesh);
        meshes.push(mesh);
      });
    }

    // Particles
    const particleCount = 80;
    const positions = new Float32Array(particleCount * 3);
    for (let i = 0; i < particleCount * 3; i++) {
      positions[i] = (Math.random() - 0.5) * 16;
    }
    const particleGeom = new THREE.BufferGeometry();
    particleGeom.setAttribute('position', new THREE.BufferAttribute(positions, 3));
    const particleMat = new THREE.PointsMaterial({ color: 0xd4c9a8, size: 0.03, transparent: true, opacity: 0.4 });
    scene.add(new THREE.Points(particleGeom, particleMat));

    container.addEventListener('mousemove', onMouseMove);
    container.addEventListener('touchmove', onTouchMove, { passive: true });
    window.addEventListener('resize', onResize);

    animate();
  }

  function onMouseMove(e) {
    const rect = container.getBoundingClientRect();
    mouseX = ((e.clientX - rect.left) / rect.width - 0.5) * 2;
    mouseY = ((e.clientY - rect.top) / rect.height - 0.5) * 2;
  }

  function onTouchMove(e) {
    if (e.touches.length === 1) {
      const rect = container.getBoundingClientRect();
      mouseX = ((e.touches[0].clientX - rect.left) / rect.width - 0.5) * 2;
      mouseY = ((e.touches[0].clientY - rect.top) / rect.height - 0.5) * 2;
    }
  }

  function onResize() {
    if (!camera || !renderer || !container) return;
    camera.aspect = container.clientWidth / container.clientHeight;
    camera.updateProjectionMatrix();
    renderer.setSize(container.clientWidth, container.clientHeight);
  }

  function animate() {
    if (!browser) return;
    animationId = requestAnimationFrame(animate);
    const time = performance.now() * 0.001;

    if (camera) {
      camera.position.x += (mouseX * 1.2 - camera.position.x) * 0.02;
      camera.position.y += (0.5 - mouseY * 0.4 - camera.position.y) * 0.02;
      camera.lookAt(0, 0, 0);
    }

    for (const mesh of meshes) {
      const d = mesh.userData;
      mesh.position.y = d.baseY + Math.sin(time * d.bobSpeed) * d.bobAmp;
      mesh.rotation.y += d.rotSpeed;
    }

    if (renderer && scene && camera) renderer.render(scene, camera);
  }

  onDestroy(() => {
    if (animationId) cancelAnimationFrame(animationId);
    if (browser) {
      window.removeEventListener('resize', onResize);
    }
    if (renderer) renderer.dispose();
    for (const m of meshes) {
      m.geometry?.dispose();
      m.material?.dispose();
    }
  });
</script>

<div class="floating-gallery" bind:this={container}>
  <div class="gallery-overlay">
    <h2 class="gallery-title">Floating Gallery</h2>
    <p class="gallery-subtitle">Move to explore</p>
  </div>
</div>

<style>
  .floating-gallery {
    width: 100%;
    height: 70vh;
    min-height: 400px;
    position: relative;
    overflow: hidden;
    background: #0a0a0a;
    cursor: grab;
  }

  .floating-gallery:active {
    cursor: grabbing;
  }

  .gallery-overlay {
    position: absolute;
    bottom: 2rem;
    left: 50%;
    transform: translateX(-50%);
    text-align: center;
    z-index: 10;
    pointer-events: none;
  }

  .gallery-title {
    font-family: 'Georgia', serif;
    font-size: 1.4rem;
    font-weight: 200;
    color: #d4c9a8;
    margin: 0 0 0.25rem;
    letter-spacing: 0.05em;
  }

  .gallery-subtitle {
    font-size: 0.75rem;
    color: rgba(212, 201, 168, 0.4);
    margin: 0;
    animation: pulse 2.5s ease-in-out infinite;
  }

  @keyframes pulse {
    0%, 100% { opacity: 0.3; }
    50% { opacity: 0.7; }
  }

  :global(.floating-gallery canvas) {
    display: block;
    width: 100% !important;
    height: 100% !important;
  }

  @media (max-width: 768px) {
    .floating-gallery {
      height: 50vh;
      min-height: 300px;
    }
    .gallery-title {
      font-size: 1.1rem;
    }
  }
</style>
