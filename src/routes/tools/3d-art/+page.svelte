<script>
  import { onMount } from 'svelte';
  import { t } from '$lib/i18n/index.js';
  import Image3DManipulator from '$lib/components/Image3DManipulator.svelte';
  import { CF_IMAGES_ACCOUNT_HASH } from '$lib/config.js';
  import { getThumbnailUrl } from '$lib/cloudflare/images.js';
  
  let { data } = $props();
  
  // Reference to 3D manipulator methods
  let image3DMethods = $state(null);
  
  let selectedArtwork = $state(data.artworks?.[0] || null);
  let isSaving = $state(false);
  let isResetting = $state(false);
  let saveMessage = $state('');
  let messageType = $state('success');
  
  let filterType = $state('all');
  let filterFeatured = $state(false);
  
  let filteredArtworks = $derived(() => {
    let results = data.artworks || [];
    
    if (filterType !== 'all') {
      results = results.filter(artwork => artwork.type === filterType);
    }
    
    if (filterFeatured) {
      results = results.filter(artwork => artwork.featured);
    }
    
    return results;
  });
  
  let imageUrl = $derived(
    selectedArtwork && selectedArtwork.imageId
      ? `https://imagedelivery.net/${CF_IMAGES_ACCOUNT_HASH}/${selectedArtwork.imageId}/gallery`
      : ''
  );
  
  onMount(() => {
    setTimeout(() => {
      if (window.image3DMethods) {
        image3DMethods = window.image3DMethods;
      }
    }, 100);
  });
  
  async function saveTransform() {
    if (!image3DMethods || !selectedArtwork) return;
    
    isSaving = true;
    saveMessage = '';
    
    try {
      const transform = image3DMethods.transform;
      
      const response = await fetch(`/api/artworks/${selectedArtwork.id}/transform`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ transform })
      });
      
      const result = await response.json();
      
      if (result.success) {
        saveMessage = $t('3dart_successSaved');
        messageType = 'success';
      } else {
        saveMessage = $t('3dart_saveFailed') + ' ' + result.error;
        messageType = 'error';
      }
    } catch (error) {
      console.error('Save error:', error);
      saveMessage = $t('3dart_unknownError') + ' ' + error.message;
      messageType = 'error';
    } finally {
      isSaving = false;
      setTimeout(() => { saveMessage = ''; }, 3000);
    }
  }
  
  async function resetTransform() {
    if (!image3DMethods || !selectedArtwork) return;
    
    isResetting = true;
    saveMessage = '';
    
    try {
      const response = await fetch(`/api/artworks/${selectedArtwork.id}/transform`, {
        method: 'DELETE'
      });
      
      const result = await response.json();
      
      if (result.success) {
        saveMessage = $t('3dart_successReset');
        messageType = 'success';
        
        // Reset component
        image3DMethods.resetTransform();
      } else {
        saveMessage = $t('3dart_resetFailed') + ' ' + result.error;
        messageType = 'error';
      }
    } catch (error) {
      console.error('Reset error:', error);
      saveMessage = $t('3dart_unknownError') + ' ' + error.message;
      messageType = 'error';
    } finally {
      isResetting = false;
      setTimeout(() => { saveMessage = ''; }, 3000);
    }
  }
  
  function selectArtwork(artwork) {
    selectedArtwork = artwork;
  }
  
  function typeLabel(type) {
    const labels = {
      'still': 'Imagen Fija',
      'animation': 'Animación',
      'gif': 'GIF',
      'video': 'Video',
      'mixed': 'Medios Mixtos'
    };
    return labels[type] || type;
  }
</script>

<svelte:head>
  <title>{$t('3dart_title')}</title>
  <meta name="description" content={$t('3dart_description')} />
</svelte:head>

