<!-- src/lib/components/Artwork3DShowcase.svelte -->
<script>
  import { t } from '$lib/i18n';
  import Image3DManipulator from './Image3DManipulator.svelte';
  import { CF_IMAGES_ACCOUNT_HASH } from '$lib/config.js';
  import { onMount } from 'svelte';
  import { checkARSupport } from '$lib/ar-detect.js';

  let { artworks } = $props();

  let arStatus = $state('hidden');
  onMount(async () => { arStatus = await checkARSupport(); });

  let selectedArtwork = $state(artworks?.[0] || null);
  let selectedIndex = $state(0);
  let thumbnailStrip;

  let imageUrl = $derived(
    selectedArtwork && selectedArtwork.image_id
      ? `https://imagedelivery.net/${CF_IMAGES_ACCOUNT_HASH}/${selectedArtwork.image_id}/gallery`
      : ''
  );

  function selectArtwork(artwork, index) {
    selectedArtwork = artwork;
    selectedIndex = index;
    
    // Scroll thumbnail strip to keep active thumbnail visible
    setTimeout(() => {
      if (thumbnailStrip) {
        const activeThumbnail = thumbnailStrip.querySelector('.thumbnail.active');
        if (activeThumbnail) {
          activeThumbnail.scrollIntoView({ behavior: 'smooth', block: 'nearest', inline: 'center' });
        }
      }
    }, 50);
  }

  function nextArtwork() {
    if (!artworks || artworks.length === 0) return;
    const nextIndex = (selectedIndex + 1) % artworks.length;
    selectArtwork(artworks[nextIndex], nextIndex);
  }

  function prevArtwork() {
    if (!artworks || artworks.length === 0) return;
    const prevIndex = (selectedIndex - 1 + artworks.length) % artworks.length;
    selectArtwork(artworks[prevIndex], prevIndex);
  }

  function getImageUrl(artwork) {
    if (!artwork?.image_id) return '';
    return `https://imagedelivery.net/${CF_IMAGES_ACCOUNT_HASH}/${artwork.image_id}/gallery`;
  }
</script>

