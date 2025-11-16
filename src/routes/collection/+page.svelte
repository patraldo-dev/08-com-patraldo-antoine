<!-- src/routes/collection/+page.svelte -->
<script>
  import { onMount } from 'svelte';
  import { goto } from '$app/navigation';
  import { t } from '$lib/translations';
  import { 
    getAllVisits, 
    getAllFavorites, 
    toggleFavorite, 
    getVisitStats,
    clearAllVisits,
    exportVisitData 
  } from '$lib/utils/visitTracker.js';
  
  const { data } = $props();
  const { allArtworks } = data;
  
  let visits = $state({});
  let favorites = $state(new Set());
  let stats = $state({});
  let filter = $state('visited'); // 'all' | 'visited' | 'favorites' | 'unvisited'
  let sortBy = $state('recent'); // 'recent' | 'frequent' | 'alphabetical'
  let showMenu = $state(false);
  
  onMount(() => {
    loadCollectionData();
    
    // Listen for updates
    window.addEventListener('artworkVisited', loadCollectionData);
    window.addEventListener('favoriteToggled', loadCollectionData);
    
    return () => {
      window.removeEventListener('artworkVisited', loadCollectionData);
      window.removeEventListener('favoriteToggled', loadCollectionData);
    };
  });
  
  function loadCollectionData() {
    visits = getAllVisits();
    favorites = getAllFavorites();
    stats = getVisitStats();
  }
  
  function handleToggleFavorite(artworkId, event) {
    event.preventDefault();
    event.stopPropagation();
    toggleFavorite(artworkId);
    loadCollectionData();
  }
  
  function openArtwork(artworkId) {
    goto(`/#artwork-${artworkId}`);
  }
  
  function handleClearAll() {
    if (confirm('Are you sure you want to clear all visit history?')) {
      clearAllVisits();
      loadCollectionData();
    }
  }
  
  function handleExport() {
    const data = exportVisitData();
    const blob = new Blob([data], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `collection-${new Date().toISOString().split('T')[0]}.json`;
    a.click();
    URL.revokeObjectURL(url);
  }
  
  function toggleMenu() {
    showMenu = !showMenu;
  }
  
  // Filter artworks based on selection
  let filteredArtworks = $derived(allArtworks.filter(artwork => {
    const isVisited = !!visits[artwork.id];
    const isFav = favorites.has(artwork.id.toString());
    
    switch(filter) {
      case 'visited': return isVisited;
      case 'favorites': return isFav;
      case 'unvisited': return !isVisited;
      case 'all':
      default: return true;
    }
  }));
  
  // Sort artworks
  let sortedArtworks = $derived([...filteredArtworks].sort((a, b) => {
    switch(sortBy) {
      case 'recent':
        const timeA = visits[a.id]?.lastVisited || 0;
        const timeB = visits[b.id]?.lastVisited || 0;
        return new Date(timeB) - new Date(timeA);
      case 'frequent':
        const countA = visits[a.id]?.viewCount || 0;
        const countB = visits[b.id]?.viewCount || 0;
        return countB - countA;
      case 'alphabetical':
        const nameA = (a.display_name || a.title).toLowerCase();
        const nameB = (b.display_name || b.title).toLowerCase();
        return nameA.localeCompare(nameB);
      default:
        return 0;
    }
  }));
  
  let visitedCount = $derived(Object.keys(visits).length);
  let favoritesCount = $derived(favorites.size);
</script>

<svelte:head>
  <title>My Collection - Antoine Patraldo</title>
</svelte:head>

<div class="collection-page">
  <header class="collection-header">
    <div class="header-content">
      <h1>My Collection</h1>
      <p class="subtitle">Track your journey through the artworks</p>
    </div>
    
    {#if sortedArtworks.length > 0}
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
  
  <div class="layout">
    <!-- Stats -->
    <div class="stats-grid">
      <div class="stat-card">
        <div class="stat-number">{visitedCount}</div>
        <div class="stat-label">Artworks Viewed</div>
      </div>
      <div class="stat-card">
        <div class="stat-number">{stats.totalViews || 0}</div>
        <div class="stat-label">Total Views</div>
      </div>
      <div class="stat-card">
        <div class="stat-number">{favoritesCount}</div>
        <div class="stat-label">Favorites</div>
      </div>
      <div class="stat-card">
        <div class="stat-number">{allArtworks.length - visitedCount}</div>
        <div class="stat-label">To Discover</div>
      </div>
    </div>
    
    <!-- Controls -->
    <div class="controls">
      <div class="filters">
        <button 
          class="filter-btn" 
          class:active={filter === 'all'}
          onclick={() => filter = 'all'}
        >
          All ({allArtworks.length})
        </button>
        <button 
          class="filter-btn" 
          class:active={filter === 'visited'}
          onclick={() => filter = 'visited'}
        >
          Visited ({visitedCount})
        </button>
        <button 
          class="filter-btn" 
          class:active={filter === 'favorites'}
          onclick={() => filter = 'favorites'}
        >
          ❤️ Favorites ({favoritesCount})
        </button>
        <button 
          class="filter-btn" 
          class:active={filter === 'unvisited'}
          onclick={() => filter = 'unvisited'}
        >
          Unvisited ({allArtworks.length - visitedCount})
        </button>
      </div>
      
      <div class="sort-controls">
        <label for="sort">Sort by:</label>
        <select id="sort" bind:value={sortBy}>
          <option value="recent">Recently Viewed</option>
          <option value="frequent">Most Viewed</option>
          <option value="alphabetical">Alphabetical</option>
        </select>
      </div>
      
      <div class="actions">
        <button class="action-btn" onclick={handleExport}>
          Export Data
        </button>
        <button class="action-btn danger" onclick={handleClearAll}>
          Clear History
        </button>
      </div>
    </div>
    
    <!-- Grid -->
    {#if sortedArtworks.length === 0}
      <div class="empty-state">
        <div class="empty-icon">🎨</div>
        <h2>No artworks found</h2>
        <p>Start exploring the gallery!</p>
        <a href="/" class="cta-button">Go to Gallery</a>
      </div>
    {:else}
      <div class="collection-grid">
        {#each sortedArtworks as artwork (artwork.id)}
          <div class="artwork-card" onclick={() => openArtwork(artwork.id)}>
            <div class="artwork-image">
              <img 
                src={artwork.thumbnailUrl} 
                alt={artwork.display_name || artwork.title}
                loading="lazy"
              />
              
              <!-- Favorite button -->
              <button 
                class="favorite-btn" 
                class:active={favorites.has(artwork.id.toString())}
                onclick={(e) => handleToggleFavorite(artwork.id, e)}
              >
                {favorites.has(artwork.id.toString()) ? '❤️' : '🤍'}
              </button>
              
              <!-- View count badge -->
              {#if visits[artwork.id]}
                <div class="view-count">
                  👁️ {visits[artwork.id].viewCount}
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
              {#if visits[artwork.id]}
                <p class="last-viewed">
                  Last viewed: {new Date(visits[artwork.id].lastVisited).toLocaleDateString()}
                </p>
              {/if}
            </div>
          </div>
        {/each}
      </div>
    {/if}
  </div>
</div>

<!-- Slide-out menu -->
{#if showMenu}
  <div class="menu-overlay" onclick={toggleMenu}></div>
  <nav class="slide-menu">
    <div class="menu-header">
      <h2>Collection</h2>
      <button class="close-button" onclick={toggleMenu}>×</button>
    </div>
    <ul class="menu-list">
      {#each sortedArtworks as artwork (artwork.id)}
        <li>
          <button class="menu-item" onclick={() => openArtwork(artwork.id)}>
            {#if artwork.thumbnailUrl}
              <img src={artwork.thumbnailUrl} alt="" class="menu-thumb" />
            {/if}
            <span class="menu-text">{artwork.display_name || artwork.title}</span>
          </button>
        </li>
      {/each}
    </ul>
  </nav>
{/if}

<style>
  .collection-page {
    min-height: 100vh;
    background: linear-gradient(180deg, #fafafa 0%, #ffffff 100%);
    padding-top: 80px;
  }
  
  .collection-header {
    max-width: 1200px;
    margin: 0 auto;
    padding: 3rem 2rem 2rem;
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
  
  .layout {
    max-width: 1200px;
    margin: 0 auto;
    padding: 0 2rem 4rem;
  }
  
  .stats-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
    gap: 1.5rem;
    margin-bottom: 3rem;
  }
  
  .stat-card {
    background: white;
    padding: 2rem;
    border-radius: 12px;
    text-align: center;
    box-shadow: 0 2px 8px rgba(0,0,0,0.08);
    border: 1px solid #e0e0e0;
    transition: all 0.3s ease;
  }
  
  .stat-card:hover {
    transform: translateY(-2px);
    box-shadow: 0 4px 12px rgba(0,0,0,0.12);
  }
  
  .stat-number {
    font-size: 2.5rem;
    font-weight: 700;
    color: #1a1a1a;
    margin-bottom: 0.5rem;
  }
  
  .stat-label {
    font-size: 0.9rem;
    color: #666;
    text-transform: uppercase;
    letter-spacing: 0.5px;
    font-weight: 500;
  }
  
  .controls {
    background: white;
    padding: 2rem;
    border-radius: 12px;
    margin-bottom: 3rem;
    box-shadow: 0 2px 8px rgba(0,0,0,0.08);
    border: 1px solid #e0e0e0;
  }
  
  .filters {
    display: flex;
    gap: 1rem;
    margin-bottom: 1.5rem;
    flex-wrap: wrap;
  }
  
  .filter-btn {
    padding: 0.75rem 1.5rem;
    border: 2px solid #e0e0e0;
    background: white;
    border-radius: 8px;
    cursor: pointer;
    transition: all 0.2s ease;
    font-size: 0.95rem;
    font-weight: 500;
  }
  
  .filter-btn:hover {
    background: #f5f5f5;
    border-color: #ccc;
  }
  
  .filter-btn.active {
    background: #1a1a1a;
    color: white;
    border-color: #1a1a1a;
  }
  
  .sort-controls {
    display: flex;
    align-items: center;
    gap: 1rem;
    margin-bottom: 1.5rem;
  }
  
  .sort-controls label {
    font-weight: 500;
    color: #1a1a1a;
  }
  
  .sort-controls select {
    padding: 0.5rem 1rem;
    border: 2px solid #e0e0e0;
    border-radius: 6px;
    font-size: 0.95rem;
    cursor: pointer;
    background: white;
  }
  
  .actions {
    display: flex;
    gap: 1rem;
    flex-wrap: wrap;
  }
  
  .action-btn {
    padding: 0.75rem 1.5rem;
    border: 2px solid #e0e0e0;
    background: white;
    border-radius: 8px;
    cursor: pointer;
    transition: all 0.2s ease;
    font-size: 0.9rem;
    font-weight: 500;
  }
  
  .action-btn:hover {
    background: #f5f5f5;
    border-color: #ccc;
  }
  
  .action-btn.danger {
    border-color: #dc3545;
    color: #dc3545;
  }
  
  .action-btn.danger:hover {
    background: #dc3545;
    color: white;
  }
  
  .collection-grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
    gap: 1.5rem;
  }
  
  .artwork-card {
    background: white;
    border-radius: 12px;
    overflow: hidden;
    cursor: pointer;
    transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
    border: 1px solid #e0e0e0;
  }
  
  .artwork-card:hover {
    transform: translateY(-4px);
    box-shadow: 0 12px 24px rgba(0,0,0,0.1);
    border-color: #ccc;
  }
  
  .artwork-image {
    position: relative;
    width: 100%;
    padding-top: 66.67%;
    background: #f5f5f5;
    overflow: hidden;
  }
  
  .artwork-image img {
    position: absolute;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    object-fit: cover;
    transition: transform 0.3s ease;
  }
  
  .artwork-card:hover .artwork-image img {
    transform: scale(1.05);
  }
  
  .favorite-btn {
    position: absolute;
    top: 0.75rem;
    right: 0.75rem;
    background: rgba(255, 255, 255, 0.95);
    border: none;
    width: 40px;
    height: 40px;
    border-radius: 50%;
    font-size: 1.3rem;
    cursor: pointer;
    transition: all 0.2s ease;
    display: flex;
    align-items: center;
    justify-content: center;
    z-index: 2;
  }
  
  .favorite-btn:hover {
    transform: scale(1.1);
    background: white;
  }
  
  .view-count {
    position: absolute;
    bottom: 0.75rem;
    left: 0.75rem;
    background: rgba(0, 0, 0, 0.75);
    color: white;
    padding: 0.25rem 0.75rem;
    border-radius: 20px;
    font-size: 0.85rem;
    font-weight: 500;
    z-index: 2;
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
    font-weight: 600;
    text-transform: uppercase;
    letter-spacing: 0.05em;
  }
  
  .card-content {
    padding: 1.25rem;
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
    margin: 0 0 0.5rem 0;
  }
  
  .last-viewed {
    font-size: 0.85rem;
    color: #666;
    margin: 0;
  }
  
  .empty-state {
    text-align: center;
    padding: 4rem 2rem;
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
    width: 100%;
    background: none;
    border: none;
    text-align: left;
    color: #1a1a1a;
    cursor: pointer;
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
  
  @media (max-width: 768px) {
    .collection-header {
      padding: 2rem 1.5rem 1.5rem;
    }
    
    .header-content h1 {
      font-size: 2rem;
    }
    
    .layout {
      padding: 0 1.5rem 3rem;
    }
    
    .stats-grid {
      grid-template-columns: repeat(2, 1fr);
      gap: 1rem;
    }
    
    .stat-card {
      padding: 1.5rem;
    }
    
    .stat-number {
      font-size: 2rem;
    }
    
    .collection-grid {
      grid-template-columns: repeat(auto-fill, minmax(240px, 1fr));
      gap: 1rem;
    }
    
    .filters {
      flex-direction: column;
    }
    
    .filter-btn {
      width: 100%;
    }
  }
  
  @media (max-width: 480px) {
    .collection-grid {
      grid-template-columns: 1fr;
    }
  }
</style>
