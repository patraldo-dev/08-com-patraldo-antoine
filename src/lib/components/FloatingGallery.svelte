<!-- src/lib/components/FloatingGallery.svelte -->
<script>
  import { onMount, onDestroy } from 'svelte';
  import { browser } from '$app/environment';
  import { CF_IMAGES_ACCOUNT_HASH } from '$lib/config.js';
  import { t } from '$lib/i18n';

  let { artworks = [] } = $props();

  const GALLERY_ARTWORK_IDS = [
    '12c79899-fb93-4885-508f-d2da0a2fbf00', // Hans
    'bd4602b0-149d-42f8-e872-f697b64c7d00', // Barzango
    '5c7fb409-1aa2-45a9-8466-296077e18e00', // Alena la Alien
    'f8a136eb-363e-4a24-0f54-70bb4f4bf800', // Mujer
  ];

  const GALLERY_IDS = artworks
    .filter(a => GALLERY_ARTWORK_IDS.includes(a.image_id))
    .map(a => ({ id: a.image_id, title: a.display_name || a.title }));

  function segmentUrl(imageId, width = 500) {
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
    const angle = ((i / (n - 1)) - 0.5) * Math.PI * 0.7;
    return {
      angle,
      radius: 2.8,
      rotSpeed: 0.0005 + Math.random() * 0.0008,
      bobSpeed: 0.3 + Math.random() * 0.3,
      bobAmp: 0.06 + Math.random() * 0.06,
      baseY: 0,
    };
  });

  onMount(async () => {
    if (!browser || GALLERY_IDS.length === 0) return;

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

    const isMobile = container.clientWidth < 768;

    scene = new THREE.Scene();
    scene.background = new THREE.Color(0x0a0a0a);
    scene.fog = new THREE.Fog(0x0a0a0a, 8, 18);

    camera = new THREE.PerspectiveCamera(45, container.clientWidth / container.clientHeight, 0.1, 100);
    camera.position.set(0, 0.3, isMobile ? 6 : 5);

    renderer = new THREE.WebGLRenderer({ antialias: true, alpha: false });
    renderer.setSize(container.clientWidth, container.clientHeight);
    renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
    // CRITICAL: allow vertical scroll to pass through
    renderer.domElement.style.touchAction = 'pan-y';
    container.appendChild(renderer.domElement);

    scene.add(new THREE.AmbientLight(0xffffff, 1));
    const warm = new THREE.PointLight(0xd4c9a8, 1.2, 15);
    warm.position.set(3, 3, 3);
    scene.add(warm);

    const loader = new THREE.TextureLoader();
    loader.crossOrigin = 'anonymous';

    const planeSize = isMobile ? 1.6 : 2.4;

    for (let i = 0; i < GALLERY_IDS.length; i++) {
      const art = GALLERY_IDS[i];
      const url = segmentUrl(art.id, isMobile ? 350 : 500);
      const placement = placements[i];

      loader.load(url, (texture) => {
        texture.colorSpace = THREE.SRGBColorSpace;
        const aspect = texture.image.height / texture.image.width;
        const planeH = planeSize * aspect;
        const geometry = new THREE.PlaneGeometry(planeSize, planeH);
        const material = new THREE.MeshBasicMaterial({
          map: texture,
          transparent: true,
          side: THREE.DoubleSide,
        });

        const mesh = new THREE.Mesh(geometry, material);
        const px = Math.sin(placement.angle) * placement.radius;
        const pz = Math.cos(placement.angle) * placement.radius - placement.radius;
        mesh.position.set(px, placement.baseY, pz);
        mesh.lookAt(0, mesh.position.y, camera.position.z);
        mesh.userData = { index: i, title: art.title, ...placement };

        scene.add(mesh);
        meshes.push(mesh);
      });
    }

    // Particles
    const particleCount = 60;
    const positions = new Float32Array(particleCount * 3);
    for (let i = 0; i < particleCount * 3; i++) {
      positions[i] = (Math.random() - 0.5) * 14;
    }
    const particleGeom = new THREE.BufferGeometry();
    particleGeom.setAttribute('position', new THREE.BufferAttribute(positions, 3));
    const particleMat = new THREE.PointsMaterial({ color: 0xd4c9a8, size: 0.02, transparent: true, opacity: 0.3 });
    scene.add(new THREE.Points(particleGeom, particleMat));

    // Only mouse parallax on desktop — no touch listeners at all
    container.addEventListener('mousemove', onMouseMove);
    window.addEventListener('resize', onResize);

    animate();
  }

  function onMouseMove(e) {
    const rect = container.getBoundingClientRect();
    mouseX = ((e.clientX - rect.left) / rect.width - 0.5) * 2;
    mouseY = ((e.clientY - rect.top) / rect.height - 0.5) * 2;
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
      camera.position.x += (mouseX * 0.8 - camera.position.x) * 0.02;
      camera.position.y += (0.3 - mouseY * 0.3 - camera.position.y) * 0.02;
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
    <h2 class="gallery-title">{$t('floatingGallery.title')}</h2>
    <p class="gallery-subtitle">{$t('floatingGallery.subtitle')}</p>
  </div>
</div>

<style>
  .floating-gallery {
    width: 100%;
    height: 60vh;
    min-height: 350px;
    position: relative;
    overflow: hidden;
    background: #0a0a0a;
  }

  .gallery-overlay {
    position: absolute;
    bottom: 1.5rem;
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
    touch-action: pan-y !important;
  }

  @media (max-width: 768px) {
    .floating-gallery {
      height: 45vh;
      min-height: 280px;
    }
    .gallery-title {
      font-size: 1.1rem;
    }
  }
</style>
