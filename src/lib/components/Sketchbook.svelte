<!-- src/lib/components/Sketchbook.svelte -->
<script>
  import { onMount, onDestroy } from 'svelte';
  import { locale, t } from '$lib/i18n';
  import StoryView from './StoryView.svelte';
  
  // Props
  export let artworks = [];
  
  // State
  let currentPage = 0;
  let selectedImage = null;
  let isAnimating = false;
  
  // DOM refs
  let sketchbookContainer;
  
  // Preload sounds
  let flipSound;
  let selectSound;
  
  onMount(async () => {
    // Preload sounds
    try {
      flipSound = new Audio('/sounds/page-flip.mp3');
      flipSound.volume = 0.3;
      selectSound = new Audio('/sounds/select.mp3');
      selectSound.volume = 0.2;
    } catch (e) {
      console.log('Audio not available');
    }
  });
  
  function completePage(direction) {
    if (isAnimating) return;
    
    let targetPage = currentPage;
    const totalPages = artworks.length;
    
    if (direction === 'forward') {
      if (currentPage < totalPages - 1) {
        targetPage = currentPage + 1;
      } else {
        return;
      }
    } else if (direction === 'backward') {
      if (currentPage > 0) {
        targetPage = currentPage - 1;
      } else {
        return;
      }
    }
    
    if (flipSound) {
      flipSound.currentTime = 0;
      flipSound.play().catch(() => {});
    }
    
    isAnimating = true;
    
    // Simple fade transition
    setTimeout(() => {
      currentPage = targetPage;
      isAnimating = false;
    }, 300);
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
    if (flipSound) flipSound.remove();
    if (selectSound) selectSound.remove();
  });
  
  $: totalPages = artworks.length;
  $: currentArtwork = currentPage >= 0 && currentPage < totalPages
    ? artworks[currentPage]
    : null;
  
  // Get story excerpt (first 200 chars or full text if shorter)
  function getStoryExcerpt(artwork) {
    if (!artwork.story_intro) return null;
    const text = artwork.story_intro;
    if (text.length <= 200) return text;
    return text.substring(0, 197) + '...';
  }
  
  // Use 'gallery' variant for better quality
  function getImageSource(artwork) {
    if (artwork && artwork.thumbnailId) {
      const ACCOUNT_HASH = '4bRSwPonOXfEIBVZiDXg0w';
      return `https://imagedelivery.net/${ACCOUNT_HASH}/${artwork.thumbnailId}/gallery`;
    }
    if (artwork && artwork.image_id) {
      const ACCOUNT_HASH = '4bRSwPonOXfEIBVZiDXg0w';
      return `https://imagedelivery.net/${ACCOUNT_HASH}/${artwork.image_id}/gallery`;
    }
    return null;
  }
</script>