<section class="showcase-3d-section">
  <div class="showcase-container">
    <!-- Artwork Selector -->
    <div class="artwork-selector">
      <div class="nav-buttons">
        <button class="nav-btn first" onclick={() => selectArtwork(artworks[0], 0)} aria-label="First artwork">
          ⏮
        </button>

        <button class="nav-btn prev" onclick={prevArtwork} aria-label="Previous artwork">
          ←
        </button>
      </div>

      <div class="thumbnail-strip" bind:this={thumbnailStrip}>
        <div class="scroll-spacer"></div>
        {#each artworks as artwork, i (artwork.id)}
          <button
            class="thumbnail {selectedArtwork?.id === artwork.id ? 'active' : ''}"
            onclick={() => selectArtwork(artwork, i)}
            aria-label="Select {artwork.title}"
          >
            <img src={getImageUrl(artwork)} alt={artwork.title} loading="lazy" />
          </button>
        {/each}
        <div class="scroll-spacer right"></div>
      </div>

      <div class="nav-buttons">
        <button class="nav-btn next" onclick={nextArtwork} aria-label="Next artwork">
          →
        </button>

        <button class="nav-btn last" onclick={() => selectArtwork(artworks[artworks.length - 1], artworks.length - 1)} aria-label="Last artwork">
          ⏭
        </button>
      </div>
    </div>

    <!-- 3D Viewer -->
    <div class="viewer-container">
      {#if selectedArtwork}
        <div class="viewer-header">
          <h3>{selectedArtwork.display_name || selectedArtwork.title}</h3>
          {#if selectedArtwork.year}
            <span class="year">{selectedArtwork.year}</span>
          {/if}
          {#if arStatus === 'supported'}
            <a class="ar-btn" href="/ar/image/{selectedArtwork.image_id}" rel="prefetch">👤 Ver en AR</a>
          {:else if arStatus === 'teaser'}
            <span class="ar-btn teaser">👤 AR</span>
          {/if}
        </div>
        
        <div class="manipulator-wrapper">
          {#key imageUrl}
            <Image3DManipulator {imageUrl} />
          {/key}
        </div>

        <div class="viewer-instructions">
          <p>🖱️ {$t('3dart_dragRotate')}</p>
          <p>🔍 {$t('3dart_scrollZoom')}</p>
          <p>✋ {$t('3dart_pan')}</p>
          <p class="mobile-hint">{$t('3dart_mobileHint')}</p>
        </div>
      {:else}
        <div class="no-artwork">
          <p>{$t('pages.home.noArtwork3D')}</p>
        </div>
      {/if}
    </div>
  </div>
</section>

<style>
  .showcase-3d-section {
    padding: 4rem 2rem;
    background: linear-gradient(180deg, var(--color-bg) 0%, var(--color-bg) 100%);
  }

  .showcase-header {
    text-align: center;
    margin-bottom: 3rem;
  }

  .showcase-header h2 {
    font-family: 'Georgia', serif;
    font-size: 2.5rem;
    font-weight: 300;
    color: var(--color-green);
    margin: 0 0 1rem;
  }

  .subtitle {
    font-size: 1.1rem;
    color: var(--color-text-muted);
    font-style: italic;
  }

  .showcase-container {
    max-width: 1200px;
    margin: 0 auto;
  }

  .artwork-selector {
    display: flex;
    align-items: center;
    gap: 1rem;
    margin-bottom: 2rem;
  }

  .nav-buttons {
    display: flex;
    flex-direction: column;
    gap: 0.5rem;
  }

  .nav-btn {
    width: 50px;
    height: 50px;
    border-radius: 50%;
    background: var(--color-green);
    color: var(--color-surface-raised);
    border: none;
    font-size: 1.5rem;
    cursor: pointer;
    transition: all 0.3s;
    display: flex;
    align-items: center;
    justify-content: center;
  }

  .nav-btn:hover {
    background: var(--color-green-hover);
    transform: scale(1.1);
  }

  .thumbnail-strip {
    display: flex;
    gap: 0.75rem;
    overflow-x: auto;
    flex: 1;
    padding: 0.5rem 0;
    scrollbar-width: thin;
    scrollbar-color: var(--color-green) var(--color-border);
    scroll-snap-type: x proximity;
  }

  .scroll-spacer {
    flex-shrink: 0;
    width: 0.25rem;
  }

  .scroll-spacer.right {
    width: 0.75rem;
  }

  .thumbnail-strip::-webkit-scrollbar {
    height: 8px;
  }

  .thumbnail-strip::-webkit-scrollbar-track {
    background: var(--color-border);
    border-radius: 4px;
  }

  .thumbnail-strip::-webkit-scrollbar-thumb {
    background: var(--color-green);
    border-radius: 4px;
  }

  .thumbnail {
    flex-shrink: 0;
    width: 80px;
    height: 80px;
    border-radius: 8px;
    overflow: hidden;
    border: 3px solid transparent;
    cursor: pointer;
    transition: all 0.3s;
    background: var(--color-surface-raised);
  }

  .thumbnail:hover {
    transform: scale(1.05);
    border-color: var(--color-green);
  }

  .thumbnail.active {
    border-color: var(--color-green);
    box-shadow: 0 4px 12px rgba(44, 94, 61, 0.2);
  }

  .thumbnail img {
    width: 100%;
    height: 100%;
    object-fit: cover;
  }

  .viewer-container {
    background: var(--color-surface-raised);
    border-radius: 16px;
    overflow: hidden;
    box-shadow: 0 8px 32px var(--color-border);
  }

  .viewer-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 1.5rem 2rem;
    background: linear-gradient(135deg, var(--color-surface) 0%, var(--color-bg) 100%);
    border-bottom: 1px solid var(--color-border);
  }

  .viewer-header h3 {
    font-family: 'Georgia', serif;
    font-size: 1.5rem;
    color: var(--color-green);
    margin: 0;
  }

  .year {
    font-size: 1rem;
    color: var(--color-text-muted);
    font-style: italic;
  }

  .ar-btn {
    background: var(--color-gold);
    color: var(--color-text);
    border: none;
    padding: 0.4rem 1rem;
    border-radius: 20px;
    font-size: 0.85rem;
    font-weight: 600;
    cursor: pointer;
    white-space: nowrap;
    transition: transform 0.1s;
  }
  .ar-btn:hover { transform: scale(1.05); }
  .ar-btn.teaser { opacity: 0.4; pointer-events: none; }
  .ar-btn.video.teaser { opacity: 0.4; pointer-events: none; }

  .manipulator-wrapper {
    height: 500px;
    background: var(--color-surface);
  }

  .viewer-instructions {
    display: flex;
    justify-content: center;
    gap: 2rem;
    padding: 1.5rem;
    background: var(--color-surface);
    border-top: 1px solid var(--color-border);
  }

  .viewer-instructions p {
    font-size: 0.9rem;
    color: var(--color-text-muted);
    margin: 0;
  }

  .no-artwork {
    padding: 4rem;
    text-align: center;
    color: var(--color-text-muted);
  }

  @media (max-width: 768px) {
    .showcase-3d-section {
      padding: 2rem 1rem;
    }

    .showcase-header h2 {
      font-size: 1.5rem;
    }

    .artwork-selector {
      flex-direction: column;
    }

    .nav-buttons {
      flex-direction: row;
      justify-content: center;
    }

    .nav-btn {
      width: 40px;
      height: 40px;
      font-size: 1.25rem;
    }

    .thumbnail-strip {
      width: 100%;
      justify-content: flex-start;
      padding: 0.5rem 0;
      scroll-padding: 0 0.5rem;
    }

    .scroll-spacer {
      width: 0.5rem;
    }

    .scroll-spacer.right {
      width: 0.5rem;
    }

    .thumbnail {
      width: 60px;
      height: 60px;
    }

    .manipulator-wrapper {
      height: 350px;
    }

    .viewer-header {
      padding: 1rem 1.5rem;
      flex-direction: column;
      gap: 0.5rem;
      text-align: center;
    }

    .viewer-instructions {
      flex-direction: column;
      gap: 0.75rem;
      padding: 1rem;
    }
  }
</style>
