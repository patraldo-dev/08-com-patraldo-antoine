<script>
  import ArtPiece from './ArtPiece.svelte';
  import { onMount } from 'svelte';
  import { CF_IMAGES_ACCOUNT_HASH, CUSTOM_DOMAIN } from '$lib/config.js';
  
  let artworks = [];
  let loading = true;
  let error = null;
  
  // Function to create Cloudflare Images URL with custom domain and variant
  function createImageUrl(imageId, variant = '') {
    const baseUrl = `https://${CUSTOM_DOMAIN}/cdn-cgi/imagedelivery/${CF_IMAGES_ACCOUNT_HASH}/${imageId}`;
    return variant ? `${baseUrl}/${variant}` : baseUrl;
  }
  
  // Function to create Cloudflare Stream URL
  function createVideoUrl(videoId) {
    return `https://customer-<your-account-id>.cloudflarestream.com/${videoId}/downloads/default.mp4`;
  }
  
  async function loadArtworks() {
    try {
      const response = await fetch('/api/artworks');
      if (!response.ok) {
        throw new Error('Failed to fetch artworks');
      }
      const data = await response.json();
      
      // Transform the data to include URLs
      artworks = data.map(artwork => ({
        ...artwork,
        imageUrl: artwork.type === 'still' || artwork.type === 'gif' 
          ? createImageUrl(artwork.image_id, 'desktop')
          : undefined,
        thumbnailId: artwork.image_id,
        videoUrl: artwork.video_id ? createVideoUrl(artwork.video_id) : undefined
      }));
    } catch (err) {
      error = err.message;
      console.error('Error loading artworks:', err);
    } finally {
      loading = false;
    }
  }
  
  onMount(() => {
    loadArtworks();
  });
  
  let selectedType = 'all';
  
  $: filteredArtworks = selectedType === 'all' 
    ? artworks 
    : artworks.filter(artwork => artwork.type === selectedType);
  
  const artworkTypes = [
    { value: 'all', label: 'Obras Completas' },
    { value: 'still', label: 'Dibujos' },
    { value: 'animation', label: 'Videos' },
    { value: 'gif', label: 'GIFs' }
  ];
</script>

<div class="gallery">
  <div class="container">
    <div class="header">
      <h3>Obra destacada</h3>
      
      <div class="filter-container">
        <select bind:value={selectedType} class="filter-select">
          {#each artworkTypes as type}
            <option value={type.value}>{type.label}</option>
          {/each}
        </select>
      </div>
    </div>
    
    {#if loading}
      <div class="loading-container">
        <p>Loading artworks...</p>
      </div>
    {:else if error}
      <div class="error-container">
        <p>Error: {error}</p>
      </div>
    {:else}
      <div class="grid">
        {#each filteredArtworks as artwork (artwork.id)}
          <ArtPiece {artwork} />
        {/each}
      </div>
      
      {#if filteredArtworks.length === 0}
        <div class="no-results">
          <p>No {selectedType} artworks to display yet.</p>
        </div>
      {/if}
    {/if}
  </div>
</div>

<style>
  /* Keep existing styles */
  
  .loading-container,
  .error-container {
    text-align: center;
    padding: 4rem 0;
    color: #666;
  }
  
  .error-container {
    color: #e53e3e;
  }
</style>
