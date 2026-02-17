<!-- src/lib/components/Artwork3DShowcase.svelte -->
<script>
  import { t } from '$lib/i18n';
  import Image3DManipulator from './Image3DManipulator.svelte';
  import { CF_IMAGES_ACCOUNT_HASH } from '$lib/config.js';

  let { artworks } = $props();

  let selectedArtwork = $state(artworks?.[0] || null);
  let selectedIndex = $state(0);

  $: if (artworks && artworks.length > 0 && !selectedArtwork) {
    selectedArtwork = artworks[0];
  }

  function selectArtwork(artwork, index) {
    selectedArtwork = artwork;
    selectedIndex = index;
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

<section class="3d-showcase-section">
  <div class="showcase-header">
    <h2>{$t('pages.home.explore3D')}</h2>
    <p class="subtitle">{$t('pages.home.explore3DSubtitle')}</p>
  </div>

  <div class="showcase-container">
    <!-- Artwork Selector -->
    <div class="artwork-selector">
      <button class="nav-btn prev" onclick={prevArtwork} aria-label="Previous artwork">
        ←
      </button>
      
      <div class="thumbnail-strip">
        {#each artworks as artwork, i (artwork.id)}
          <button
            class="thumbnail {selectedArtwork?.id === artwork.id ? 'active' : ''}"
            onclick={() => selectArtwork(artwork, i)}
            aria-label="Select {artwork.title}"
          >
            <img src={getImageUrl(artwork)} alt={artwork.title} loading="lazy" />
          </button>
        {/each}
      </div>

      <button class="nav-btn next" onclick={nextArtwork} aria-label="Next artwork">
        →
      </button>
    </div>

    <!-- 3D Viewer -->
    <div class="viewer-container">
      {#if selectedArtwork}
        <div class="viewer-header">
          <h3>{selectedArtwork.title}</h3>
          {#if selectedArtwork.year}
            <span class="year">{selectedArtwork.year}</span>
          {/if}
        </div>
        
        <div class="manipulator-wrapper">
          <Image3DManipulator {imageUrl} />
        </div>

        <div class="viewer-instructions">
          <p>🖱️ {$t('3dart_dragRotate')}</p>
          <p>🔍 {$t('3dart_scrollZoom')}</p>
          <p>✋ {$t('3dart_pan')}</p>
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
  .3d-showcase-section {
    padding: 4rem 2rem;
    background: linear-gradient(180deg, #f5f5f5 0%, #fafafa 100%);
  }

  .showcase-header {
    text-align: center;
    margin-bottom: 3rem;
  }

  .showcase-header h2 {
    font-family: 'Georgia', serif;
    font-size: 2.5rem;
    font-weight: 300;
    color: #2c5e3d;
    margin: 0 0 1rem;
  }

  .subtitle {
    font-size: 1.1rem;
    color: #666;
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

  .nav-btn {
    width: 50px;
    height: 50px;
    border-radius: 50%;
    background: #2c5e3d;
    color: white;
    border: none;
    font-size: 1.5rem;
    cursor: pointer;
    transition: all 0.3s;
    display: flex;
    align-items: center;
    justify-content: center;
  }

  .nav-btn:hover {
    background: #1f4229;
    transform: scale(1.1);
  }

  .thumbnail-strip {
    display: flex;
    gap: 0.75rem;
    overflow-x: auto;
    flex: 1;
    padding: 0.5rem;
    scrollbar-width: thin;
    scrollbar-color: #2c5e3d #e0e0e0;
  }

  .thumbnail-strip::-webkit-scrollbar {
    height: 8px;
  }

  .thumbnail-strip::-webkit-scrollbar-track {
    background: #e0e0e0;
    border-radius: 4px;
  }

  .thumbnail-strip::-webkit-scrollbar-thumb {
    background: #2c5e3d;
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
    background: white;
  }

  .thumbnail:hover {
    transform: scale(1.05);
    border-color: #2c5e3d;
  }

  .thumbnail.active {
    border-color: #2c5e3d;
    box-shadow: 0 4px 12px rgba(44, 94, 61, 0.3);
  }

  .thumbnail img {
    width: 100%;
    height: 100%;
    object-fit: cover;
  }

  .viewer-container {
    background: white;
    border-radius: 16px;
    overflow: hidden;
    box-shadow: 0 8px 32px rgba(0, 0, 0, 0.12);
  }

  .viewer-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 1.5rem 2rem;
    background: linear-gradient(135deg, #f8f7f4 0%, #edebe8 100%);
    border-bottom: 1px solid #e0e0e0;
  }

  .viewer-header h3 {
    font-family: 'Georgia', serif;
    font-size: 1.5rem;
    color: #2c5e3d;
    margin: 0;
  }

  .year {
    font-size: 1rem;
    color: #999;
    font-style: italic;
  }

  .manipulator-wrapper {
    height: 500px;
    background: #f0f0f0;
  }

  .viewer-instructions {
    display: flex;
    justify-content: center;
    gap: 2rem;
    padding: 1.5rem;
    background: #f8f7f4;
    border-top: 1px solid #e0e0e0;
  }

  .viewer-instructions p {
    font-size: 0.9rem;
    color: #666;
    margin: 0;
  }

  .no-artwork {
    padding: 4rem;
    text-align: center;
    color: #999;
  }

  @media (max-width: 768px) {
    .3d-showcase-section {
      padding: 3rem 1rem;
    }

    .showcase-header h2 {
      font-size: 1.75rem;
    }

    .artwork-selector {
      flex-direction: column;
    }

    .nav-btn {
      width: 40px;
      height: 40px;
      font-size: 1.25rem;
    }

    .thumbnail-strip {
      width: 100%;
      justify-content: center;
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
