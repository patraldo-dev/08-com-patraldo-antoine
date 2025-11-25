<!-- src/lib/components/Sketchbook.svelte -->
<script>
  import { onMount, onDestroy } from 'svelte';
  import { locale, t } from '$lib/i18n';
  import StoryView from './StoryView.svelte';
  
  // Props
  export let artworks = [];
  
  // State
  let currentSpread = 0; // Track which spread (pair) we're on
  let selectedImage = null;
  let isAnimating = false;
  let flipDirection = null; // 'forward' or 'backward'
  
  // DOM refs
  let sketchbookContainer;
  
  // Preload sounds
  let flipSound;
  let selectSound;
  
  onMount(async () => {
    try {
      flipSound = new Audio('/sounds/page-flip.mp3');
      flipSound.volume = 0.3;
      selectSound = new Audio('/sounds/select.mp3');
      selectSound.volume = 0.2;
    } catch (e) {
      console.log('Audio not available');
    }
  });
  
  function nextSpread() {
    if (isAnimating) return;
    const totalSpreads = Math.ceil(artworks.length / 2);
    if (currentSpread < totalSpreads - 1) {
      playFlip();
      isAnimating = true;
      flipDirection = 'forward';
      setTimeout(() => {
        currentSpread++;
        flipDirection = null;
      }, 400);
      setTimeout(() => { 
        isAnimating = false; 
      }, 600);
    }
  }
  
  function prevSpread() {
    if (isAnimating) return;
    if (currentSpread > 0) {
      playFlip();
      isAnimating = true;
      flipDirection = 'backward';
      setTimeout(() => {
        currentSpread--;
        flipDirection = null;
      }, 400);
      setTimeout(() => { 
        isAnimating = false; 
      }, 600);
    }
  }
  
  function playFlip() {
    if (flipSound) {
      flipSound.currentTime = 0;
      flipSound.play().catch(() => {});
    }
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
    isAnimating = false;
  }
  
  onDestroy(() => {
    if (flipSound) flipSound.remove();
    if (selectSound) selectSound.remove();
  });
  
  // Get left and right artworks for current spread
  $: leftIndex = currentSpread * 2;
  $: rightIndex = currentSpread * 2 + 1;
  $: leftArtwork = artworks[leftIndex] || null;
  $: rightArtwork = artworks[rightIndex] || null;
  $: totalSpreads = Math.ceil(artworks.length / 2);
  
  function getImageSource(artwork) {
    if (!artwork) return null;
    if (artwork.thumbnailId) {
      const ACCOUNT_HASH = '4bRSwPonOXfEIBVZiDXg0w';
      return `https://imagedelivery.net/${ACCOUNT_HASH}/${artwork.thumbnailId}/gallery`;
    }
    if (artwork.image_id) {
      const ACCOUNT_HASH = '4bRSwPonOXfEIBVZiDXg0w';
      return `https://imagedelivery.net/${ACCOUNT_HASH}/${artwork.image_id}/gallery`;
    }
    return null;
  }
</script>