<style>
  .sketchbook-container {
    width: 100%;
    max-width: 1100px;
    margin: 0 auto;
    padding: 1rem;
    perspective: 1200px;
    position: relative;
  }
  
  .sketchbook {
    position: relative;
    width: 100%;
    height: 650px;
    background: linear-gradient(135deg, #f8f7f4 0%, #edebe8 100%);
    border: 6px solid #d4c9a8;
    border-radius: 12px;
    box-shadow:
      0 10px 30px rgba(0,0,0,0.2),
      inset 0 0 15px rgba(212, 201, 168, 0.3);
    overflow: hidden;
    display: flex;
    transition: opacity 0.3s ease;
  }
  
  .sketchbook.animating {
    opacity: 0.7;
  }
  
  /* Left page - Story content */
  .page-left {
    width: 45%;
    height: 100%;
    padding: 3rem 2.5rem;
    display: flex;
    flex-direction: column;
    justify-content: center;
    border-right: 2px solid #d4c9a8;
    background: #fcfaf6;
    font-family: 'Georgia', serif;
  }
  
  .story-content {
    display: flex;
    flex-direction: column;
    gap: 1.5rem;
  }
  
  .artwork-meta {
    display: flex;
    flex-direction: column;
    gap: 0.5rem;
    padding-bottom: 1rem;
    border-bottom: 1px solid #e0d8c4;
  }
  
  .artwork-year {
    font-size: 0.85rem;
    color: #999;
    text-transform: uppercase;
    letter-spacing: 1px;
  }
  
  .artwork-title {
    font-size: 1.75rem;
    color: #2c5e3d;
    font-weight: 400;
    line-height: 1.3;
    margin: 0;
  }
  
  .story-text {
    font-size: 1.1rem;
    line-height: 1.8;
    color: #4a4a3c;
    font-style: italic;
  }
  
  .read-more {
    margin-top: auto;
    padding: 0.75rem 1.5rem;
    background: #2c5e3d;
    color: white;
    border: none;
    border-radius: 6px;
    font-size: 0.95rem;
    cursor: pointer;
    transition: all 0.3s ease;
    font-family: inherit;
    align-self: flex-start;
  }
  
  .read-more:hover {
    background: #234a30;
    transform: translateY(-2px);
    box-shadow: 0 4px 12px rgba(44, 94, 61, 0.3);
  }
  
  /* Right page - Artwork image */
  .page-right {
    width: 55%;
    height: 100%;
    padding: 2rem;
    display: flex;
    align-items: center;
    justify-content: center;
    background: #fcfaf6;
    cursor: pointer;
    transition: background 0.3s ease;
  }
  
  .page-right:hover {
    background: #f8f6f2;
  }
  
  .artwork-image {
    max-width: 100%;
    max-height: 100%;
    object-fit: contain;
    border-radius: 8px;
    box-shadow: 0 8px 24px rgba(0,0,0,0.15);
    transition: transform 0.3s ease, box-shadow 0.3s ease;
  }
  
  .page-right:hover .artwork-image {
    transform: scale(1.02);
    box-shadow: 0 12px 32px rgba(0,0,0,0.2);
  }
  
  /* Navigation arrows */
  .nav-arrow {
    position: absolute;
    top: 50%;
    transform: translateY(-50%);
    width: 50px;
    height: 50px;
    border: 2px solid #d4c9a8;
    background: rgba(255, 255, 255, 0.95);
    border-radius: 50%;
    font-size: 2rem;
    color: #4a4a3c;
    cursor: pointer;
    display: flex;
    align-items: center;
    justify-content: center;
    z-index: 10;
    transition: all 0.3s ease;
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
  
  .page-counter {
    position: absolute;
    bottom: 1rem;
    left: 50%;
    transform: translateX(-50%);
    font-size: 0.85rem;
    color: #999;
    font-style: italic;
    background: rgba(255, 255, 255, 0.8);
    padding: 0.5rem 1rem;
    border-radius: 20px;
  }
  
  /* Mobile responsive */
  @media (max-width: 968px) {
    .sketchbook {
      flex-direction: column;
      height: auto;
      min-height: 600px;
    }
    
    .page-left, .page-right {
      width: 100%;
    }
    
    .page-left {
      border-right: none;
      border-bottom: 2px solid #d4c9a8;
      padding: 2rem 1.5rem;
    }
    
    .artwork-title {
      font-size: 1.5rem;
    }
    
    .story-text {
      font-size: 1rem;
    }
    
    .page-right {
      min-height: 400px;
    }
  }
  
  @media (max-width: 768px) {
    .sketchbook-container {
      padding: 0.5rem;
    }
    
    .sketchbook {
      height: auto;
    }
    
    .page-left {
      padding: 1.5rem;
    }
    
    .artwork-title {
      font-size: 1.25rem;
    }
    
    .story-text {
      font-size: 0.95rem;
      line-height: 1.6;
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
    <div class="sketchbook" class:animating={isAnimating}>
      <!-- Left page: Story content -->
      <div class="page-left">
        {#if currentArtwork}
          <div class="story-content">
            <div class="artwork-meta">
              {#if currentArtwork.year}
                <span class="artwork-year">{currentArtwork.year}</span>
              {/if}
              <h2 class="artwork-title">
                {currentArtwork.display_name || currentArtwork.title}
              </h2>
            </div>
            
            {#if currentArtwork.story_intro}
              <p class="story-text">
                {getStoryExcerpt(currentArtwork)}
              </p>
              <button class="read-more" on:click={(e) => selectImage(e, currentArtwork)}>
                Read Full Story →
              </button>
            {:else}
              <p class="story-text">
                Click the image to explore this artwork...
              </p>
            {/if}
          </div>
        {/if}
      </div>
      
      <!-- Right page: Artwork image -->
      <div class="page-right" on:click={(e) => selectImage(e, currentArtwork)}>
        {#if currentArtwork}
          <img
            class="artwork-image"
            src={getImageSource(currentArtwork)}
            alt={currentArtwork.display_name || currentArtwork.title}
          />
        {/if}
      </div>
      
      <!-- Navigation -->
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
      
      <div class="page-counter">
        Page {currentPage + 1} of {totalPages}
      </div>
    </div>
  </div>
{/if}
