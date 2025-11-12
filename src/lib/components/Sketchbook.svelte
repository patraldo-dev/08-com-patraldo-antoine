<script>
  import { onMount, onDestroy } from 'svelte';
  import { t, locale } from '$lib/translations';  
  import ArtPiece from './ArtPiece.svelte';

  export let artworks = [];
  export let maxPages = 6;

  let currentPage = 0;
  let selectedImage = null;
  let isFlipping = false;
  let pageRight;

  let flipSound, selectSound;

  onMount(async () => {
    flipSound = new Audio('/sounds/page-flip.mp3');
    selectSound = new Audio('/sounds/select.mp3');
  });

  // reactively get current locale from i18n's store
  $: currentLocale = $locale;  // Correct: subscribe directly to locale store

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
  /* Keep your existing styles here */
</style>

{#if selectedImage}
  <div class="selected-image-view" role="dialog" aria-label="Selected artwork view">
    <button class="back-button" on:click={goBackToSketchbook} aria-label="Go back to sketchbook">
      ← {t('common.back')}
    </button>
    <ArtPiece image={selectedImage} interactive={true} />
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
            <img src={artworks[currentPage - 1].src} alt={artworks[currentPage - 1].title} loading="lazy" />
          </div>
        {:else}
          <span class="placeholder">...</span>
        {/if}
      </div>
    </div>
  </div>
{/if}

