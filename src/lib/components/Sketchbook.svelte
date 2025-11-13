<!-- src/lib/components/Sketchbook.svelte -->
<script>
  import { onMount, onDestroy } from 'svelte';
  import Matter from 'matter-js';
  // ❌ Import locale correctly from your translations file
  import { locale, t } from '$lib/translations'; // Assumes your translations file is at src/lib/translations.js
  import ArtPiece from './ArtPiece.svelte';

  // Props
  export let artworks = [];
  // Remove hardcoded maxPages
  // export let maxPages = 6;

  // State
  let currentPage = 0;
  let selectedImage = null;
  let isDragging = false;
  let dragProgress = 0; // 0 to 1, how far the page has been dragged

  // DOM refs
  let sketchbookContainer;
  let pageRightEl; // Reference for the right page being flipped
  let pageLeftEl;  // Reference for the left page (for potential backward flip)
  let canvasEl;

  // Matter.js
  let engine;
  let runner;
  let render;
  let mouse;
  let mouseConstraint;
  let pageCornerBody;
  let pagePivot;

  // Preload sounds
  let flipSound;
  let selectSound;
  let dragSound;

  // i18n
  $: promptText = getPromptText($locale);

  function getPromptText(currentLocale) {
    const prompts = {
      'es-MX': 'Un dibujo cada día. Una historia cada semana.',
      'en-US': 'A drawing each day. A story each week.',
      'fr-CA': 'Un dessin chaque jour. Une histoire chaque semaine.'
    };
    return prompts[currentLocale] || prompts['es-MX'];
  }

  onMount(async () => {
    // Preload sounds
    try {
      flipSound = new Audio('/sounds/page-flip.mp3');
      flipSound.volume = 0.3;

      selectSound = new Audio('/sounds/select.mp3');
      selectSound.volume = 0.2;

      dragSound = new Audio('/sounds/paper-rustle.mp3');
      dragSound.volume = 0.15;
      dragSound.loop = true;
    } catch (e) {
      console.log('Audio not available');
    }

    if (sketchbookContainer) {
      initPhysics();
    }
  });

  function initPhysics() {
    if (!sketchbookContainer) return; // Guard clause
    const containerRect = sketchbookContainer.getBoundingClientRect();
    const width = containerRect.width;
    const height = 500; // Match .sketchbook height

    // Create engine
    engine = Matter.Engine.create();
    engine.gravity.y = 0.3; // Subtle gravity for natural droop

    // Create renderer (invisible, just for physics debugging if needed)
    // You can set `visible: false` in production
    render = Matter.Render.create({
      element: sketchbookContainer,
      engine: engine,
      canvas: canvasEl,
      options: {
        width: width,
        height: height,
        wireframes: false,
        background: 'transparent',
        pixelRatio: window.devicePixelRatio
      }
    });

    // Page corner that user can drag (top-right of right page for forward flip)
    const cornerX = width * 0.75; // Right side of right page
    const cornerY = height * 0.15; // Near top

    pageCornerBody = Matter.Bodies.circle(cornerX, cornerY, 30, {
      density: 0.001,
      frictionAir: 0.02,
      restitution: 0.3,
      render: {
        fillStyle: 'rgba(212, 201, 168, 0.3)', // Semi-transparent for visibility
        strokeStyle: '#d4c9a8',
        lineWidth: 2
      },
      label: 'pageCorner'
    });

    // Pivot point (spine of the book - left edge of right page)
    pagePivot = Matter.Bodies.circle(width / 2, height / 2, 5, {
      isStatic: true,
      render: { visible: false }
    });

    // Constraint connecting corner to pivot (like a hinge)
    const pageConstraint = Matter.Constraint.create({
      bodyA: pagePivot,
      bodyB: pageCornerBody,
      stiffness: 0.008,
      damping: 0.05,
      length: Math.hypot(cornerX - width/2, cornerY - height/2),
      render: { visible: false }
    });

    // Add mouse control
    mouse = Matter.Mouse.create(render.canvas);
    mouseConstraint = Matter.MouseConstraint.create(engine, {
      mouse: mouse,
      constraint: {
        stiffness: 0.2,
        render: { visible: false }
      }
    });

    // Detect drag events for forward flip
    Matter.Events.on(mouseConstraint, 'startdrag', (event) => {
      if (event.body === pageCornerBody) {
        isDragging = true;
        if (dragSound && dragSound.paused) {
          dragSound.play().catch(() => {});
        }
      }
    });

    Matter.Events.on(mouseConstraint, 'enddrag', (event) => {
      if (event.body === pageCornerBody) {
        isDragging = false;
        if (dragSound) {
          dragSound.pause();
          dragSound.currentTime = 0;
        }

        // Check if dragged far enough to flip forward
        const dragDistance = width / 2 - pageCornerBody.position.x;
        if (dragDistance > width * 0.25) { // Dragged past 25% threshold
          completePage('forward');
        } else {
          // Reset if not dragged far enough (optional)
          // Matter.Body.setPosition(pageCornerBody, { x: cornerX, y: cornerY });
        }
      }
    });

    // Add to world
    Matter.World.add(engine.world, [pageCornerBody, pagePivot, pageConstraint, mouseConstraint]);

    // Run engine
    runner = Matter.Runner.create();
    Matter.Runner.run(runner, engine);
    Matter.Render.run(render);

    // Update loop to sync DOM with physics for the RIGHT page (forward flip)
    const updateLoop = () => {
      if (!pageRightEl || !pageCornerBody || !sketchbookContainer) return;

      const rect = sketchbookContainer.getBoundingClientRect();
      const currentWidth = rect.width;
      const currentHeight = 500; // Assuming height is fixed

      // Calculate drag progress based on corner position relative to current width
      const cornerX = pageCornerBody.position.x;
      const maxDrag = currentWidth / 2; // Full flip distance
      const currentDrag = Math.max(0, (currentWidth * 0.75) - cornerX);
      dragProgress = Math.min(1, currentDrag / maxDrag);

      // Apply transform to RIGHT page element
      const rotateY = dragProgress * -180;
      pageRightEl.style.transform = `rotateY(${rotateY}deg)`;
      pageRightEl.style.boxShadow = `0 0 ${20 * dragProgress}px rgba(0,0,0,${0.4 * dragProgress})`;

      requestAnimationFrame(updateLoop);
    };
    updateLoop();
  }

  function completePage(direction) { // Accept direction parameter
    let targetPage = currentPage;
    // Calculate total pages based on artworks length
    const totalPages = artworks.length;

    if (direction === 'forward') {
      if (currentPage < totalPages - 1) { // Check against actual length
        targetPage = currentPage + 1;
      } else {
        return; // Already on the last page, do nothing
      }
    } else if (direction === 'backward') {
      if (currentPage > 0) {
        targetPage = currentPage - 1;
      } else {
        return; // Already on the first page, do nothing
      }
    } else {
      return; // Invalid direction
    }

    // Play flip sound
    if (flipSound) {
      flipSound.currentTime = 0;
      flipSound.play().catch(() => {});
    }

    // Determine which page is being flipped based on direction
    // For simplicity, assume right page flips for both directions here,
    // but the visual effect might need adjustment for backward.
    // A more complex setup would involve two separate physics bodies/pages.
    const pageElementToFlip = pageRightEl; // Simplified for now

    if (!pageElementToFlip) return;

    // Animate to full flip (simplified, assumes right page always flips visually)
    const animateFlip = () => {
      dragProgress += 0.05;
      if (dragProgress >= 1) {
        currentPage = targetPage; // Update state after animation completes
        dragProgress = 0;

        // Reset physics body position for forward flip starting point
        if (pageCornerBody && sketchbookContainer) {
          const rect = sketchbookContainer.getBoundingClientRect();
          Matter.Body.setPosition(pageCornerBody, {
            x: rect.width * 0.75,
            y: 500 * 0.15
          });
          Matter.Body.setVelocity(pageCornerBody, { x: 0, y: 0 });
        }
        return;
      }

      // Apply rotation based on direction (simplified)
      // This is where backward flip visual logic would need refinement
      const rotateY = (direction === 'forward' ? -1 : 1) * dragProgress * 180;
      pageElementToFlip.style.transform = `rotateY(${rotateY}deg)`;
      // Optional: Adjust shadow based on direction too
      pageElementToFlip.style.boxShadow = `0 0 ${20 * dragProgress}px rgba(0,0,0,${0.4 * dragProgress})`;

      requestAnimationFrame(animateFlip);
    };
    animateFlip();
  }

  function selectImage(event, image) {
    event.stopPropagation();
    selectedImage = image;

    if (selectSound) {
      selectSound.currentTime = 0;
      selectSound.play().catch(() => {});
    }
  }

  function goBackToSketchbook() {
    selectedImage = null;
  }

  onDestroy(() => {
    if (render) Matter.Render.stop(render);
    if (runner) Matter.Runner.stop(runner);
    if (engine) {
      Matter.World.clear(engine.world);
      Matter.Engine.clear(engine);
    }
    if (dragSound) dragSound.pause();
  });

  // Calculate total pages based on artworks length
  $: totalPages = artworks.length;

  $: currentArtwork = currentPage >= 0 && currentPage < totalPages
    ? artworks[currentPage] // Use currentPage directly as index
    : null;

  $: previousArtwork = currentPage > 0 && currentPage - 1 < totalPages
    ? artworks[currentPage - 1] // Use currentPage - 1 as index for previous
    : null;

