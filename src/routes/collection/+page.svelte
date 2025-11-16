<!-- src/routes/collection/+page.svelte -->
<script>
  import { onMount } from 'svelte';
  import { getVisitedArtworks } from '$lib/utils/visitTracker.js';
  
  const { data } = $props();
  let visitedArtworks = $state([]);
  let isLoading = $state(true);
  let showMenu = $state(false);
  
  onMount(() => {
    const visitedIds = getVisitedArtworks();
    
    // Filter artworks to only show visited ones
    visitedArtworks = data.allArtworks.filter(artwork => 
      visitedIds.includes(artwork.id)
    );
    
    isLoading = false;
  });
  
  function toggleMenu() {
    showMenu = !showMenu;
  }
</script>

<svelte:head>
  <title>Your Collection</title>
  <meta name="description" content="Artworks you've explored" />
</svelte:head>

<div class="collection-container">
  <header class="collection-header">
    <div class="header-content">
      <h1>Your Collection</h1>
      <p class="subtitle">
        {#if isLoading}
          Loading...
        {:else if visitedArtworks.length === 0}
          Start exploring to build your collection
        {:else}
          {visitedArtworks.length} {visitedArtworks.length === 1 ? 'artwork' : 'artworks'} discovered
        {/if}
      </p>
    </div>
    
    {#if visitedArtworks.length > 0}
      <button 
        class="menu-toggle" 
        onclick={toggleMenu}
        aria-label="Toggle menu"
      >
        <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor">
          <line x1="3" y1="6" x2="21" y2="6" stroke-width="2"/>
          <line x1="3" y1="12" x2="21" y2="12" stroke-width="2"/>
          <line x1="3" y1="18" x2="21" y2="18" stroke-width="2"/>
        </svg>
      </button>
    {/if}
  </header>

  {#if !isLoading && visitedArtworks.length === 0}
    <div class="empty-state">
      <div class="empty-icon">🎨</div>
      <h2>Your collection is empty</h2>
      <p>Visit artworks to add them to your personal collection</p>
      <a href="/" class="cta-button">Start Exploring</a>
    </div>
  {:else if !isLoading}
    <div class="artworks-grid">
      {#each visitedArtworks as artwork (artwork.id)}
        <a href="/artwork/{artwork.id}" class="artwork-card">
          <div class="card-image">
            {#if artwork.thumbnailUrl}
              <img 
                src={artwork.thumbnailUrl} 
                alt={artwork.title}
                loading="lazy"
              />
            {:else}
              <div class="placeholder">
                <span>No Image</span>
              </div>
            {/if}
            <div class="card-overlay">
              <span class="view-label">View</span>
            </div>
          </div>
          
          <div class="card-content">
            <h3 class="card-title">{artwork.display_name || artwork.title}</h3>
            {#if artwork.year}
              <p class="card-year">{artwork.year}</p>
            {/if}
            {#if artwork.description}
              <p class="card-description">{artwork.description}</p>
            {/if}
          </div>
        </a>
      {/each}
    </div>
  {/if}
</div>

{#if showMenu}
  <div class="menu-overlay" onclick={toggleMenu}></div>
  <nav class="slide-menu">
    <div class="menu-header">
      <h2>Collection</h2>
      <button class="close-button" onclick={toggleMenu}>×</button>
    </div>
    <ul class="menu-list">
      {#each visitedArtworks as artwork (artwork.id)}
        <li>
          <a href="/artwork/{artwork.id}" class="menu-item">
            {#if artwork.thumbnailUrl}
              <img src={artwork.thumbnailUrl} alt="" class="menu-thumb" />
            {/if}
            <span class="menu-text">{artwork.display_name || artwork.title}</span>
          </a>
        </li>
      {/each}
    </ul>
  </nav>
{/if}

<style>
  .collection-container {
    min-height: 100vh;
    background: linear-gradient(to bottom, #fafafa, #ffffff);
    padding: 2rem 1rem;
  }

  .collection-header {
    max-width: 1200px;
    margin: 0 auto 3rem;
    display: flex;
    justify-content: space-between;
    align-items: flex-start;
  }

  .header-content h1 {
    font-size: 2.5rem;
    font-weight: 600;
    color: #1a1a1a;
    margin: 0 0 0.5rem 0;
    letter-spacing: -0.02em;
  }

  .subtitle {
    font-size: 1rem;
    color: #666;
    margin: 0;
  }

  .menu-toggle {
    background: white;
    border: 1px solid #e0e0e0;
    border-radius: 8px;
    padding: 0.5rem;
    cursor: pointer;
    transition: all 0.2s ease;
    color: #666;
  }

  .menu-toggle:hover {
    background: #f5f5f5;
    border-color: #ccc;
  }

  /* Empty State */
  .empty-state {
    max-width: 500px;
    margin: 6rem auto;
    text-align: center;
    padding: 3rem 2rem;
  }

  .empty-icon {
    font-size: 4rem;
    margin-bottom: 1.5rem;
    opacity: 0.5;
  }

  .empty-state h2 {
    font-size: 1.75rem;
    font-weight: 600;
    color: #1a1a1a;
    margin: 0 0 1rem 0;
  }

  .empty-state p {
    color: #666;
    font-size: 1.1rem;
    margin: 0 0 2rem 0;
  }

  .cta-button {
    display: inline-block;
    background: #1a1a1a;
    color: white;
    padding: 0.875rem 2rem;
    border-radius: 8px;
    text-decoration: none;
    font-weight: 500;
    transition: all 0.2s ease;
  }

  .cta-button:hover {
    background: #333;
    transform: translateY(-1px);
    box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
  }

  /* Grid Layout */
  .artworks-grid {
    max-width: 1200px;
    margin: 0 auto;
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
    gap: 1.5rem;
  }

  /* Card Styling */
  .artwork-card {
    background: white;
    border-radius: 12px;
    overflow: hidden;
    text-decoration: none;
    color: inherit;
    transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
    border: 1px solid #e0e0e0;
    display: flex;
    flex-direction: column;
  }

  .artwork-card:hover {
    transform: translateY(-4px);
    box-shadow: 0 12px 24px rgba(0, 0, 0, 0.1);
    border-color: #ccc;
  }

  .card-image {
    position: relative;
    width: 100%;
    padding-top: 66.67%; /* 3:2 aspect ratio */
    background: #f5f5f5;
    overflow: hidden;
  }

  .card-image img {
    position: absolute;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    object-fit: cover;
    transition: transform 0.3s ease;
  }

  .artwork-card:hover .card-image img {
    transform: scale(1.05);
  }

  .placeholder {
    position: absolute;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    display: flex;
    align-items: center;
    justify-content: center;
    background: linear-gradient(135deg, #f5f5f5, #e8e8e8);
    color: #999;
    font-size: 0.875rem;
  }

  .card-overlay {
    position: absolute;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    background: linear-gradient(to top, rgba(0,0,0,0.6), transparent);
    opacity: 0;
    transition: opacity 0.3s ease;
    display: flex;
    align-items: flex-end;
    padding: 1rem;
  }

  .artwork-card:hover .card-overlay {
    opacity: 1;
  }

  .view-label {
    color: white;
    font-size: 0.875rem;
    font-weight: 500;
    text-transform: uppercase;
    letter-spacing: 0.05em;
  }

  .card-content {
    padding: 1.25rem;
    flex: 1;
    display: flex;
    flex-direction: column;
  }

  .card-title {
    font-size: 1.125rem;
    font-weight: 600;
    color: #1a1a1a;
    margin: 0 0 0.5rem 0;
    line-height: 1.4;
  }

  .card-year {
    font-size: 0.875rem;
    color: #999;
    margin: 0 0 0.75rem 0;
  }

  .card-description {
    font-size: 0.9375rem;
    color: #666;
    line-height: 1.5;
    margin: 0;
    display: -webkit-box;
    -webkit-line-clamp: 2;
    -webkit-box-orient: vertical;
    overflow: hidden;
  }

  /* Slide-out Menu */
  .menu-overlay {
    position: fixed;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    background: rgba(0, 0, 0, 0.5);
    z-index: 998;
    animation: fadeIn 0.2s ease;
  }

  .slide-menu {
    position: fixed;
    top: 0;
    right: 0;
    bottom: 0;
    width: 320px;
    max-width: 90vw;
    background: white;
    z-index: 999;
    box-shadow: -4px 0 24px rgba(0, 0, 0, 0.15);
    animation: slideIn 0.3s cubic-bezier(0.4, 0, 0.2, 1);
    display: flex;
    flex-direction: column;
  }

  .menu-header {
    padding: 1.5rem;
    border-bottom: 1px solid #e0e0e0;
    display: flex;
    justify-content: space-between;
    align-items: center;
  }

  .menu-header h2 {
    font-size: 1.25rem;
    font-weight: 600;
    margin: 0;
    color: #1a1a1a;
  }

  .close-button {
    background: none;
    border: none;
    font-size: 2rem;
    color: #666;
    cursor: pointer;
    padding: 0;
    width: 32px;
    height: 32px;
    display: flex;
    align-items: center;
    justify-content: center;
    border-radius: 4px;
    transition: background 0.2s ease;
  }

  .close-button:hover {
    background: #f5f5f5;
  }

  .menu-list {
    list-style: none;
    padding: 0;
    margin: 0;
    overflow-y: auto;
    flex: 1;
  }

  .menu-item {
    display: flex;
    align-items: center;
    gap: 1rem;
    padding: 1rem 1.5rem;
    text-decoration: none;
    color: #1a1a1a;
    transition: background 0.2s ease;
    border-bottom: 1px solid #f5f5f5;
  }

  .menu-item:hover {
    background: #f9f9f9;
  }

  .menu-thumb {
    width: 48px;
    height: 48px;
    object-fit: cover;
    border-radius: 6px;
    flex-shrink: 0;
  }

  .menu-text {
    font-size: 0.9375rem;
    font-weight: 500;
    line-height: 1.4;
  }

  @keyframes fadeIn {
    from { opacity: 0; }
    to { opacity: 1; }
  }

  @keyframes slideIn {
    from { transform: translateX(100%); }
    to { transform: translateX(0); }
  }

  /* Responsive */
  @media (max-width: 768px) {
    .collection-container {
      padding: 1.5rem 1rem;
    }

    .header-content h1 {
      font-size: 2rem;
    }

    .artworks-grid {
      grid-template-columns: repeat(auto-fill, minmax(240px, 1fr));
      gap: 1rem;
    }
  }

  @media (max-width: 480px) {
    .artworks-grid {
      grid-template-columns: 1fr;
    }
  }
</style>
