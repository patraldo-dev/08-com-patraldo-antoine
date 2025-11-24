    <!-- src/routes/collection/+page.svelte -->
<script>
  import { onMount } from 'svelte';
  import { goto } from '$app/navigation';
  import { t } from '$lib/i18n';
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
  let filter = $state('all');
  let sortBy = $state('recent');
  let showMenu = $state(false);
  let showToast = $state(false);
  let toastMessage = $state('');
  let selectedMood = $state('');

  // Mood filter options - MOVE THIS UP HERE
  const moodOptions = [
    { value: '', label: 'tags.filter.all' },
    { value: 'melancholic', label: 'tags.mood.melancholic' },
    { value: 'vibrant', label: 'tags.mood.vibrant' },
    { value: 'surreal', label: 'tags.mood.surreal' },
    { value: 'playful', label: 'tags.mood.playful' },
    { value: 'contemplative', label: 'tags.mood.contemplative' },
    { value: 'energetic', label: 'tags.mood.energetic' },
    { value: 'calm', label: 'tags.mood.calm' },
    { value: 'mysterious', label: 'tags.mood.mysterious' }
  ];

  onMount(() => {
    loadCollectionData();
    
    window.addEventListener('artworkVisited', loadCollectionData);
    window.addEventListener('favoriteToggled', loadCollectionData);
    window.addEventListener('visitsCleared', loadCollectionData);
    
    return () => {
      window.removeEventListener('artworkVisited', loadCollectionData);
      window.removeEventListener('favoriteToggled', loadCollectionData);
      window.removeEventListener('visitsCleared', loadCollectionData);
    };
  });
  
  function loadCollectionData() {
    visits = getAllVisits();
    favorites = getAllFavorites();
    stats = getVisitStats();
  }

  let filteredArtworks = $derived(allArtworks.filter(artwork => {
    const isVisited = !!visits[artwork.id];
    const isFav = favorites.has(artwork.id.toString());
    
    // Apply mood filter first
    if (selectedMood && (!artwork.tags || !artwork.tags.includes(selectedMood))) {
      return false;
    }
    
    // Then apply existing collection filters
    switch(filter) {
      case 'visited': return isVisited;
      case 'favorites': return isFav;
      case 'unvisited': return !isVisited;
      case 'all':
      default: return true;
    }
  }));
  
  function handleToggleFavorite(artworkId, event) {
    event.preventDefault();
    event.stopPropagation();
    
    const wasFavorite = favorites.has(artworkId.toString());
    toggleFavorite(artworkId);
    loadCollectionData();
    
    // Show toast with confetti
    if (!wasFavorite) {
      toastMessage = $t('pages.collection.toastAdded');
      showToast = true;
      createConfetti();
      setTimeout(() => showToast = false, 3000);
    } else {
      toastMessage = $t('pages.collection.toastRemoved');
      showToast = true;
      setTimeout(() => showToast = false, 3000);
    }
  }
  
  function createConfetti() {
    const count = 50;
    const colors = ['#ff0000', '#ff69b4', '#ff1493', '#ff6b9d', '#ffc0cb'];
    
    for (let i = 0; i < count; i++) {
      const particle = document.createElement('div');
      particle.style.position = 'fixed';
      particle.style.width = '10px';
      particle.style.height = '10px';
      particle.style.backgroundColor = colors[Math.floor(Math.random() * colors.length)];
      particle.style.left = `${50 + (Math.random() - 0.5) * 30}%`;
      particle.style.top = '50%';
      particle.style.pointerEvents = 'none';
      particle.style.zIndex = '9999';
      particle.style.borderRadius = '50%';
      document.body.appendChild(particle);
      
      const angle = (Math.random() - 0.5) * Math.PI;
      const velocity = 5 + Math.random() * 5;
      let x = 0, y = 0, vy = -velocity;
      
      const animate = () => {
        y += vy;
        x += velocity * Math.sin(angle);
        vy += 0.3;
        
        particle.style.transform = `translate(${x}px, ${y}px) rotate(${x * 2}deg)`;
        particle.style.opacity = Math.max(0, 1 - y / 300);
        
        if (y < 300) {
          requestAnimationFrame(animate);
        } else {
          particle.remove();
        }
      };
      animate();
    }
  }
  
  function shareToWhatsApp(artwork, event) {
    event.preventDefault();
    event.stopPropagation();
    const url = `${window.location.origin}/#artwork-${artwork.id}`;
    const text = `${$t('pages.collection.shareCheckOut')} "${artwork.display_name || artwork.title}" by Antoine Patraldo`;
    const whatsappUrl = `https://wa.me/?text=${encodeURIComponent(text + ' ' + url)}`;
    window.open(whatsappUrl, '_blank');
  }
  
  function shareToInstagram(artwork, event) {
    event.preventDefault();
    event.stopPropagation();
    const url = `${window.location.origin}/#artwork-${artwork.id}`;
    navigator.clipboard.writeText(url).then(() => {
      toastMessage = $t('pages.collection.toastLinkCopied');
      showToast = true;
      setTimeout(() => showToast = false, 3000);
    });
  }
  
  function openArtwork(artworkId) {
    goto(`/#artwork-${artworkId}`);
  }
  
  function handleClearAll() {
    if (confirm($t('pages.collection.actionsConfirmClear'))) {
      console.log('Clearing all visits...');
      clearAllVisits();
      loadCollectionData();
      
      // Show success toast
      toastMessage = $t('pages.collection.toastCleared');
      showToast = true;
      setTimeout(() => showToast = false, 3000);
      
      // Reset filter to 'all' to show results
      filter = 'all';
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

$effect(() => {
    console.log('Artworks with tags:', allArtworks.map(a => ({
      id: a.id,
      name: a.display_name,
      tags: a.tags
    })));
  });
</script>

<svelte:head>
  <title>{$t('pages.home.metaTitle')} - {$t('common.navCollection')}</title>

</svelte:head>

<div class="collection-page">
  <header class="collection-header">
    <div class="header-content">
      <h1>{$t('pages.collection.title')}</h1>
      <p class="subtitle">{$t('pages.collection.subtitle')}</p>
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
    <!-- Mood Filter -->
    <div class="compact-mood-filter">
      <div class="mood-filter-header">
        <span class="filter-title">{$t('tags.filter.title')}</span>
        <span class="filter-prompt">{$t('tags.filter.prompt')}</span>
      </div>
      
      <div class="mood-buttons compact">
        {#each moodOptions as mood}
          <button 
            class="mood-button {selectedMood === mood.value ? 'active' : ''}"
            onclick={() => selectedMood = mood.value}
          >
            {$t(mood.label)}
          </button>
        {/each}
      </div>
      
      {#if selectedMood}
        <div class="mood-active-filter">
          <span>Showing: <strong>{$t(moodOptions.find(m => m.value === selectedMood)?.label)}</strong></span>
          <button class="clear-mood" onclick={() => selectedMood = ''}>×</button>
        </div>
      {/if}
    </div>

    <!-- Stats -->

<div class="stats-bar">
  <div class="stat-item">
    <span class="stat-number">{visitedCount}</span>
    <span class="stat-label">{$t('pages.collection.statsViewed')}</span>
  </div>
  <div class="stat-item">
    <span class="stat-number">{stats.totalViews || 0}</span>
    <span class="stat-label">{$t('pages.collection.statsTotalViews')}</span>
  </div>
  <div class="stat-item">
    <span class="stat-number">{favoritesCount}</span>
    <span class="stat-label">{$t('pages.collection.statsFavorites')}</span>
  </div>
  <div class="stat-item">
    <span class="stat-number">{allArtworks.length - visitedCount}</span>
    <span class="stat-label">{$t('pages.collection.statsToDiscover')}</span>
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
          {$t('pages.collection.filtersAll')} ({allArtworks.length})
        </button>
        <button 
          class="filter-btn" 
          class:active={filter === 'visited'}
          onclick={() => filter = 'visited'}
        >
          {$t('pages.collection.filtersVisited')} ({visitedCount})
        </button>
        <button 
          class="filter-btn" 
          class:active={filter === 'favorites'}
          onclick={() => filter = 'favorites'}
        >
          ❤️ {$t('pages.collection.filtersFavorites')} ({favoritesCount})
        </button>
        <button 
          class="filter-btn" 
          class:active={filter === 'unvisited'}
          onclick={() => filter = 'unvisited'}
        >
          {$t('pages.collection.filtersUnvisited')} ({allArtworks.length - visitedCount})
        </button>
      </div>
      
      <div class="sort-controls">
        <label for="sort">{$t('pages.collection.sortLabel')}</label>
        <select id="sort" bind:value={sortBy}>
          <option value="recent">{$t('pages.collection.sortRecent')}</option>
          <option value="frequent">{$t('pages.collection.sortFrequent')}</option>
          <option value="alphabetical">{$t('pages.collection.sortAlphabetical')}</option>
        </select>
      </div>
      
      <div class="actions">
        <button class="action-btn" onclick={handleExport}>
          {$t('pages.collection.actionsExport')}
        </button>
        <button class="action-btn danger" onclick={handleClearAll}>
          {$t('pages.collection.actionsClear')}
        </button>
      </div>
    </div>
    
    <!-- Grid -->
    {#if sortedArtworks.length === 0}
      <div class="empty-state">
        <div class="empty-icon">🎨</div>
        <h2>{$t('pages.collection.emptyTitle')}</h2>
        <p>{$t('pages.collection.emptyMessage')}</p>
        <a href="/" class="cta-button">{$t('pages.collection.emptyCta')}</a>
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
              
              <!-- Share buttons -->
              <div class="share-buttons">
                <button 
                  class="share-btn whatsapp"
                  onclick={(e) => shareToWhatsApp(artwork, e)}
                  title={$t('pages.collection.cardShareWhatsApp')}
                >
                  <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor">
                    <path d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347m-5.421 7.403h-.004a9.87 9.87 0 01-5.031-1.378l-.361-.214-3.741.982.998-3.648-.235-.374a9.86 9.86 0 01-1.51-5.26c.001-5.45 4.436-9.884 9.888-9.884 2.64 0 5.122 1.03 6.988 2.898a9.825 9.825 0 012.893 6.994c-.003 5.45-4.437 9.884-9.885 9.884m8.413-18.297A11.815 11.815 0 0012.05 0C5.495 0 .16 5.335.157 11.892c0 2.096.547 4.142 1.588 5.945L.057 24l6.305-1.654a11.882 11.882 0 005.683 1.448h.005c6.554 0 11.89-5.335 11.893-11.893a11.821 11.821 0 00-3.48-8.413Z"/>
                  </svg>
                </button>
                <button 
                  class="share-btn instagram"
                  onclick={(e) => shareToInstagram(artwork, e)}
                  title={$t('pages.collection.cardCopyLink')}
                >
                  <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor">
                    <path d="M12 2.163c3.204 0 3.584.012 4.85.07 3.252.148 4.771 1.691 4.919 4.919.058 1.265.069 1.645.069 4.849 0 3.205-.012 3.584-.069 4.849-.149 3.225-1.664 4.771-4.919 4.919-1.266.058-1.644.07-4.85.07-3.204 0-3.584-.012-4.849-.07-3.26-.149-4.771-1.699-4.919-4.92-.058-1.265-.07-1.644-.07-4.849 0-3.204.013-3.583.07-4.849.149-3.227 1.664-4.771 4.919-4.919 1.266-.057 1.645-.069 4.849-.069zm0-2.163c-3.259 0-3.667.014-4.947.072-4.358.2-6.78 2.618-6.98 6.98-.059 1.281-.073 1.689-.073 4.948 0 3.259.014 3.668.072 4.948.2 4.358 2.618 6.78 6.98 6.98 1.281.058 1.689.072 4.948.072 3.259 0 3.668-.014 4.948-.072 4.354-.2 6.782-2.618 6.979-6.98.059-1.28.073-1.689.073-4.948 0-3.259-.014-3.667-.072-4.947-.196-4.354-2.617-6.78-6.979-6.98-1.281-.059-1.69-.073-4.949-.073zm0 5.838c-3.403 0-6.162 2.759-6.162 6.162s2.759 6.163 6.162 6.163 6.162-2.759 6.162-6.163c0-3.403-2.759-6.162-6.162-6.162zm0 10.162c-2.209 0-4-1.79-4-4 0-2.209 1.791-4 4-4s4 1.791 4 4c0 2.21-1.791 4-4 4zm6.406-11.845c-.796 0-1.441.645-1.441 1.44s.645 1.44 1.441 1.44c.795 0 1.439-.645 1.439-1.44s-.644-1.44-1.439-1.44z"/>
                  </svg>
                </button>
              </div>
              
              <!-- Favorite button -->
              <button 
                class="favorite-btn" 
                class:active={favorites.has(artwork.id.toString())}
                onclick={(e) => handleToggleFavorite(artwork.id, e)}
                title={favorites.has(artwork.id.toString()) ? $t('pages.collection.cardRemoveFavorite') : $t('pages.collection.cardAddFavorite')}
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
                <span class="view-label">{$t('pages.collection.cardView')}</span>
              </div>
            </div>
            
            <div class="card-content">
              <h3 class="card-title">{artwork.display_name || artwork.title}</h3>
              {#if artwork.year}
                <p class="card-year">{artwork.year}</p>
              {/if}
              {#if visits[artwork.id]}
                <p class="last-viewed">
                  {$t('pages.collection.cardLastViewed')} {new Date(visits[artwork.id].lastVisited).toLocaleDateString()}
                </p>
              {/if}
            </div>
          </div>
        {/each}
      </div>
    {/if}
  </div>
</div>

<!-- Slide-out menu - auto-opens for mood filter -->
{#if showMenu || selectedMood}
  <div class="menu-overlay" onclick={() => { showMenu = false; selectedMood = ''; }}></div>
  <nav class="slide-menu">
    <div class="menu-header">
      {#if selectedMood}
        <div>
          <h2>{$t('tags.filter.title')}</h2>
          <p class="mood-subtitle">{$t(`tags.mood.${selectedMood}`)}</p>
        </div>
      {:else}
        <h2>{$t('pages.collection.title')}</h2>
      {/if}
      <button class="close-button" onclick={() => { showMenu = false; selectedMood = ''; }}>×</button>
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

<!-- Toast notification -->
{#if showToast}
  <div class="toast">
    {toastMessage}
  </div>
{/if}

<style>
  /* ───────────────────────────────────────
     COLLECTION PAGE LAYOUT OVERRIDES
     ─────────────────────────────────────── */
  .collection-page {
    padding: 0.25rem 0.5rem 1rem !important;
    max-width: 1400px;
    margin: 0 auto;
    min-height: 100vh;
    background: linear-gradient(180deg, #fafafa 0%, #ffffff 100%);
  }

  .collection-page .layout {
    max-width: none !important;
    padding-left: 0.5rem !important;
    padding-right: 0.5rem !important;
    width: 100% !important;
  }

  /* ───────────────────────────────────────
     HEADER - SUPER COMPACT
     ─────────────────────────────────────── */
  .collection-header {
    text-align: center;
    margin-bottom: 0.75rem;
    padding: 0.5rem 0.25rem 0 !important;
  }

  .collection-header h1 {
    font-size: 1.5rem !important;
    font-weight: 600;
    color: #1a1a1a;
    margin: 0 0 0.1rem 0 !important;
    letter-spacing: -0.02em;
  }

  .subtitle {
    font-size: 0.85rem !important;
    color: #666;
    margin: 0 0 0.25rem 0 !important;
  }

  .menu-toggle {
    background: white;
    border: 1px solid #e0e0e0;
    border-radius: 6px;
    padding: 0.4rem;
    cursor: pointer;
    transition: all 0.2s ease;
    color: #666;
    margin-top: 0.5rem;
  }

  /* ───────────────────────────────────────
     STATS BAR - ULTRA COMPACT
     ─────────────────────────────────────── */
  .stats-bar {
    display: grid;
    grid-template-columns: repeat(4, 1fr);
    gap: 0.25rem;
    padding: 0.5rem;
    background: #f8f9fa;
    border-radius: 6px;
    margin-bottom: 0.75rem;
    border: 1px solid #e9ecef;
  }

  .stat-item {
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 0.1rem;
    padding: 0.4rem 0.25rem;
    border-radius: 4px;
    transition: all 0.3s ease;
    cursor: default;
    text-align: center;
  }

  .stat-item:hover {
    background: rgba(44, 94, 61, 0.05);
    transform: translateY(-1px);
    box-shadow: 0 2px 6px rgba(0,0,0,0.08);
  }

  .stat-number {
    font-weight: bold;
    color: #2c5e3d;
    font-size: 0.9rem;
    line-height: 1;
  }

  .stat-label {
    font-size: 0.65rem;
    color: #666;
    font-weight: 500;
    line-height: 1.1;
  }

  /* ───────────────────────────────────────
     MOOD FILTER - COMPACT
     ─────────────────────────────────────── */
  .compact-mood-filter {
    background: #f8f9fa;
    border-radius: 8px;
    padding: 0.75rem;
    margin-bottom: 0.75rem;
    border: 1px solid #e9ecef;
  }

  .mood-filter-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 0.5rem;
  }

  .filter-title {
    font-weight: 600;
    color: #333;
    font-size: 0.9rem;
  }

  .filter-prompt {
    font-size: 0.75rem;
    color: #666;
    font-style: italic;
  }

  .mood-buttons.compact {
    display: flex;
    flex-wrap: wrap;
    gap: 0.25rem;
    margin-bottom: 0.5rem;
  }

  .mood-buttons.compact .mood-button {
    padding: 0.3rem 0.6rem;
    border: 1px solid #ddd;
    border-radius: 1.5rem;
    background: white;
    color: #333;
    cursor: pointer;
    transition: all 0.2s ease;
    font-size: 0.75rem;
  }

  .mood-buttons.compact .mood-button:hover {
    border-color: #2c5e3d;
  }

  .mood-buttons.compact .mood-button.active {
    background: #2c5e3d;
    color: white;
    border-color: #2c5e3d;
  }

  .mood-active-filter {
    display: flex;
    align-items: center;
    gap: 0.5rem;
    padding: 0.5rem 0.75rem;
    background: #e8f5e8;
    border-radius: 4px;
    border-left: 3px solid #2c5e3d;
    font-size: 0.8rem;
  }

  .clear-mood {
    background: none;
    border: none;
    font-size: 1rem;
    cursor: pointer;
    color: #666;
    padding: 0;
    width: 18px;
    height: 18px;
  }

  /* ───────────────────────────────────────
     CONTROLS - COMPACT
     ─────────────────────────────────────── */
  .controls {
    background: white;
    padding: 1rem;
    border-radius: 8px;
    margin-bottom: 1rem;
    box-shadow: 0 1px 4px rgba(0,0,0,0.06);
    border: 1px solid #e0e0e0;
  }

  .filters {
    display: flex;
    gap: 0.5rem;
    margin-bottom: 1rem;
    flex-wrap: wrap;
  }

  .filter-btn {
    padding: 0.5rem 1rem;
    border: 1px solid #e0e0e0;
    background: white;
    border-radius: 6px;
    cursor: pointer;
    transition: all 0.2s ease;
    font-size: 0.85rem;
    font-weight: 500;
  }

  .filter-btn.active {
    background: #1a1a1a;
    color: white;
    border-color: #1a1a1a;
  }

  .sort-controls {
    display: flex;
    align-items: center;
    gap: 0.5rem;
    margin-bottom: 1rem;
    font-size: 0.85rem;
  }

  .sort-controls select {
    padding: 0.4rem 0.75rem;
    border: 1px solid #e0e0e0;
    border-radius: 4px;
    font-size: 0.85rem;
  }

  .actions {
    display: flex;
    gap: 0.5rem;
    flex-wrap: wrap;
  }

  .action-btn {
    padding: 0.5rem 1rem;
    border: 1px solid #e0e0e0;
    background: white;
    border-radius: 6px;
    cursor: pointer;
    font-size: 0.8rem;
    font-weight: 500;
  }

  /* ───────────────────────────────────────
     ARTWORK GRID - MAXIMUM VISIBILITY
     ─────────────────────────────────────── */
  .collection-grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
    gap: 1rem;
    margin-top: 0.5rem;
  }

  .artwork-card {
    background: white;
    border-radius: 8px;
    overflow: hidden;
    cursor: pointer;
    transition: all 0.3s ease;
    border: 1px solid #e0e0e0;
  }

  .artwork-card:hover {
    transform: translateY(-2px);
    box-shadow: 0 4px 12px rgba(0,0,0,0.1);
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
  }

  /* Share buttons */
  .share-buttons {
    position: absolute;
    top: 0.5rem;
    left: 0.5rem;
    display: flex;
    gap: 0.25rem;
    opacity: 0;
    transition: opacity 0.3s ease;
    z-index: 3;
  }

  .artwork-card:hover .share-buttons {
    opacity: 1;
  }

  .share-btn {
    background: rgba(255, 255, 255, 0.95);
    border: none;
    width: 30px;
    height: 30px;
    border-radius: 50%;
    cursor: pointer;
    transition: all 0.2s ease;
    display: flex;
    align-items: center;
    justify-content: center;
    color: #666;
    font-size: 0.8rem;
  }

  /* Favorite button */
  .favorite-btn {
    position: absolute;
    top: 0.5rem;
    right: 0.5rem;
    background: rgba(255, 255, 255, 0.95);
    border: none;
    width: 32px;
    height: 32px;
    border-radius: 50%;
    font-size: 1.1rem;
    cursor: pointer;
    transition: all 0.2s ease;
    display: flex;
    align-items: center;
    justify-content: center;
    z-index: 2;
  }

  /* View count */
  .view-count {
    position: absolute;
    bottom: 0.5rem;
    left: 0.5rem;
    background: rgba(0, 0, 0, 0.75);
    color: white;
    padding: 0.2rem 0.5rem;
    border-radius: 12px;
    font-size: 0.7rem;
    font-weight: 500;
    z-index: 2;
  }

  /* Card overlay */
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
    padding: 0.75rem;
  }

  .artwork-card:hover .card-overlay {
    opacity: 1;
  }

  .view-label {
    color: white;
    font-size: 0.75rem;
    font-weight: 600;
    text-transform: uppercase;
    letter-spacing: 0.05em;
  }

  .card-content {
    padding: 0.75rem;
  }

  .card-title {
    font-size: 0.95rem;
    font-weight: 600;
    color: #1a1a1a;
    margin: 0 0 0.25rem 0;
    line-height: 1.4;
  }

  .card-year {
    font-size: 0.75rem;
    color: #999;
    margin: 0 0 0.25rem 0;
  }

  .last-viewed {
    font-size: 0.7rem;
    color: #666;
    margin: 0;
  }

  /* Empty state */
  .empty-state {
    text-align: center;
    padding: 2rem 1rem;
  }

  .empty-icon {
    font-size: 2.5rem;
    margin-bottom: 1rem;
    opacity: 0.5;
  }

  .empty-state h2 {
    font-size: 1.25rem;
    font-weight: 600;
    color: #1a1a1a;
    margin: 0 0 0.75rem 0;
  }

  .empty-state p {
    color: #666;
    font-size: 0.9rem;
    margin: 0 0 1.5rem 0;
  }

  .cta-button {
    display: inline-block;
    background: #1a1a1a;
    color: white;
    padding: 0.6rem 1.5rem;
    border-radius: 6px;
    text-decoration: none;
    font-weight: 500;
    font-size: 0.85rem;
    transition: all 0.2s ease;
  }

  /* ───────────────────────────────────────
     MENU & TOAST (keep your working styles)
     ─────────────────────────────────────── */
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
    padding: 1.25rem;
    border-bottom: 1px solid #e0e0e0;
    display: flex;
    justify-content: space-between;
    align-items: center;
  }

  .menu-header h2 {
    font-size: 1.1rem;
    font-weight: 600;
    margin: 0;
    color: #1a1a1a;
  }

  .close-button {
    background: none;
    border: none;
    font-size: 1.5rem;
    color: #666;
    cursor: pointer;
    padding: 0;
    width: 28px;
    height: 28px;
    display: flex;
    align-items: center;
    justify-content: center;
    border-radius: 4px;
    transition: background 0.2s ease;
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
    gap: 0.75rem;
    padding: 0.75rem 1.25rem;
    width: 100%;
    background: none;
    border: none;
    text-align: left;
    color: #1a1a1a;
    cursor: pointer;
    transition: background 0.2s ease;
    border-bottom: 1px solid #f5f5f5;
    font-size: 0.9rem;
  }

.menu-thumb {
  width: 80px;   /* was 40px */
  height: 80px;  /* was 40px */
  object-fit: cover;
  border-radius: 8px;  /* was 4px */
  flex-shrink: 0;
}

.mood-subtitle {
  font-size: 1.25rem;
  font-weight: 600;
  color: #2c5e3d;
  margin: 0.25rem 0 0 0;
}

  /* Toast */
  .toast {
    position: fixed;
    bottom: 1.5rem;
    left: 50%;
    transform: translateX(-50%);
    background: rgba(0, 0, 0, 0.9);
    color: white;
    padding: 0.75rem 1.5rem;
    border-radius: 25px;
    font-size: 0.85rem;
    font-weight: 500;
    z-index: 10000;
    animation: toastIn 0.3s ease, toastOut 0.3s ease 2.7s;
    box-shadow: 0 4px 12px rgba(0, 0, 0, 0.3);
  }

  @keyframes fadeIn {
    from { opacity: 0; }
    to { opacity: 1; }
  }

  @keyframes slideIn {
    from { transform: translateX(100%); }
    to { transform: translateX(0); }
  }

  @keyframes toastIn {
    from {
      opacity: 0;
      transform: translateX(-50%) translateY(20px);
    }
    to {
      opacity: 1;
      transform: translateX(-50%) translateY(0);
    }
  }

  @keyframes toastOut {
    from {
      opacity: 1;
      transform: translateX(-50%) translateY(0);
    }
    to {
      opacity: 0;
      transform: translateX(-50%) translateY(20px);
    }
  }

  /* ───────────────────────────────────────
     MOBILE RESPONSIVE
     ─────────────────────────────────────── */
  @media (max-width: 768px) {
    .collection-page {
      padding: 0.125rem 0.25rem 0.5rem !important;
    }

    .stats-bar {
      grid-template-columns: repeat(2, 1fr);
      gap: 0.5rem;
      padding: 0.75rem;
    }

    .collection-grid {
      grid-template-columns: repeat(auto-fill, minmax(240px, 1fr));
      gap: 0.75rem;
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

    .stats-bar {
      grid-template-columns: 1fr;
    }
  }
</style>