// --- Helper function to get image source ---
// Adjust this function based on your D1 schema and how image URLs are stored
function getImageSource(artwork) {
    // Check if the artwork object exists and has an image_id
    if (artwork && artwork.image_id) {
        // Construct the Cloudflare Images URL using the image_id
        // Replace 'YOUR_CF_ACCOUNT_HASH' with the actual hash from your image delivery URL
        // Example: If your delivery URL is https://imagedelivery.net/4bRSwPonOXfEIBVZiDXg0w/...
        // then '4bRSwPonOXfEIBVZiDXg0w' is the ACCOUNT_HASH
        // Use the 'thumbnail' variant as specified in the README for Gallery.svelte
        // The README example for Gallery.svelte uses '/thumbnail', so we'll use that.
        // Adjust 'thumbnail' to 'gallery', 'desktop', etc., if needed for different sizes.
        const ACCOUNT_HASH = '4bRSwPonOXfEIBVZiDXg0w'; // Extracted from the README example URL
        const VARIANT = 'thumbnail'; // Or 'gallery', 'desktop', etc., based on your Cloudflare Images setup

        console.log("Constructing URL from image_id:", artwork.image_id); // Debug log
        return `https://imagedelivery.net/${ACCOUNT_HASH}/${artwork.image_id}/${VARIANT}`;
    }

    // Fallback if no image_id is present
    console.warn("Could not determine image source for artwork (missing image_id):", artwork);
    return '/path/to/default/image.jpg'; // Provide a default image path
}
</script>

