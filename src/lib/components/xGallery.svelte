<script>
  import ArtPiece from './ArtPiece.svelte';
  import { CF_IMAGES_ACCOUNT_HASH } from '$lib/config.js';
  
  // Sample artwork data - update with your actual Cloudflare Images IDs
  const artworks = [
    {
      id: 1,
      title: "Mujer Face",
      type: "still",
      imageUrl: `https://antoine.patraldo.com/cdn-cgi/imagedelivery/${CF_IMAGES_ACCOUNT_HASH}/92c712f4-aec1-4e68-1cec-fcd9682eae00/full`,
      thumbnailId: "92c712f4-aec1-4e68-1cec-fcd9682eae00",
      description: "Charcoal and digital manipulation, 2024",
      year: 2024
    },
    {
      id: 2,
      title: "Temporal Fragments",
      type: "animation",
      imageUrl: `https://antoine.patraldo.com/cdn-cgi/imagedelivery/${CF_IMAGES_ACCOUNT_HASH}/your-second-image-id/full`,
      thumbnailId: "your-second-image-id",
      description: "Video installation, 3:42 min, 2024",
      year: 2024
    }
    // Add more artworks as needed
  ];
  
  let selectedType = 'all';
  
  $: filteredArtworks = selectedType === 'all' 
    ? artworks 
    : artworks.filter(artwork => artwork.type === selectedType);
  
  const artworkTypes = [
    { value: 'all', label: 'All Work' },
    { value: 'still', label: 'Still Images' },
    { value: 'animation', label: 'Videos' },
    { value: 'gif', label: 'Animated GIFs' }
  ];
</script>

<div class="gallery">
  <div class="container">
    <div class="header">
      <h3>Recent Work</h3>
      
      <div class="filter-container">
        <select bind:value={selectedType} class="filter-select">
          {#each artworkTypes as type}
            <option value={type.value}>{type.label}</option>
          {/each}
        </select>
      </div>
    </div>
    
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
  </div>
</div>

<style>
  .gallery {
    padding: 2rem 0;
  }
  
  .container {
    max-width: 1200px;
    margin: 0 auto;
    padding: 0 2rem;
  }
  
  .header {
    text-align: center;
    margin-bottom: 3rem;
  }
  
  h3 {
    font-size: 2.5rem;
    font-weight: 200;
    margin-bottom: 2rem;
    color: #2a2a2a;
  }
  
  .filter-container {
    display: flex;
    justify-content: center;
    margin-bottom: 1rem;
  }
  
  .filter-select {
    padding: 0.75rem 1.5rem;
    font-size: 1rem;
    border: 2px solid #e0e0e0;
    border-radius: 6px;
    background: white;
    color: #2a2a2a;
    cursor: pointer;
    outline: none;
    transition: border-color 0.3s, box-shadow 0.3s;
    font-family: inherit;
    width: 100%;
    max-width: 300px;
  }
  
  .filter-select:hover {
    border-color: #667eea;
  }
  
  .
