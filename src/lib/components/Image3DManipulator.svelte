<script>
  import { onMount, onDestroy } from 'svelte';
  import * as THREE from 'three';

  /**
   * The URL of the image to manipulate in 3D space
   * @type {string}
   */
  let { imageUrl } = $props();

  /**
   * DOM reference for the Three.js container
   * @type {HTMLDivElement}
   */
  let container;

  /**
   * Three.js scene object
   * @type {THREE.Scene}
   */
  let scene;

  /**
   * Three.js camera object
   * @type {THREE.PerspectiveCamera}
   */
  let camera;

  /**
   * Three.js renderer object
   * @type {THREE.WebGLRenderer}
   */
  let renderer;

  /**
   * Mesh containing the image texture
   * @type {THREE.Mesh}
   */
  let imageMesh;

  /**
   * Current rotation state
   * @type {{x: number, y: number, z: number}}
   */
  let rotation = $state({ x: 0, y: 0, z: 0 });

  /**
   * Current position state
   * @type {{x: number, y: number, z: number}}
   */
  let position = $state({ x: 0, y: 0, z: 0 });

  /**
   * Current scale state
   * @type {{x: number, y: number, z: number}}
   */
  let scale = $state({ x: 1, y: 1, z: 1 });

  /**
   * Whether the user is currently dragging
   * @type {boolean}
   */
  let isDragging = $state(false);

  /**
   * Previous mouse position for drag calculations
   * @type {{x: number, y: number}}
   */
  let previousMousePosition = { x: 0, y: 0 };

  /**
   * Derived transform object for external access
   * @type {{rotation: {x: number, y: number, z: number}, position: {x: number, y: number, z: number}, scale: {x: number, y: number, z: number}}}
   */
  let transform = $derived({
    rotation,
    position,
    scale
  });

  /**
   * Initialize the Three.js scene, camera, and renderer
   */
  function initializeScene() {
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

    // Add lighting
    const ambientLight = new THREE.AmbientLight(0xffffff, 0.5);
    scene.add(ambientLight);

    const directionalLight = new THREE.DirectionalLight(0xffffff, 0.8);
    directionalLight.position.set(1, 1, 1);
    scene.add(directionalLight);

    // Add grid helper
    const gridHelper = new THREE.GridHelper(10, 10, 0xcccccc, 0xe0e0e0);
    scene.add(gridHelper);
  }

  /**
   * Load an image as a texture onto a plane geometry
   * @param {string} url - The URL of the image to load
   */
  function loadTexture(url) {
    const textureLoader = new THREE.TextureLoader();

    textureLoader.load(
      url,
      (texture) => {
        const geometry = new THREE.PlaneGeometry(3, 3 * texture.image.height / texture.image.width);
        const material = new THREE.MeshStandardMaterial({
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

  /**
   * Set up mouse and touch event listeners for manipulation
   */
  function setupEventListeners() {
    const canvas = renderer.domElement;

    canvas.addEventListener('mousedown', onMouseDown);
    canvas.addEventListener('mousemove', onMouseMove);
    canvas.addEventListener('mouseup', onMouseUp);
    canvas.addEventListener('wheel', onMouseWheel);
    canvas.addEventListener('mouseleave', onMouseUp);

    // Touch events for mobile
    canvas.addEventListener('touchstart', onTouchStart, { passive: false });
    canvas.addEventListener('touchmove', onTouchMove, { passive: false });
    canvas.addEventListener('touchend', onTouchEnd);

    window.addEventListener('resize', onWindowResize);
  }

  /**
   * Handle mouse down event - start dragging
   * @param {MouseEvent} event - The mouse event
   */
  function onMouseDown(event) {
    isDragging = true;
    previousMousePosition = { x: event.clientX, y: event.clientY };
  }

  /**
   * Handle mouse move event - rotate image if dragging
   * @param {MouseEvent} event - The mouse event
   */
  function onMouseMove(event) {
    if (!isDragging || !imageMesh) return;

    const deltaX = event.clientX - previousMousePosition.x;
    const deltaY = event.clientY - previousMousePosition.y;

    rotation.y += deltaX * 0.01;
    rotation.x += deltaY * 0.01;

    imageMesh.rotation.x = rotation.x;
    imageMesh.rotation.y = rotation.y;

    previousMousePosition = { x: event.clientX, y: event.clientY };
  }

  /**
   * Handle mouse up event - stop dragging
   */
  function onMouseUp() {
    isDragging = false;
  }

  /**
   * Handle mouse wheel event - zoom in/out
   * @param {WheelEvent} event - The wheel event
   */
  function onMouseWheel(event) {
    if (!imageMesh) return;

    event.preventDefault();

    const zoomFactor = event.deltaY > 0 ? 0.95 : 1.05;
    scale.x *= zoomFactor;
    scale.y *= zoomFactor;

    imageMesh.scale.set(scale.x, scale.y, scale.z);
  }

  /**
   * Handle touch start event - start dragging on mobile
   * @param {TouchEvent} event - The touch event
   */
  function onTouchStart(event) {
    if (event.touches.length === 1) {
      event.preventDefault();
      isDragging = true;
      previousMousePosition = {
        x: event.touches[0].clientX,
        y: event.touches[0].clientY
      };
    }
  }

  /**
   * Handle touch move event - rotate image on mobile
   * @param {TouchEvent} event - The touch event
   */
  function onTouchMove(event) {
    if (!isDragging || event.touches.length !== 1 || !imageMesh) return;

    event.preventDefault();

    const deltaX = event.touches[0].clientX - previousMousePosition.x;
    const deltaY = event.touches[0].clientY - previousMousePosition.y;

    rotation.y += deltaX * 0.01;
    rotation.x += deltaY * 0.01;

    imageMesh.rotation.x = rotation.x;
    imageMesh.rotation.y = rotation.y;

    previousMousePosition = {
      x: event.touches[0].clientX,
      y: event.touches[0].clientY
    };
  }

  /**
   * Handle touch end event - stop dragging on mobile
   */
  function onTouchEnd() {
    isDragging = false;
  }

  /**
   * Handle window resize event - update camera and renderer
   */
  function onWindowResize() {
    if (!camera || !renderer || !container) return;

    camera.aspect = container.clientWidth / container.clientHeight;
    camera.updateProjectionMatrix();
    renderer.setSize(container.clientWidth, container.clientHeight);
  }

  /**
   * Animation loop - render the scene continuously
   */
  function animate() {
    requestAnimationFrame(animate);
    if (renderer && scene && camera) {
      renderer.render(scene, camera);
    }
  }

  /**
   * Set rotation values programmatically
   * @param {number} x - Rotation around X axis
   * @param {number} y - Rotation around Y axis
   * @param {number} z - Rotation around Z axis
   */
  function setRotation(x, y, z) {
    rotation.x = x;
    rotation.y = y;
    rotation.z = z;

    if (imageMesh) {
      imageMesh.rotation.set(x, y, z);
    }
  }

  /**
   * Set position values programmatically
   * @param {number} x - X position
   * @param {number} y - Y position
   * @param {number} z - Z position
   */
  function setPosition(x, y, z) {
    position.x = x;
    position.y = y;
    position.z = z;

    if (imageMesh) {
      imageMesh.position.set(x, y, z);
    }
  }

  /**
   * Set scale values programmatically
   * @param {number} x - X scale
   * @param {number} y - Y scale
   * @param {number} z - Z scale
   */
  function setScale(x, y, z) {
    scale.x = x;
    scale.y = y;
    scale.z = z;

    if (imageMesh) {
      imageMesh.scale.set(x, y, z);
    }
  }

  /**
   * Reset all transformations to default values
   */
  function resetTransform() {
    setRotation(0, 0, 0);
    setPosition(0, 0, 0);
    setScale(1, 1, 1);
  }

  /**
   * Initialize component on mount
   */
  onMount(async () => {
    initializeScene();
    loadTexture(imageUrl);
    animate();
    setupEventListeners();
  });

  /**
   * Clean up on unmount
   */
  onDestroy(() => {
    window.removeEventListener('resize', onWindowResize);
    if (renderer) {
      renderer.dispose();
    }
  });

  /**
   * Expose methods to parent component
   */
  let exposed = {
    get transform() {
      return transform;
    },
    setRotation,
    setPosition,
    setScale,
    resetTransform
  };

  defineExpose(exposed);
</script>

<div class="image-3d-container" bind:this={container}>
  {@render children?.()}
</div>

<style>
  .image-3d-container {
    width: 100%;
    height: 100%;
    position: relative;
    overflow: hidden;
  }

  :global(canvas) {
    display: block;
    width: 100% !important;
    height: 100% !important;
    touch-action: none;
  }
</style>
