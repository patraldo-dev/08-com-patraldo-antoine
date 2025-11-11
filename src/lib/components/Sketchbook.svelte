<!-- src/lib/components/Sketchbook.svelte -->
<script>
  import { onMount, onDestroy, createEventDispatcher } from 'svelte';
  import Matter from 'matter-js';
  import { locale } from 'sveltekit-i18n';

  const dispatch = createEventDispatcher();

  export let artworks = [];
  export let maxPages = 6;

  let currentPage = 0;
  let isDragging = false;
  let dragProgress = 0;
  
  let sketchbookContainer;
  let pageRightEl;
  let canvasEl;
  
  let engine, runner, render, mouse, mouseConstraint;
  let pageCornerBody, pagePivot;
  
  let flipSound, dragSound;

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
      
      dragSound = new Audio('/sounds/paper-rustle.mp3');
      dragSound.volume = 0.15;
      dragSound.loop = true;
    } catch (e) {
      console.log('Audio files not available');
    }

    if (sketchbookContainer) {
      initPhysics();
    }
  });

  function initPhysics() {
    const containerRect = sketchbookContainer.getBoundingClientRect();
    const width = containerRect.width;
    const height = 500;

    engine = Matter.Engine.create();
    engine.gravity.y = 0.3;

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

    const cornerX = width * 0.75;
    const cornerY = height * 0.15;
    
    pageCornerBody = Matter.Bodies.circle(cornerX, cornerY, 30, {
      density: 0.001,
      frictionAir: 0.02,
      restitution: 0.3,
      render: {
        fillStyle: 'rgba(212, 201, 168, 0.3)',
        strokeStyle: '#d4c9a8',
        lineWidth: 2
      },
      label: 'pageCorner'
    });

    pagePivot = Matter.Bodies.circle(width / 2, height / 2, 5, {
      isStatic: true,
      render: { visible: false }
    });

    const pageConstraint = Matter.Constraint.create({
      bodyA: pagePivot,
      bodyB: pageCornerBody,
      stiffness: 0.008,
      damping: 0.05,
      length: Math.hypot(cornerX - width/2, cornerY - height/2),
      render: { visible: false }
    });

    mouse = Matter.Mouse.create(render.canvas);
    mouseConstraint = Matter.MouseConstraint.create(engine, {
      mouse: mouse,
      constraint: {
        stiffness: 0.2,
        render: { visible: false }
      }
    });

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
        
        const dragDistance = width / 2 - pageCornerBody.position.x;
        if (dragDistance > width * 0.25) {
          completePage();
        }
      }
    });

    Matter.World.add(engine.world, [pageCornerBody, pagePivot, pageConstraint, mouseConstraint]);

    runner = Matter.Runner.create();
    Matter.Runner.run(runner, engine);
    Matter.Render.run(render);

    const updateLoop = () => {
      if (!pageRightEl || !pageCornerBody) return;
      
      const cornerX = pageCornerBody.position.x;
      const maxDrag = width / 2;
      const currentDrag = Math.max(0, (width * 0.75) - cornerX);
      dragProgress = Math.min(1, currentDrag / maxDrag);
      
      const rotateY = dragProgress * -180;
      pageRightEl.style.transform = `rotateY(${rotateY}deg)`;
      pageRightEl.style.boxShadow = `0 0 ${20 * dragProgress}px rgba(0,0,0,${0.4 * dragProgress})`;
      
      requestAnimationFrame(updateLoop);
    };
    updateLoop();
  }

  function completePage() {
    if (currentPage >= maxPages - 1) return;
    
    if (flipSound) {
      flipSound.currentTime = 0;
      flipSound.play().catch(() => {});
    }

    const animateFlip = () => {
      dragProgress += 0.05;
      if (dragProgress >= 1) {
        currentPage++;
        dragProgress = 0;
        
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
      
      const rotateY = dragProgress * -180;
      if (pageRightEl) {
        pageRightEl.style.transform = `rotateY(${rotateY}deg)`;
      }
      requestAnimationFrame(animateFlip);
    };
    animateFlip();
  }

  function selectArtwork(event, artwork) {
    event.stopPropagation();
    dispatch('selectArtwork', artwork);
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
  
  $: currentArtwork = currentPage > 0 && artworks[currentPage - 1] 
    ? artworks[currentPage - 1] 
    : null;
</script>

<div class="sketchbook-container" bind:this={sketchbookContainer}>
  <canvas bind:this={canvasEl}></canvas>
  <div class="sketchbook" class:dragging={isDragging}>
    <div class="page-left">
      <div class="prompt-text">{promptText}</div>
      {#if currentPage > 0}
        <div class="page-number">
          Página {currentPage} / {maxPages - 1}
        </div>
      {/if}
    </div>
    
    <div class="page-right" bind:this={pageRightEl}>
      {#if currentArtwork}
        <div class="sketch-preview" on:click={(e) => selectArtwork(e, currentArtwork)}>
          <div class="sketch-frame">
            <img 
              src={currentArtwork.thumbnailUrl || `/artwork/${currentArtwork.id}.jpg`}
              alt={currentArtwork.title}
              loading="lazy"
            >
          </div>
          <div class="sketch-title">{currentArtwork.title}</div>
        </div>
        <div class="tap-hint" class:hidden={isDragging}>
          Tap to read →
        </div>
      {:else}
        <span class="placeholder">...</span>
      {/if}
    </div>
  </div>
</div>

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
    opacity: 0; /* Set to 0.5 for debugging physics */
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
  }

  .page-right {
    right: 0;
    background: #fcfaf6;
    transform-origin: left center;
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

  .sketch-preview {
    width: 100%;
    height: 100%;
    display: flex;
    flex-direction: column;
    justify-content: center;
    align-items: center;
    cursor: pointer;
    pointer-events: auto;
    padding: 1.5rem;
  }

  .sketch-frame {
    position: relative;
    max-width: 85%;
    max-height: 70%;
    filter: drop-shadow(0 2px 8px rgba(0,0,0,0.15));
    transition: transform 0.3s ease;
  }

  .sketch-preview:hover .sketch-frame {
    transform: rotate(-1deg) scale(1.02);
  }

  .sketch-frame img {
    width: 100%;
    height: 100%;
    object-fit: contain;
    border: 3px solid white;
    box-shadow: inset 0 0 10px rgba(0,0,0,0.05);
  }

  .sketch-title {
    margin-top: 1rem;
    font-size: 0.85rem;
    color: #4a4a3c;
    text-align: center;
    font-style: italic;
    opacity: 0.8;
  }

  .tap-hint {
    position: absolute;
    bottom: 1rem;
    right: 1rem;
    font-size: 0.75rem;
    color: #4a4a3c;
    opacity: 0.4;
    font-style: italic;
    pointer-events: none;
    transition: opacity 0.3s;
  }

  .tap-hint.hidden {
    opacity: 0;
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
  }
</style>