<div class="page">
  <header>
    <h1>{$t('3dart_title')}</h1>
    <p>{$t('3dart_description')}</p>
  </header>

  <div class="controls">
    <div class="filter-group">
      <label for="type-filter">{$t('3dart_type')}:</label>
      <select id="type-filter" bind:value={filterType}>
        <option value="all">{$t('3dart_allTypes')}</option>
        <option value="still">{typeLabel('still')}</option>
        <option value="animation">{typeLabel('animation')}</option>
        <option value="gif">{typeLabel('gif')}</option>
        <option value="video">{typeLabel('video')}</option>
        <option value="mixed">{typeLabel('mixed')}</option>
      </select>
      
      <label class="checkbox-label">
        <input type="checkbox" bind:checked={filterFeatured} />
        {$t('3dart_featuredOnly')}
      </label>
    </div>
  </div>

  {#if saveMessage}
    <div class="message {messageType}">
      {saveMessage}
    </div>
  {/if}

  <div class="main-content">
    <aside class="sidebar">
      <h2>{$t('3dart_artworks')} ({filteredArtworks().length})</h2>
      <div class="artwork-list">
        {#each filteredArtworks() as artwork}
          <button
            class="artwork-item"
            class:active={selectedArtwork?.id === artwork.id}
            onclick={() => selectArtwork(artwork)}
          >
            <img
              src={artwork.imageId ? getThumbnailUrl(artwork.imageId) : ''}
              alt={artwork.title}
              loading="lazy"
            />
            <div class="artwork-info">
              <span class="artwork-title">{artwork.title}</span>
              <span class="artwork-meta">
                {typeLabel(artwork.type)} • {artwork.year}
              </span>
            </div>
            {#if artwork.featured}
              <span class="featured-badge">★</span>
            {/if}
          </button>
        {/each}
      </div>
    </aside>

    <div class="manipulator-container">
      {#if selectedArtwork}
        <div class="manipulator-wrapper">
           {#key imageUrl}
          <svelte:component this={Image3DManipulator} {imageUrl} />
            {/key}

          <div class="instructions">
            <p>{$t('3dart_instructions')}</p>
          </div>
        </div>

        <aside class="artwork-details">
          <h2>{selectedArtwork.title}</h2>
          <p class="artwork-year">{selectedArtwork.year}</p>
          <p class="artwork-description">{selectedArtwork.description}</p>
          
          <div class="artwork-tags">
            <span class="tag">{typeLabel(selectedArtwork.type)}</span>
            {#if selectedArtwork.featured}
              <span class="tag featured">{$t('3dart_tag_featured')}</span>
            {/if}
          </div>
        </aside>
      {:else}
        <div class="placeholder">
          <div class="placeholder-content">
            <p>{$t('3dart_selectArtwork')}</p>
          </div>
        </div>
      {/if}
    </div>
  </div>
</div>

<style>
  .page {
    display: flex;
    flex-direction: column;
    min-height: 100vh;
    padding: 20px;
    box-sizing: border-box;
    gap: 20px;
  }

  header {
    text-align: center;
  }

  header h1 {
    margin: 0 0 8px 0;
    font-size: 2rem;
  }

  header p {
    margin: 0;
    color: #666;
  }

  .controls {
    display: flex;
    justify-content: center;
    gap: 16px;
    padding: 16px;
    background: #f9fafb;
    border-radius: 8px;
  }

  .filter-group {
    display: flex;
    align-items: center;
    gap: 12px;
  }

  .filter-group label {
    font-weight: 500;
    color: #374151;
  }

  .filter-group select {
    padding: 8px 12px;
    border: 1px solid #d1d5db;
    border-radius: 6px;
    background: white;
    font-size: 14px;
  }

  .checkbox-label {
    display: flex;
    align-items: center;
    gap: 6px;
    cursor: pointer;
  }

  .checkbox-label input {
    width: 16px;
    height: 16px;
    cursor: pointer;
  }

  .message {
    padding: 12px 20px;
    border-radius: 6px;
    text-align: center;
    font-weight: 500;
  }

  .message.success {
    background: #d1fae5;
    color: #065f46;
  }

  .message.error {
    background: #fee2e2;
    color: #991b1b;
  }

  .main-content {
    display: grid;
    grid-template-columns: 280px 1fr;
    gap: 20px;
  }

  .sidebar {
    background: #f9fafb;
    border-radius: 12px;
    padding: 16px;
    display: flex;
    flex-direction: column;
    gap: 12px;
    max-height: calc(100vh - 280px);
  }

  .sidebar h2 {
    margin: 0;
    font-size: 1.125rem;
    padding-bottom: 8px;
    border-bottom: 1px solid #e5e7eb;
  }

  .artwork-list {
    flex: 1;
    overflow-y: auto;
    display: flex;
    flex-direction: column;
    gap: 8px;
  }

  .artwork-item {
    display: flex;
    align-items: center;
    gap: 12px;
    padding: 8px;
    background: white;
    border: 2px solid transparent;
    border-radius: 8px;
    cursor: pointer;
    transition: all 0.2s;
  }

  .artwork-item:hover {
    border-color: #d1d5db;
  }

  .artwork-item.active {
    border-color: #3b82f6;
    background: #eff6ff;
  }

  .artwork-item img {
    width: 48px;
    height: 48px;
    object-fit: cover;
    border-radius: 4px;
  }

  .artwork-info {
    flex: 1;
    min-width: 0;
  }

  .artwork-title {
    display: block;
    font-weight: 500;
    font-size: 14px;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
  }

  .artwork-meta {
    display: block;
    font-size: 12px;
    color: #6b7280;
  }

  .featured-badge {
    color: #f59e0b;
    font-size: 16px;
  }

  .manipulator-container {
    display: flex;
    flex-direction: column;
    gap: 16px;
  }

  .manipulator-wrapper {
    border: 2px solid #e5e7eb;
    border-radius: 12px;
    overflow: hidden;
    min-height: 500px;
    position: relative;
  }

  .instructions {
    position: absolute;
    bottom: 16px;
    left: 50%;
    transform: translateX(-50%);
    background: rgba(0, 0, 0, 0.7);
    color: white;
    padding: 8px 16px;
    border-radius: 20px;
    font-size: 14px;
    pointer-events: none;
    opacity: 0;
    transition: opacity 0.3s;
  }

  .manipulator-wrapper:hover .instructions {
    opacity: 1;
  }

  .artwork-details {
    background: #f9fafb;
    border-radius: 12px;
    padding: 20px;
  }

  .artwork-details h2 {
    margin: 0 0 4px 0;
    font-size: 1.5rem;
  }

  .artwork-year {
    margin: 0 0 16px 0;
    color: #6b7280;
    font-size: 0.875rem;
  }

  .artwork-description {
    color: #374151;
    line-height: 1.6;
    margin-bottom: 16px;
  }

  .artwork-tags {
    display: flex;
    flex-wrap: wrap;
    gap: 8px;
    margin-bottom: 20px;
  }

  .tag {
    padding: 4px 12px;
    background: #e5e7eb;
    border-radius: 12px;
    font-size: 12px;
    font-weight: 500;
    color: #374151;
  }

  .tag.featured {
    background: #fef3c7;
    color: #92400e;
  }

  .placeholder {
    flex: 1;
    display: flex;
    align-items: center;
    justify-content: center;
    background: #f9fafb;
    border: 2px dashed #e5e7eb;
    border-radius: 12px;
    min-height: 500px;
  }

  .placeholder-content {
    text-align: center;
    color: #9ca3af;
  }

  /* Tablet */
  @media (max-width: 1024px) {
    .main-content {
      grid-template-columns: 1fr;
    }
    .sidebar {
      max-height: 300px;
    }
    .artwork-list {
      flex-direction: row;
      overflow-x: auto;
      overflow-y: visible;
    }
    .artwork-item {
      min-width: 250px;
    }
  }

  /* Mobile - SINGLE CLEAN MEDIA QUERY */
  @media (max-width: 768px) {
    .page {
      padding: 12px;
      gap: 12px;
    }

    header h1 {
      font-size: 1.5rem;
    }

    .controls {
      flex-direction: column;
      gap: 8px;
      padding: 12px;
    }

    .filter-group {
      flex-wrap: wrap;
      justify-content: center;
      gap: 8px;
    }

    .filter-group select {
      font-size: 13px;
      padding: 6px 10px;
    }

    /* Canvas on TOP, Thumbnails on BOTTOM */
    .main-content {
      display: flex !important;
      flex-direction: column !important;
      gap: 16px !important;
    }

    .manipulator-wrapper {
      min-height: 450px !important;
      height: 65vh !important;
      width: 100% !important;
      position: relative !important;
      margin-bottom: 16px !important;
    }

    .manipulator-wrapper :global(.image-3d-container) {
      position: absolute !important;
      top: 0 !important;
      left: 0 !important;
      width: 100% !important;
      height: 100% !important;
    }

    /* Thumbnails - STABLE ON BOTTOM */
    .sidebar {
      z-index: 100 !important;
      position: relative !important;
      background: white !important;
      border-radius: 12px !important;
      max-height: 160px !important;
      min-height: 140px !important;
      padding: 12px !important;
    }

    .sidebar h2 {
      font-size: 0.9rem !important;
      margin-bottom: 8px !important;
    }

    .artwork-list {
      display: flex !important;
      flex-direction: row !important;
      overflow-x: auto !important;
      overflow-y: hidden !important;
      gap: 12px !important;
      padding: 8px 0 !important;
      -webkit-overflow-scrolling: touch !important;
    }

    .artwork-item {
      min-width: 90px !important;
      max-width: 90px !important;
      flex: 0 0 auto !important;
      flex-direction: column !important;
      padding: 8px !important;
      gap: 6px !important;
      background: white !important;
    }

    .artwork-item.active {
      border-color: transparent !important;
      background: white !important;
      box-shadow: 0 0 0 3px #3b82f6, 0 4px 12px rgba(59, 130, 246, 0.3) !important;
      transform: scale(1.05) !important;
    }

    .artwork-item:hover {
      border-color: transparent !important;
    }

    .artwork-item img {
      width: 74px !important;
      height: 74px !important;
      border-radius: 6px !important;
    }

    .artwork-info {
      text-align: center !important;
      width: 100% !important;
    }

    .artwork-title {
      font-size: 10px !important;
      line-height: 1.2 !important;
      display: -webkit-box !important;
      -webkit-line-clamp: 2 !important;
      -webkit-box-orient: vertical !important;
      overflow: hidden !important;
    }

    .artwork-meta {
      font-size: 9px !important;
    }

    .featured-badge {
      position: absolute !important;
      top: 4px !important;
      right: 4px !important;
      font-size: 14px !important;
    }

    .artwork-details {
      display: none !important;
    }

    .instructions {
      font-size: 12px !important;
      padding: 6px 12px !important;
      bottom: 8px !important;
    }
  }
</style>

