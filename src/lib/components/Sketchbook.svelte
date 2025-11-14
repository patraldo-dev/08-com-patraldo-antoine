<!-- src/lib/components/Sketchbook.svelte -->
<script>
  import { onMount, onDestroy } from 'svelte';
  import Matter from 'matter-js';
  import { locale, t } from '$lib/translations';
  import StoryView from './StoryView.svelte';

  // Props
  export let artworks = [];

  // State
  let currentPage = 0;
  let selectedImage = null;
  let isDragging = false;
  let dragProgress = 0;
  let isAnimating = false;

  // DOM refs
  let sketchbookContainer;
  let pageRightEl;
  let pageLeftEl;

  // Matter.js (headless - no canvas rendering)
  let engine;
  let runner;
  let mouse;
  let mouseConstraint;
  let pageCornerBody;
  let pagePivot;
  let updateLoopId = null;
  let mouseElement; // Invisible div for mouse interaction

  // Preload sounds
  let flipSound;
  let selectSound;
  let dragSound;

  // Cache dimensions
  let containerWidth = 0;
  let containerHeight = 600; // Increased from 500

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
    if (!sketchbookContainer) return;
    
    const containerRect = sketchbookContainer.getBoundingClientRect();
    containerWidth = containerRect.width;
    
    // Responsive height
    containerHeight = window.innerWidth < 768 ? 500 : 600;

    // Create engine with optimized settings (headless - no rendering)
    engine = Matter.Engine.create({
      enableSleeping: true,
      positionIterations: 6,
      velocityIterations: 4
    });
    engine.gravity.y = 0.3;

    // Page corner that user can drag
    const cornerX = containerWidth * 0.75;
    const cornerY = containerHeight * 0.15;

    pageCornerBody = Matter.Bodies.circle(cornerX, cornerY, 30, {
      density: 0.001,
      frictionAir: 0.02,
      restitution: 0.3,
      sleepThreshold: 60,
      label: 'pageCorner'
    });

    // Pivot point
    pagePivot = Matter.Bodies.circle(containerWidth / 2, containerHeight / 2, 5, {
      isStatic: true
    });

    // Constraint connecting corner to pivot
    const pageConstraint = Matter.Constraint.create({
      bodyA: pagePivot,
      bodyB: pageCornerBody,
      stiffness: 0.008,
      damping: 0.05,
      length: Math.hypot(cornerX - containerWidth/2, cornerY - containerHeight/2)
    });

    // Create invisible mouse element for interaction
    mouseElement = document.createElement('div');
    mouseElement.style.position = 'absolute';
    mouseElement.style.top = '0';
    mouseElement.style.left = '0';
    mouseElement.style.width = containerWidth + 'px';
    mouseElement.style.height = containerHeight + 'px';
    mouseElement.style.pointerEvents = 'auto';
    sketchbookContainer.appendChild(mouseElement);

    // Add mouse control (no canvas needed)
    mouse = Matter.Mouse.create(mouseElement);
    mouseConstraint = Matter.MouseConstraint.create(engine, {
      mouse: mouse,
      constraint: {
        stiffness: 0.2
      }
    });