<style>
  .sketchbook-container {
    width: 100%;
    max-width: 800px;
    margin: 0 auto;
    padding: 1rem;
    perspective: 1200px;
    position: relative;
  }

  canvas {
    position: absolute;
    top: 0;
    left: 0;
    pointer-events: auto;
    z-index: 5;
    opacity: 0; /* Set to 0 in production to hide debug view */
  }

  .sketchbook {
    position: relative;
    width: 100%;
    height: 500px;
    background: linear-gradient(135deg, #f8f7f4 0%, #edebe8 100%);
    border: 6px solid #d4c9a8;
    border-radius: 12px;
    box-shadow:
      0 10px 30px rgba(0,0,0,0.2),
      inset 0 0 15px rgba(212, 201, 168, 0.3);
    overflow: hidden;
    cursor: grab;
    user-select: none;
  }

  .sketchbook.dragging {
    cursor: grabbing;
  }

  .page-left, .page-right {
    position: absolute;
    top: 0;
    width: 50%;
    height: 100%;
    padding: 2rem;
    display: flex;
    flex-direction: column;
    justify-content: center;
    align-items: center;
    font-family: 'Georgia', serif;
    pointer-events: none;
  }

  .page-left {
    left: 0;
    border-right: 1px dotted #ccc;
    background: #fcfaf6;
    transform-origin: right center; /* Important for 3D transform */
    transform-style: preserve-3d;
  }

  .page-right {
    right: 0;
    background: #fcfaf6;
    transform-origin: left center; /* Important for 3D transform */
    transform-style: preserve-3d;
    transition: box-shadow 0.1s;
  }

  .prompt-text {
    font-size: 1.1rem;
    line-height: 1.6;
    text-align: center;
    color: #4a4a3c;
    opacity: 0.9;
    font-style: italic;
  }

  .page-number {
    margin-top: 1rem;
    font-size: 0.85rem;
    color: #666;
    font-style: italic;
  }

  .placeholder {
    font-size: 2rem;
    color: #ddd;
    font-style: italic;
  }

  .art-thumbnail {
    width: 100%;
    height: 100%;
    display: flex;
    justify-content: center;
    align-items: center;
    cursor: pointer;
    pointer-events: auto;
  }

  .art-thumbnail img {
    max-width: 90%;
    max-height: 80%;
    object-fit: contain;
    border-radius: 6px;
    box-shadow: 0 4px 12px rgba(0,0,0,0.1);
    transition: all 0.3s ease;
    border: 1px solid #e0d8c4;
  }

  .art-thumbnail img:hover {
    transform: scale(1.03);
    box-shadow: 0 6px 16px rgba(0,0,0,0.15);
  }

  .selected-image-view {
    position: fixed;
    top: 0;
    left: 0;
    width: 100vw;
    height: 100vh;
    display: flex;
    flex-direction: column;
    background: #000;
    z-index: 100;
  }

  .back-button {
    position: absolute;
    top: 1rem;
    left: 1rem;
    background: rgba(255,255,255,0.95);
    color: #333;
    border: none;
    padding: 0.5rem 1rem;
    border-radius: 6px;
    font-size: 0.9rem;
    cursor: pointer;
    z-index: 10;
    box-shadow: 0 2px 6px rgba(0,0,0,0.1);
    font-family: inherit;
    transition: all 0.2s;
  }

  .back-button:hover {
    background: #f8f7f4;
    color: #2c5e3d;
  }

  .drag-hint {
    position: absolute;
    top: 1rem;
    right: 1rem;
    font-size: 0.85rem;
    color: #4a4a3c;
    opacity: 0.5;
    font-style: italic;
    pointer-events: none;
    transition: opacity 0.3s;
  }

  .drag-hint.hidden {
    opacity: 0;
  }

  /* Navigation Arrows */
  .nav-arrow {
    position: absolute;
    top: 50%;
    transform: translateY(-50%);
    width: 48px;
    height: 48px;
    border: 2px solid #d4c9a8;
    background: rgba(255, 255, 255, 0.9);
    border-radius: 50%;
    font-size: 2rem;
    color: #4a4a3c;
    cursor: pointer;
    display: flex;
    align-items: center;
    justify-content: center;
    z-index: 10;
    transition: all 0.3s ease;
    pointer-events: auto;
  }

  .nav-arrow:hover {
    background: white;
    transform: translateY(-50%) scale(1.1);
    box-shadow: 0 4px 12px rgba(0,0,0,0.15);
  }

  .nav-arrow.prev {
    left: 1rem;
  }

  .nav-arrow.next {
    right: 1rem;
  }

  @media (max-width: 768px) {
    .sketchbook {
      height: 400px;
    }

    .page-left, .page-right {
      padding: 1rem;
    }

    .prompt-text {
      font-size: 0.95rem;
    }

    .nav-arrow {
      width: 40px;
      height: 40px;
      font-size: 1.5rem;
    }
  }

  .sketchbook::before {
    content: "";
    position: absolute;
    top: 1rem;
    right: 1rem;
    width: 40px;
    height: 40px;
    opacity: 0.08;
    pointer-events: none;
  }
</style>

{#if selectedImage}
  <div class="selected-image-view">
    <button class="back-button" on:click={goBackToSketchbook}>
      ← {$t('common.back')}
    </button>
    <ArtPiece
      artwork={selectedImage} 
      interactive={true}
    />
  </div>
{:else}
  <div class="sketchbook-container" bind:this={sketchbookContainer}>
    <canvas bind:this={canvasEl}></canvas>
    <div class="sketchbook" class:dragging={isDragging}>
      <div class="page-left" bind:this={pageLeftEl}> 
        {#if currentPage > 0 && previousArtwork} 
          <div class="art-thumbnail previous" on:click={(e) => selectImage(e, previousArtwork)}>
            <img
              src={getImageSource(previousArtwork)} 
              alt={previousArtwork.title}
              title="Click to explore this story"
            >
            <div class="sketch-title">{previousArtwork.title}</div>
          </div>
        {:else}
          <div class="prompt-text">{promptText}</div>
          {#if currentPage > 0} 
            <div class="page-number">
              Página {currentPage + 1} / {totalPages} 
            </div>
          {/if}
        {/if}
      </div>

      <div class="page-right" bind:this={pageRightEl}>
        {#if currentArtwork}
          <div class="art-thumbnail" on:click={(e) => selectImage(e, currentArtwork)}>
            <img
              src={getImageSource(currentArtwork)} 
              alt={currentArtwork.title}
              title="Click to explore this story"
            >
            <div class="sketch-title">{currentArtwork.title}</div>
          </div>
        {:else}
          <span class="placeholder">...</span>
        {/if}
      </div>

      {#if currentPage > 0}
        <button class="nav-arrow prev" on:click={() => completePage('backward')} aria-label="Previous page">
          ‹
        </button>
      {/if}
      {#if currentPage < totalPages - 1} 
        <button class="nav-arrow next" on:click={() => completePage('forward')} aria-label="Next page">
          ›
        </button>
      {/if}

      <div class="drag-hint" class:hidden={isDragging || currentPage > 0}>
        Drag the corner →
      </div>
    </div>
  </div>
{/if}
