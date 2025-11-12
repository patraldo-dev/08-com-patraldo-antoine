<!-- src/lib/components/Sketchbook.svelte -->
<script>
  import { onMount, onDestroy } from 'svelte';
  import { t, locale } from '$lib/translations';
  // Import ArtPiece for the detailed view when an artwork is selected
  import ArtPiece from './ArtPiece.svelte';

  export let artworks = [];
  export let maxPages = 6;

  // Debug log to verify data received
  $: console.log("🖼️ Sketchbook component received artworks:", artworks);

  let currentPage = 0;
  let selectedImage = null; // State for the selected artwork details view
  let isFlipping = false;
  let pageRight;

  let flipSound, selectSound;

  onMount(async () => {
    flipSound = new Audio('/sounds/page-flip.mp3');
    selectSound = new Audio('/sounds/select.mp3');
  });

  // Reactively get current locale from i18n's store
  $: currentLocale = $locale;

  $: promptText = {
    'es-MX': 'Un dibujo cada día. Una historia cada semana.',
    'en-US': 'A drawing each day. A story each week.',
    'fr-CA': 'Un dessin chaque jour. Une histoire chaque semaine.'
  }[currentLocale] || 'Un dibujo cada día. Una historia cada semana.';

  async function flipPage() {
    if (isFlipping || currentPage >= maxPages - 1) return;

    isFlipping = true;

    if (pageRight) {
      pageRight.classList.add('flipping');

      if (flipSound) {
        flipSound.currentTime = 0;
        try {
          await flipSound.play();
        } catch (e) {
          console.log('Audio play failed');
        }
      }
    }

    setTimeout(() => {
      currentPage++;
      isFlipping = false;
      if (pageRight) pageRight.classList.remove('flipping');
    }, 600);
  }

  function selectImage(image) {
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
    flipSound = null;
    selectSound = null;
  });
</script>

<style>
  .sketchbook-container {
    width: 100%;
    max-width: 800px;
    margin: 0 auto;
    padding: 1rem;
    perspective: 1200px;
  }

  .sketchbook {
    position: relative;
    width: 100%;
    height: 500px; /* Adjust as needed */
    background: linear-gradient(135deg, #f8f7f4 0%, #edebe8 100%);
    border: 6px solid #d4c9a8; /* Linen/canvas texture */
    border-radius: 12px;
    box-shadow:
      0 10px 30px rgba(0,0,0,0.2),
      inset 0 0 15px rgba(212, 201, 168, 0.3);
    overflow: hidden;
    cursor: pointer;
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
  }

  .page-left {
    left: 0;
    border-right: 1px dotted #ccc;
    background: #fcfaf6;
  }

  .page-right {
    right: 0;
    background: #fcfaf6;
    transition: transform 0.6s ease-in-out;
    transform-origin: left center;
  }

  .page-right.flipping {
    animation: flipPage 0.6s ease-in-out forwards;
  }

  @keyframes flipPage {
    0% { transform: rotateY(0deg); }
    50% { transform: rotateY(-90deg); }
    100% { transform: rotateY(-180deg); }
  }

  .prompt-text {
    font-size: 1.1rem;
    line-height: 1.6;
    text-align: center;
    color: #4a4a3c;
    opacity: 0.9;
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
    width: 100%;
    height: 100%;
    display: flex;
    flex-direction: column;
    background: #000;
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
  }

  .back-button:hover {
    background: #f8f7f4;
    color: #2c5e3d;
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

{#if selectedImage}
  <!-- Show the selected artwork in detail using ArtPiece -->
  <div class="selected-image-view" role="dialog" aria-label="Selected artwork view">
    <button class="back-button" on:click={goBackToSketchbook} aria-label="Go back to sketchbook">
      ← {t('common.back')}
    </button>
    <!-- Pass the selected artwork object to ArtPiece -->
    <ArtPiece artwork={selectedImage} />
  </div>
{:else}
  <div class="sketchbook-container" role="main" aria-label="Interactive sketchbook">
    <div class="sketchbook" on:click={flipPage} tabindex="0" on:keydown={(e) => e.key === 'Enter' && flipPage()}>
      <div class="page-left">
        <div class="prompt-text">{promptText}</div>
        <div class="page-number">
          {currentPage > 0 ? `Página ${currentPage + 1}` : ''}
        </div>
      </div>
      <div class="page-right" bind:this={pageRight}>
        {#if currentPage > 0 && artworks[currentPage - 1]}
          <div
            class="art-thumbnail"
            on:click|stopPropagation={() => selectImage(artworks[currentPage - 1])}
            role="button"
            aria-label={`Select artwork: ${artworks[currentPage - 1].title}`}
            tabindex="0"
            on:keydown={(e) => e.key === 'Enter' && selectImage(artworks[currentPage - 1])}
          >
            <!-- Use the thumbnailId property from the artwork object to construct the Cloudflare Images URL -->
            <img
              src={`https://antoine.patraldo.com/cdn-cgi/imagedelivery/4bRSwPonOXfEIBVZiDXg0w/${artworks[currentPage - 1].thumbnailId}/thumbnail`}
              alt={artworks[currentPage - 1].title}
              loading="lazy"
            />
          </div>
        {:else}
          <span class="placeholder">...</span>
        {/if}
      </div>
    </div>
  </div>
{/if}
