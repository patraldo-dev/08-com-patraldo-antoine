<script>
  import ArtPiece from './ArtPiece.svelte';
  import { onMount } from 'svelte';
  
  // Your Cloudflare Images account hash
  const CF_IMAGES_ACCOUNT_HASH = "4bRSwPonOXfEIBVZiDXg0w"; // Replace with your actual hash
  
  console.log("Gallery component loaded");
  console.log("Account hash:", CF_IMAGES_ACCOUNT_HASH);
  
  // Sample artwork data - update with your actual image IDs
  const artworks = [
    {
      id: 1,
      title: "Mujer Face",
      type: "still",
      r2Url: `https://imagedelivery.net/${CF_IMAGES_ACCOUNT_HASH}/mujer-face/full`,
      thumbnailId: "mujer-face",
      description: "Charcoal and digital manipulation, 2024",
      year: 2024
    },
    {
      id: 2,
      title: "Temporal Fragments",
      type: "animation",
      r2Url: `https://imagedelivery.net/${CF_IMAGES_ACCOUNT_HASH}/temporal-fragments/full`,
      thumbnailId: "temporal-fragments",
      description: "Video installation, 3:42 min, 2024",
      year: 2024
    }
  ];
  
  console.log("Artworks data:", artworks);
  
  let selectedType = 'all';
  
  $: filteredArtworks = selectedType === 'all' 
    ? artworks 
    : artworks.filter(artwork => artwork.type === selectedType);
  
  console.log("Filtered artworks:", filteredArtworks);
  
  const artworkTypes = [
    { value: 'all', label: 'All Work' },
    { value: 'still', label: 'Still Images' },
    { value: 'animation', label: 'Videos' },
    { value: 'gif', label: 'Animated GIFs' }
  ];
  
  onMount(() => {
    console.log("Gallery component mounted");
  });
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
  }
  .filter-select:hover {
    border-color: #667eea;
  }
  .filter-select:focus {
    border-color: #667eea;
    box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.1);
  }
  .grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(350px, 1fr));
    gap: 2rem;
    transition: all 0.3s ease;
  }
  .no-results {
    text-align: center;
    padding: 4rem 0;
    color: #666;
    font-style: italic;
  }
  @media (max-width: 768px) {
    .container {
      padding: 0 1rem;
    }
    
    .grid {
      grid-template-columns: 1fr;
      gap: 1.5rem;
    }
    
    h3 {
      font-size: 2rem;
    }
  }
</style>