<style>
  .sketchbook-container {
    width: 100%;
    max-width: 1200px;
    margin: 0 auto;
    padding: 1rem;
    perspective: 1500px;
    position: relative;
  }
  
  .magazine-spread {
    position: relative;
    width: 100%;
    height: 700px;
    background: linear-gradient(135deg, #f8f7f4 0%, #edebe8 100%);
    border: 6px solid #d4c9a8;
    border-radius: 12px;
    box-shadow:
      0 10px 40px rgba(0,0,0,0.25),
      inset 0 0 20px rgba(212, 201, 168, 0.3);
    overflow: hidden;
    display: flex;
    transition: none;
    transform-style: preserve-3d;
    perspective: 1500px;
  }
  
  .magazine-spread.animating {
    pointer-events: none;
  }
  
  /* Magazine pages */
  .magazine-page {
    width: 50%;
    height: 100%;
    padding: 2.5rem;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    background: #fcfaf6;
    position: relative;
    cursor: pointer;
    transition: background 0.2s ease, transform 0.5s ease, box-shadow 0.5s ease;
    transform-style: preserve-3d;
    backface-visibility: hidden;
  }
  
  .magazine-page:hover:not(.flipping) {
    background: #f8f6f2;
  }
  
  .magazine-page.left {
    border-right: 2px solid #d4c9a8;
    transform-origin: right center;
  }
  
  .magazine-page.right {
    transform-origin: left center;
  }
  
  /* Page flip animations */
  .magazine-page.flipping.forward {
    animation: pageFlipForward 0.6s ease-in-out;
  }
  
  .magazine-page.flipping.backward {
    animation: pageFlipBackward 0.6s ease-in-out;
  }
  
  @keyframes pageFlipForward {
    0% {
      transform: rotateY(0deg);
      box-shadow: 0 0 0 rgba(0,0,0,0);
    }
    50% {
      transform: rotateY(-90deg);
      box-shadow: -20px 0 30px rgba(0,0,0,0.3);
    }
    100% {
      transform: rotateY(-180deg);
      box-shadow: 0 0 0 rgba(0,0,0,0);
    }
  }
  
  @keyframes pageFlipBackward {
    0% {
      transform: rotateY(0deg);
      box-shadow: 0 0 0 rgba(0,0,0,0);
    }
    50% {
      transform: rotateY(90deg);
      box-shadow: 20px 0 30px rgba(0,0,0,0.3);
    }
    100% {
      transform: rotateY(180deg);
      box-shadow: 0 0 0 rgba(0,0,0,0);
    }
  }
  
  .artwork-wrapper {
    width: 100%;
    height: 100%;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    gap: 1rem;
  }
  
  .magazine-page img {
    max-width: 95%;
    max-height: 85%;
    object-fit: contain;
    border-radius: 8px;
    box-shadow: 0 8px 24px rgba(0,0,0,0.15);
    transition: transform 0.3s ease, box-shadow 0.3s ease;
  }
  
  .magazine-page:hover img {
    transform: scale(1.03);
    box-shadow: 0 12px 32px rgba(0,0,0,0.2);
  }
  
  .artwork-caption {
    font-family: 'Georgia', serif;
    font-size: 1rem;
    color: #4a4a3c;
    text-align: center;
    font-style: italic;
    max-width: 90%;
  }
  
  .empty-page {
    display: flex;
    align-items: center;
    justify-content: center;
    font-family: 'Georgia', serif;
    font-size: 1.5rem;
    color: #d4c9a8;
    font-style: italic;
  }
  
  /* Navigation arrows */
  .nav-arrow {
    position: absolute;
    top: 50%;
    transform: translateY(-50%);
    width: 55px;
    height: 55px;
    border: 2px solid #d4c9a8;
    background: rgba(255, 255, 255, 0.95);
    border-radius: 50%;
    font-size: 2.2rem;
    color: #4a4a3c;
    cursor: pointer;
    display: flex;
    align-items: center;
    justify-content: center;
    z-index: 10;
    transition: all 0.3s ease;
  }
  
  .nav-arrow:hover:not(:disabled) {
    background: white;
    transform: translateY(-50%) scale(1.1);
    box-shadow: 0 4px 12px rgba(0,0,0,0.15);
  }
  
  .nav-arrow:disabled {
    opacity: 0.3;
    cursor: not-allowed;
  }
  
  .nav-arrow.prev {
    left: -1.5rem;
  }
  
  .nav-arrow.next {
    right: -1.5rem;
  }
  
  .spread-counter {
    position: absolute;
    bottom: 1rem;
    left: 50%;
    transform: translateX(-50%);
    font-family: 'Georgia', serif;
    font-size: 0.9rem;
    color: #999;
    font-style: italic;
    background: rgba(255, 255, 255, 0.9);
    padding: 0.5rem 1.5rem;
    border-radius: 20px;
    box-shadow: 0 2px 8px rgba(0,0,0,0.1);
  }
  
  /* Gutter/spine effect */
  .magazine-spine {
    position: absolute;
    left: 50%;
    top: 0;
    bottom: 0;
    width: 4px;
    background: linear-gradient(to bottom, 
      transparent 0%, 
      rgba(212, 201, 168, 0.5) 20%, 
      rgba(212, 201, 168, 0.8) 50%, 
      rgba(212, 201, 168, 0.5) 80%, 
      transparent 100%);
    transform: translateX(-50%);
    pointer-events: none;
    z-index: 5;
  }
  
  /* Mobile responsive */
  @media (max-width: 968px) {
    .magazine-spread {
      flex-direction: column;
      height: auto;
    }
    
    .magazine-page {
      width: 100%;
      min-height: 400px;
      border-right: none !important;
    }
    
    .magazine-page.left {
      border-bottom: 2px solid #d4c9a8;
    }
    
    .magazine-spine {
      display: none;
    }
    
    .nav-arrow.prev {
      left: 1rem;
    }
    
    .nav-arrow.next {
      right: 1rem;
    }
  }
  
  @media (max-width: 768px) {
    .sketchbook-container {
      padding: 0.5rem;
    }
    
    .magazine-spread {
      height: auto;
    }
    
    .magazine-page {
      padding: 1.5rem;
      min-height: 350px;
    }
    
    .nav-arrow {
      width: 45px;
      height: 45px;
      font-size: 1.8rem;
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
    <div class="magazine-spread" class:animating={isAnimating}>
      <!-- Left page -->
      <div 
        class="magazine-page left" 
        class:flipping={flipDirection === 'backward'}
        class:backward={flipDirection === 'backward'}
        on:click={(e) => leftArtwork && selectImage(e, leftArtwork)}
      >
        {#if leftArtwork}
          <div class="artwork-wrapper">
            <img
              src={getImageSource(leftArtwork)}
              alt={leftArtwork.display_name || leftArtwork.title}
            />
            <div class="artwork-caption">
              {leftArtwork.display_name || leftArtwork.title}
            </div>
          </div>
        {:else}
          <div class="empty-page">·</div>
        {/if}
      </div>
      
      <!-- Magazine spine/gutter -->
      <div class="magazine-spine"></div>
      
      <!-- Right page -->
      <div 
        class="magazine-page right" 
        class:flipping={flipDirection === 'forward'}
        class:forward={flipDirection === 'forward'}
        on:click={(e) => rightArtwork && selectImage(e, rightArtwork)}
      >
        {#if rightArtwork}
          <div class="artwork-wrapper">
            <img
              src={getImageSource(rightArtwork)}
              alt={rightArtwork.display_name || rightArtwork.title}
            />
            <div class="artwork-caption">
              {rightArtwork.display_name || rightArtwork.title}
            </div>
          </div>
        {:else}
          <div class="empty-page">·</div>
        {/if}
      </div>
      
      <!-- Navigation -->
      <button 
        class="nav-arrow prev" 
        on:click={prevSpread}
        disabled={currentSpread === 0}
        aria-label="Previous spread"
      >
        ‹
      </button>
      
      <button 
        class="nav-arrow next" 
        on:click={nextSpread}
        disabled={currentSpread >= totalSpreads - 1}
        aria-label="Next spread"
      >
        ›
      </button>
      
      <div class="spread-counter">
        Spread {currentSpread + 1} of {totalSpreads}
      </div>
    </div>
  </div>
{/if}
