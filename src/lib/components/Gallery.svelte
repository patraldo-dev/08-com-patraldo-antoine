<script>
  import ArtPiece from './ArtPiece.svelte';
  import { onMount } from 'svelte';
 
  // Sample artwork data - update with your actual URLs
  const artworks = [
{
      id: 1,
      title: "Metamorphosis Series #1",
      type: "still",
      r2Url: "https://antoine-patraldo.r2.cloudflarestorage.com/MujerFaceAntoine.jpg",
      thumbnailId: "thumb-meta-1",
      description: "Charcoal and digital manipulation, 2024",
      year: 2024
    },
    {
      id: 2,
      title: "Temporal Fragments",
      type: "animation",
      r2Url: "https://antoine-patraldo.r2.cloudflarestorage.com/MujerFaceAntoine.jpg",
      thumbnailId: "thumb-temporal",
      description: "Video installation, 3:42 min, 2024",
      year: 2024
    },
    {
      id: 3,
      title: "Memory Loop",
      type: "gif",
      r2Url: "https://antoine-patraldo.r2.cloudflarestorage.com/MujerFaceAntoine.jpg",
      thumbnailId: "thumb-memory",
      description: "Animated sequence, 2024",
      year: 2024
    },
    {
      id: 4,
      title: "Digital Archaeology",
      type: "still",
      r2Url: "https://antoine-patraldo.r2.cloudflarestorage.com/MujerFaceAntoine.jpg",
      thumbnailId: "thumb-arch",
      description: "Mixed media on canvas, 2024",
      year: 2024
    },
    {
      id: 5,
      title: "Fluid Motion Study",
      type: "animation",
      r2Url: "https://antoine-patraldo.r2.cloudflarestorage.com/MujerFaceAntoine.jpg",
      thumbnailId: "thumb-fluid",
      description: "Video study, 1:20 min, 2023",
      year: 2023
    },
    {
      id: 6,
      title: "Glitch Portrait",
      type: "gif",
      r2Url: "https://antoine-patraldo.r2.cloudflarestorage.com/MujerFaceAntoine.jpg",
      thumbnailId: "thumb-glitch",
      description: "Digital manipulation, 2023",
      year: 2023
    }
  ];
  
  let config = null;
  let configError = null;
  let selectedType = 'all';
  
  $: filteredArtworks = selectedType === 'all' 
    ? artworks 
    : artworks.filter(artwork => artwork.type === selectedType);
  
  $: CF_IMAGES_BASE = config ? `https://imagedelivery.net/${config.cfImagesAccountHash}` : "";
  
  const artworkTypes = [
    { value: 'all', label: 'All Work' },
    { value: 'still', label: 'Still Images' },
    { value: 'animation', label: 'Videos' },
    { value: 'gif', label: 'Animated GIFs' }
  ];
  
  onMount(async () => {
    try {
      const response = await fetch('/api/config');
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }
      config = await response.json();
    } catch (error) {
      console.error('Failed to load configuration:', error);
      configError = error.message;
    }
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
    
    {#if configError}
      <div class="error-message">
        <p>Error loading gallery: {configError}</p>
        <p>Please check your configuration and try again.</p>
      </div>
    {:else if !CF_IMAGES_BASE}
      <div class="loading-gallery">
        <p>Loading gallery...</p>
      </div>
    {:else}
      <div class="grid">
        {#each filteredArtworks as artwork (artwork.id)}
          <ArtPiece {artwork} {CF_IMAGES_BASE} />
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
  /* Add these new styles */
  .error-message {
    text-align: center;
    padding: 2rem;
    background: #f8d7da;
    color: #721c24;
    border-radius: 8px;
    margin: 2rem 0;
  }
  
  .loading-gallery {
    text-align: center;
    padding: 3rem;
    color: #666;
  }
  
  /* Keep existing styles */
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
