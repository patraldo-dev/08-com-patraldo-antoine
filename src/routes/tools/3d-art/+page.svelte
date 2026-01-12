<script>
  import { t } from '$lib/i18n/index.js';
  import Image3DManipulator from '$lib/components/Image3DManipulator.svelte';
  import { getArtworkImageUrl, getThumbnailUrl } from '$lib/cloudflare/images.js';
  
  let { data } = $props();
  
  /** @type {import('svelte').ComponentType} */
  let manipulator;
  
  // State
  let selectedArtwork = $state(data.artworks[0] || null);
  let isSaving = $state(false);
  let isResetting = $state(false);
  let saveMessage = $state('');
  let messageType = $state('success');
  
  // Filter options
  let filterType = $state('all');
  let filterFeatured = $state(false);
  
  // Computed values
  let filteredArtworks = $derived(() => {
    let results = data.artworks;
    
    if (filterType !== 'all') {
      results = results.filter(artwork => artwork.type === filterType);
    }
    
    if (filterFeatured) {
      results = results.filter(artwork => artwork.featured);
    }
    
    return results;
  });
  
  let imageUrl = $derived(
    selectedArtwork 
      ? getArtworkImageUrl({ CLOUDFLARE_ACCOUNT_ID: data.cloudflareAccountId }, selectedArtwork)
      : ''
  );
  
  // Helper function to get artwork type label
  function typeLabel(type) {
    const key = `3dart_type_${type}`;
    return $t(key) || type;
  }
  
  // Actions
  async function saveTransform() {
    if (!manipulator || !selectedArtwork) return;
    
    isSaving = true;
    saveMessage = '';
    
    try {
      const transform = manipulator.transform;
      
      const response = await fetch(`/api/artworks/${selectedArtwork.id}/transform`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ transform })
      });
      
      const result = await response.json();
      
      if (result.success) {
        saveMessage = $t('3dart_successSaved');
        messageType = 'success';
        // Update local state
        selectedArtwork.transform = transform;
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
    if (!selectedArtwork) return;
    
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
        if (manipulator) {
          manipulator.resetTransform();
        }
        
        // Update local state
        selectedArtwork.transform = {
          rotation: { x: 0, y: 0, z: 0 },
          position: { x: 0, y: 0, z: 0 },
          scale: { x: 1, y: 1, z: 1 }
        };
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

  <!-- Filters and Controls -->
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

    <div class="action-group">
      {#if selectedArtwork}
        <button 
          onclick={saveTransform} 
          disabled={isSaving} 
          class="btn-primary"
        >
          {isSaving ? $t('3dart_saving') : $t('3dart_save')}
        </button>

        <button 
          onclick={resetTransform} 
          disabled={isResetting} 
          class="btn-secondary"
        >
          {isResetting ? $t('3dart_resetting') : $t('3dart_reset')}
        </button>
      {/if}
    </div>
  </div>

  {#if saveMessage}
    <div class="message {messageType}">
      {saveMessage}
    </div>
  {/if}

  <div class="main-content">
    <!-- Artwork Selector Sidebar -->
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
              src={getThumbnailUrl({ CLOUDFLARE_ACCOUNT_ID: data.cloudflareAccountId }, artwork.imageId)}
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
        
        {#if filteredArtworks().length === 0}
          <p class="no-results">{$t('3dart_noArtworks')}</p>
        {/if}
      </div>
    </aside>

    <!-- 3D Manipulator -->
    <div class="manipulator-container">
      {#if selectedArtwork}
        <div class="manipulator-wrapper">
          <svelte:component 
            this={Image3DManipulator} 
            {imageUrl} 
            bind:this={manipulator}
          />
          
          <div class="instructions">
            <p>{$t('3dart_instructions')}</p>
          </div>
        </div>

        <!-- Artwork Details -->
        <aside class="artwork-details">
          <h2>{selectedArtwork.title}</h2>
          <p class="artwork-year">{selectedArtwork.year}</p>
          <p class="artwork-description">{selectedArtwork.description}</p>
          
          <div class="artwork-tags">
            <span class="tag">{typeLabel(selectedArtwork.type)}</span>
            {#if selectedArtwork.featured}
              <span class="tag featured">{$t('3dart_tag_featured')}</span>
            {/if}
            {#if selectedArtwork.isCinematic}
              <span class="tag cinematic">{$t('3dart_tag_cinematic')}</span>
            {/if}
          </div>
          
          {#if selectedArtwork.transform}
            <div class="transform-info">
              <h3>{$t('3dart_currentTransform')}</h3>
              <div class="transform-grid">
                <div>
                  <span class="label">{$t('3dart_rotation')}:</span>
                  <span class="value">
                    X={selectedArtwork.transform.rotation.x.toFixed(2)}
                    Y={selectedArtwork.transform.rotation.y.toFixed(2)}
                    Z={selectedArtwork.transform.rotation.z.toFixed(2)}
                  </span>
                </div>
                <div>
                  <span class="label">{$t('3dart_position')}:</span>
                  <span class="value">
                    X={selectedArtwork.transform.position.x.toFixed(2)}
                    Y={selectedArtwork.transform.position.y.toFixed(2)}
                    Z={selectedArtwork.transform.position.z.toFixed(2)}
                  </span>
                </div>
                <div>
                  <span class="label">{$t('3dart_scale')}:</span>
                  <span class="value">
                    X={selectedArtwork.transform.scale.x.toFixed(2)}
                    Y={selectedArtwork.transform.scale.y.toFixed(2)}
                    Z={selectedArtwork.transform.scale.z.toFixed(2)}
                  </span>
                </div>
              </div>
            </div>
          {/if}
        </aside>
      {:else}
        <div class="placeholder">
          <div class="placeholder-content">
            <svg width="64" height="64" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
              <rect x="3" y="3" width="18" height="18" rx="2" ry="2"></rect>
              <circle cx="8.5" cy="8.5" r="1.5"></circle>
              <polyline points="21 15 16 10 5 21"></polyline>
            </svg>
            <p>{$t('3dart_selectArtwork')}</p>
            <p class="hint">{$t('3dart_selectHint')}</p>
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
    justify-content: space-between;
    align-items: center;
    flex-wrap: wrap;
    gap: 16px;
    padding: 16px;
    background: #f9fafb;
    border-radius: 8px;
  }

  .filter-group {
    display: flex;
    align-items: center;
    gap: 12px;
    flex-wrap: wrap;
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

  .action-group {
    display: flex;
    gap: 8px;
  }

  .btn-primary {
    padding: 10px 20px;
    background: #10b981;
    color: white;
    border: none;
    border-radius: 6px;
    cursor: pointer;
    font-weight: 500;
    transition: background 0.2s;
  }

  .btn-primary:hover:not(:disabled) {
    background: #059669;
  }

  .btn-primary:disabled {
    opacity: 0.5;
    cursor: not-allowed;
  }

  .btn-secondary {
    padding: 10px 20px;
    background: #6b7280;
    color: white;
    border: none;
    border-radius: 6px;
    cursor: pointer;
    font-weight: 500;
    transition: background 0.2s;
  }

  .btn-secondary:hover:not(:disabled) {
    background: #4b5563;
  }

  .btn-secondary:disabled {
    opacity: 0.5;
    cursor: not-allowed;
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
    flex: 1;
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
    text-align: left;
    width: 100%;
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

  .no-results {
    text-align: center;
    color: #6b7280;
    padding: 20px;
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

  .tag.cinematic {
    background: #dbeafe;
    color: #1e40af;
  }

  .transform-info {
    padding-top: 20px;
    border-top: 1px solid #e5e7eb;
  }

  .transform-info h3 {
    margin: 0 0 12px 0;
    font-size: 1rem;
  }

  .transform-grid {
    display: flex;
    flex-direction: column;
    gap: 8px;
  }

  .transform-grid > div {
    display: flex;
    gap: 8px;
  }

  .transform-grid .label {
    font-weight: 500;
    min-width: 80px;
    color: #374151;
  }

  .transform-grid .value {
    font-family: monospace;
    font-size: 14px;
    color: #6b7280;
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

  .placeholder-content svg {
    margin-bottom: 16px;
    color: #d1d5db;
  }

  .placeholder-content p {
    margin: 4px 0;
  }

  .placeholder-content .hint {
    font-size: 14px;
  }

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

  @media (max-width: 768px) {
    .controls {
      flex-direction: column;
      align-items: stretch;
    }

    .filter-group,
    .action-group {
      flex-direction: column;
    }

    .filter-group select {
      width: 100%;
    }

    .btn-primary,
    .btn-secondary {
      width: 100%;
    }

    header h1 {
      font-size: 1.5rem;
    }
  }
</style>
