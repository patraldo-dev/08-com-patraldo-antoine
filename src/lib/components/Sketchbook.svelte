<!-- src/lib/components/Sketchbook.svelte -->
<script>
  import { onMount, onDestroy } from 'svelte';
  import { locale, t } from '$lib/i18n';
  import StoryView from './StoryView.svelte';
  
  export let artworks = [];
  
  let currentSpread = 0; // Track spreads (pairs) instead of individual pages
  let selectedImage = null;
  let flipSound, selectSound;
  
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
    const totalSpreads = Math.ceil(artworks.length / 2);
    if (currentSpread < totalSpreads - 1) {
      if (flipSound) {
        flipSound.currentTime = 0;
        flipSound.play().catch(() => {});
      }
      currentSpread++;
    }
  }
  
  function prevSpread() {
    if (currentSpread > 0) {
      if (flipSound) {
        flipSound.currentTime = 0;
        flipSound.play().catch(() => {});
      }
      currentSpread--;
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
  }
  
  onDestroy(() => {
    if (flipSound) flipSound.remove();
    if (selectSound) selectSound.remove();
  });
  
  // Calculate which artworks to show
  $: leftIndex = currentSpread * 2;
  $: rightIndex = currentSpread * 2 + 1;
  $: leftArtwork = artworks[leftIndex] || null;
  $: rightArtwork = artworks[rightIndex] || null;
  $: totalSpreads = Math.ceil(artworks.length / 2);
  
  $: promptText = getPromptText($locale);
  function getPromptText(currentLocale) {
    const prompts = {
      'es': 'Un dibujo cada día. Una historia cada semana.',
      'en': 'A drawing each day. A story each week.',
      'fr': 'Un dessin chaque jour. Une histoire chaque semaine.'
    };
    return prompts[currentLocale] || prompts['es'];
  }
  
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

{#if selectedImage}
  <StoryView 
    artwork={selectedImage}
    on:close={goBackToSketchbook}
  />
{:else}
  <div class="sketchbook-container">
    <div class="sketchbook">
      <!-- Left page -->
      <div class="page-left">
        {#if leftArtwork}
          <div class="art-thumbnail" on:click={(e) => selectImage(e, leftArtwork)}>
            <img
              src={getImageSource(leftArtwork)}
              alt={leftArtwork.display_name || leftArtwork.title}
              title="Click to explore this story"
            />
            <div class="sketch-title">{leftArtwork.display_name || leftArtwork.title}</div>
          </div>
        {:else if currentSpread === 0}
          <div class="prompt-text">{promptText}</div>
        {:else}
          <span class="placeholder">·</span>
        {/if}
      </div>
      
      <!-- Right page -->
      <div class="page-right">
        {#if rightArtwork}
          <div class="art-thumbnail" on:click={(e) => selectImage(e, rightArtwork)}>
            <img
              src={getImageSource(rightArtwork)}
              alt={rightArtwork.display_name || rightArtwork.title}
              title="Click to explore this story"
            />
            <div class="sketch-title">{rightArtwork.display_name || rightArtwork.title}</div>
          </div>
        {:else}
          <span class="placeholder">·</span>
        {/if}
      </div>
      
      <!-- Navigation -->
      {#if currentSpread > 0}
        <button class="nav-arrow prev" on:click={prevSpread} aria-label="Previous spread">
          ‹
        </button>
      {/if}
      
      {#if currentSpread < totalSpreads - 1}
        <button class="nav-arrow next" on:click={nextSpread} aria-label="Next spread">
          ›
        </button>
      {/if}
      
      <!-- Spread counter with i18n -->
      <div class="page-number">
        {$t('sketchbook.spread')} {currentSpread + 1} {$t('sketchbook.of')} {totalSpreads}
      </div>
    </div>
  </div>
{/if}

<style>
  .sketchbook-container {
    width: 100%;
    max-width: 900px;
    margin: 0 auto;
    padding: 0.5rem;
    perspective: 1200px;
    position: relative;
  }
  
  .sketchbook {
    position: relative;
    width: 100%;
    height: 600px;
    background: linear-gradient(135deg, #f8f7f4 0%, #edebe8 100%);
    border: 6px solid #d4c9a8;
    border-radius: 12px;
    box-shadow:
      0 10px 30px rgba(0,0,0,0.2),
      inset 0 0 15px rgba(212, 201, 168, 0.3);
    overflow: hidden;
    user-select: none;
  }
  
  .page-left, .page-right {
    position: absolute;
    top: 0;
    width: 50%;
    height: 100%;
    padding: 2.5rem;
    display: flex;
    flex-direction: column;
    justify-content: center;
    align-items: center;
    font-family: 'Georgia', serif;
  }
  
  .page-left {
    left: 0;
    border-right: 1px dotted #ccc;
    background: #fcfaf6;
  }
  
  .page-right {
    right: 0;
    background: #fcfaf6;
  }
  
  .prompt-text {
    font-size: 1.2rem;
    line-height: 1.6;
    text-align: center;
    color: #4a4a3c;
    opacity: 0.9;
    font-style: italic;
    padding: 0 1rem;
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
    gap: 0.75rem;
  }
  
  .art-thumbnail img {
    max-width: 95%;
    max-height: 85%;
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
  
  .sketch-title {
    font-size: 1rem;
    color: #4a4a3c;
    text-align: center;
    font-style: italic;
    max-width: 90%;
  }
  
  .nav-arrow {
    position: absolute;
    top: 50%;
    transform: translateY(-50%);
    width: 50px;
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
  
  .page-number {
    position: absolute;
    bottom: 1rem;
    left: 50%;
    transform: translateX(-50%);
    font-size: 0.85rem;
    color: #666;
    font-style: italic;
    background: rgba(255, 255, 255, 0.8);
    padding: 0.5rem 1rem;
    border-radius: 20px;
  }
  
  @media (max-width: 768px) {
    .sketchbook-container {
      max-width: 100%;
      padding: 0.25rem;
    }
    
    .sketchbook {
      height: 500px;
    }
    
    .page-left, .page-right {
      padding: 1.5rem;
    }
    
    .prompt-text {
      font-size: 1rem;
    }
    
    .sketch-title {
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