// Create a visible draggable corner indicator
const cornerIndicator = document.createElement('div');
cornerIndicator.style.position = 'absolute';
cornerIndicator.style.top = (containerHeight * 0.15) + 'px';
cornerIndicator.style.left = (containerWidth * 0.75) + 'px';
cornerIndicator.style.width = '60px';
cornerIndicator.style.height = '60px';
cornerIndicator.style.pointerEvents = 'auto'; // Only THIS area is draggable
cornerIndicator.style.cursor = 'grab';
cornerIndicator.style.borderRadius = '50%';
cornerIndicator.style.opacity = '0.3';
cornerIndicator.style.transition = 'opacity 0.3s';
cornerIndicator.addEventListener('mouseenter', () => cornerIndicator.style.opacity = '0.6');
cornerIndicator.addEventListener('mouseleave', () => cornerIndicator.style.opacity = '0.3');
sketchbookContainer.appendChild(cornerIndicator);

    // Detect drag events
    Matter.Events.on(mouseConstraint, 'startdrag', (event) => {
      if (event.body === pageCornerBody) {
        isDragging = true;
        Matter.Sleeping.set(pageCornerBody, false);
        
        if (dragSound && dragSound.paused) {
          dragSound.play().catch(() => {});
        }
        
        if (!updateLoopId) {
          startUpdateLoop();
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

        const dragDistance = containerWidth / 2 - pageCornerBody.position.x;
        if (dragDistance > containerWidth * 0.25) {
          completePage('forward');
        } else {
          resetPageCorner();
        }
      }
    });

    // Add to world
    Matter.World.add(engine.world, [pageCornerBody, pagePivot, pageConstraint, mouseConstraint]);

    // Run engine (headless - no renderer)
    runner = Matter.Runner.create();
    Matter.Runner.run(runner, engine);
  }

  function startUpdateLoop() {
    const updateLoop = () => {
      if (!pageRightEl || !pageCornerBody || !sketchbookContainer) {
        stopUpdateLoop();
        return;
      }

      if (!isDragging && !isAnimating) {
        stopUpdateLoop();
        return;
      }

      const cornerX = pageCornerBody.position.x;
      const maxDrag = containerWidth / 2;
      const currentDrag = Math.max(0, (containerWidth * 0.75) - cornerX);
      dragProgress = Math.min(1, currentDrag / maxDrag);

      const rotateY = dragProgress * -180;
      pageRightEl.style.transform = `rotateY(${rotateY}deg)`;
      pageRightEl.style.boxShadow = `0 0 ${20 * dragProgress}px rgba(0,0,0,${0.4 * dragProgress})`;

      updateLoopId = requestAnimationFrame(updateLoop);
    };
    updateLoop();
  }

  function stopUpdateLoop() {
    if (updateLoopId) {
      cancelAnimationFrame(updateLoopId);
      updateLoopId = null;
    }
  }

  function resetPageCorner() {
    if (pageCornerBody && sketchbookContainer) {
      Matter.Body.setPosition(pageCornerBody, {
        x: containerWidth * 0.75,
        y: containerHeight * 0.15
      });
      Matter.Body.setVelocity(pageCornerBody, { x: 0, y: 0 });
      
      setTimeout(() => {
        Matter.Sleeping.set(pageCornerBody, true);
      }, 100);
    }
  }

  function completePage(direction) {
    let targetPage = currentPage;
    const totalPages = artworks.length;

    if (direction === 'forward') {
      if (currentPage < totalPages - 1) {
        targetPage = currentPage + 1;
      } else {
        resetPageCorner();
        return;
      }
    } else if (direction === 'backward') {
      if (currentPage > 0) {
        targetPage = currentPage - 1;
      } else {
        return;
      }
    } else {
      return;
    }

    if (flipSound) {
      flipSound.currentTime = 0;
      flipSound.play().catch(() => {});
    }

    const pageElementToFlip = pageRightEl;
    if (!pageElementToFlip) return;

    isAnimating = true;
    startUpdateLoop();

    let animProgress = dragProgress;
    const animateFlip = () => {
      animProgress += 0.05;
      if (animProgress >= 1) {
        currentPage = targetPage;
        dragProgress = 0;
        isAnimating = false;

        resetPageCorner();
        return;
      }

      dragProgress = animProgress;
      const rotateY = (direction === 'forward' ? -1 : 1) * animProgress * 180;
      pageElementToFlip.style.transform = `rotateY(${rotateY}deg)`;
      pageElementToFlip.style.boxShadow = `0 0 ${20 * animProgress}px rgba(0,0,0,${0.4 * animProgress})`;

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
    // Restart physics if needed
    if (engine && pageCornerBody) {
      Matter.Sleeping.set(pageCornerBody, false);
    }
  }

  onDestroy(() => {
    stopUpdateLoop();
    
    if (mouseConstraint) {
      Matter.Events.off(mouseConstraint, 'startdrag');
      Matter.Events.off(mouseConstraint, 'enddrag');
    }
    if (runner) Matter.Runner.stop(runner);
    if (engine) {
      Matter.World.clear(engine.world);
      Matter.Engine.clear(engine);
    }
    if (mouseElement && mouseElement.parentNode) {
      mouseElement.parentNode.removeChild(mouseElement);
    }
    
    if (dragSound) {
      dragSound.pause();
      dragSound.remove();
    }
    if (flipSound) flipSound.remove();
    if (selectSound) selectSound.remove();
  });

  $: totalPages = artworks.length;

  $: currentArtwork = currentPage >= 0 && currentPage < totalPages
    ? artworks[currentPage]
    : null;

  $: previousArtwork = currentPage > 0 && currentPage - 1 < totalPages
    ? artworks[currentPage - 1]
    : null;

  // Use 'gallery' variant for better quality (larger than thumbnail)
  function getImageSource(artwork) {
    // Try thumbnailId first (from your page.server.js transform)
    if (artwork && artwork.thumbnailId) {
      const ACCOUNT_HASH = '4bRSwPonOXfEIBVZiDXg0w';
      const VARIANT = 'gallery'; // Changed from 'thumbnail' to 'gallery'
      return `https://imagedelivery.net/${ACCOUNT_HASH}/${artwork.thumbnailId}/${VARIANT}`;
    }
    // Fallback to image_id (direct from database)
    if (artwork && artwork.image_id) {
      const ACCOUNT_HASH = '4bRSwPonOXfEIBVZiDXg0w';
      const VARIANT = 'gallery';
      return `https://imagedelivery.net/${ACCOUNT_HASH}/${artwork.image_id}/${VARIANT}`;
    }
    console.warn("Could not determine image source for artwork:", artwork);
    return null;
  }

</script>

<style>
  .sketchbook-container {
    width: 100%;
    max-width: 900px; /* Increased from 800px */
    margin: 0 auto;
    padding: 0.5rem; /* Reduced padding for more space */
    perspective: 1200px;
    position: relative;
  }

  .sketchbook {
    position: relative;
    width: 100%;
    height: 600px; /* Increased from 500px */
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
    padding: 2.5rem; /* Increased from 2rem */
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
    transform-origin: right center;
    transform-style: preserve-3d;
  }

  .page-right {
    right: 0;
    background: #fcfaf6;
    transform-origin: left center;
    transform-style: preserve-3d;
    transition: box-shadow 0.1s;
    will-change: transform;
  }

  .prompt-text {
    font-size: 1.2rem; /* Slightly increased */
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
    flex-direction: column;
    justify-content: center;
    align-items: center;
    cursor: pointer;
    pointer-events: auto;
    gap: 0.75rem;
  }

  .art-thumbnail img {
    max-width: 95%; /* Increased from 90% */
    max-height: 85%; /* Increased from 80% */
    object-fit: contain;
    border-radius: 6px;
    box-shadow: 0 4px 12px rgba(0,0,0,0.1);
    transition: transform 0.3s ease, box-shadow 0.3s ease;
    border: 1px solid #e0d8c4;
  }

  .art-thumbnail img:hover {
    transform: scale(1.03);
    box-shadow: 0 6px 16px rgba(0,0,0,0.15);
  }

  .sketch.display_name {
    font-size: 1rem; /* Slightly increased */
    color: #4a4a3c;
    text-align: center;
    font-style: italic;
    max-width: 90%;
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

  .nav-arrow {
    position: absolute;
    top: 50%;
    transform: translateY(-50%);
    width: 50px; /* Slightly larger */
    height: 50px;
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
    .sketchbook-container {
      max-width: 100%;
      padding: 0.25rem;
    }

    .sketchbook {
      height: 500px; /* Keep reasonable height on mobile */
    }

    .page-left, .page-right {
      padding: 1.5rem;
    }

    .prompt-text {
      font-size: 1rem;
    }

    .sketch.display_name {
      font-size: 0.9rem;
    }

    .nav-arrow {
      width: 42px;
      height: 42px;
      font-size: 1.75rem;
    }

    .art-thumbnail img {
      max-width: 92%;
      max-height: 82%;
    }
  }

  /* Extra small screens */
  @media (max-width: 480px) {
    .sketchbook {
      height: 450px;
    }

    .page-left, .page-right {
      padding: 1rem;
    }

    .nav-arrow {
      width: 38px;
      height: 38px;
      font-size: 1.5rem;
    }
  }
</style>

{#if selectedImage}
  <StoryView 
    artwork={selectedImage}
    on:close={goBackToSketchbook}
  />
{:else}
  <div class="sketchbook-container" bind:this={sketchbookContainer}>
    <div class="sketchbook" class:dragging={isDragging}>
      <div class="page-left" bind:this={pageLeftEl}> 
        {#if currentPage > 0 && previousArtwork} 
          <div class="art-thumbnail previous" on:click={(e) => selectImage(e, previousArtwork)}>
            <img
              src={getImageSource(previousArtwork)} 
              alt={previousArtwork.display_name || previousArtwork.title}
              title="Click to explore this story"
            >
            <div class="sketch.display_name">{previousArtwork.display_name}</div>
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
              alt={currentArtwork.display_name || currentArtwork.title}
              title="Click to explore this story"
            >
            <div class="sketch.display_name">{currentArtwork.display_name}</div>
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


{#if selectedImage}
  <StoryView 
    artwork={selectedImage}
    on:close={goBackToSketchbook}
  />
{:else}
  <div class="sketchbook-container" bind:this={sketchbookContainer}>
    <!-- all the sketchbook content -->
  </div>
{/if}
