<!-- src/routes/canal/gallery/+page.svelte -->
<script>
  import { t } from '$lib/i18n';
  import VideoCard from '$lib/components/canal/VideoCard.svelte';
  
  let { data } = $props();
  let { films, groupedFilms, customerCode, error } = data;
  
  // Create reactive groups using $derived
  const filmsByType = $derived(() => {
    if (!films || films.length === 0) return {};
    
    const groups = {};
    films.forEach(film => {
      const type = film.artwork?.type || 'Other';
      if (!groups[type]) groups[type] = [];
      groups[type].push(film);
    });
    return groups;
  });
</script>

<svelte:head>
  <title>{$t('canal.gallery.title')}</title>
</svelte:head>

<div class="gallery-page">
  <header class="gallery-header">
    <h1>{$t('canal.gallery.title')}</h1>
    <p>{$t('canal.gallery.subtitle')}</p>
  </header>
  
  <!-- Navigation -->
  <nav class="gallery-nav">
    <a href="/canal" class="nav-link">
      <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
        <path d="M19 12H5M12 19l-7-7 7-7"/>
      </svg>
      Featured Video
    </a>
    <a href="/" class="nav-link">
      <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
        <path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/>
        <polyline points="9 22 9 12 15 12 15 22"/>
      </svg>
      {$t('canal.nav.home')}
    </a>
  </nav>
  
  {#if error || films.length === 0}
    <div class="empty-state">
      <p>{$t('canal.gallery.noVideos')}</p>
      <a href="/canal" class="back-link">← {$t('canal.nav.home')}</a>
    </div>
  {:else}
    <!-- All videos grid -->
    <section class="all-videos">
      <h2>{$t('canal.gallery.allVideos')} ({films.length})</h2>
      <div class="videos-grid">
{#each films as film (film.id)}
  <VideoCard 
    {film} 
    customerCode={customerCode}
    cloudflareAccountHash={cloudflareAccountHash}
  />
{/each}
      </div>
    </section>
    
    <!-- Optional: Grouped by type -->
    {#if Object.keys(filmsByType).length > 1}
      {#each Object.entries(filmsByType) as [type, typeFilms]}
        <section class="type-section">
          <h2>{type} Videos ({typeFilms.length})</h2>
          <div class="videos-grid">
            {#each typeFilms as film (film.id)}
              <VideoCard {film} {customerCode} />
            {/each}
          </div>
        </section>
      {/each}
    {/if}
  {/if}
</div>

<style>
  .gallery-page {
    max-width: 1200px;
    margin: 0 auto;
    padding: 2rem;
  }
  
  .gallery-header {
    text-align: center;
    margin-bottom: 3rem;
  }
  
  .gallery-nav {
    display: flex;
    justify-content: center;
    gap: 1rem;
    margin-bottom: 3rem;
  }
  
  .nav-link {
    display: flex;
    align-items: center;
    gap: 8px;
    background: #f5f5f5;
    color: #333;
    padding: 10px 20px;
    border-radius: 8px;
    text-decoration: none;
    font-weight: 500;
    transition: background 0.2s;
  }
  
  .nav-link:hover {
    background: #e0e0e0;
  }
  
  .videos-grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
    gap: 2rem;
    margin-bottom: 3rem;
  }
  
  .empty-state {
    text-align: center;
    padding: 4rem;
    color: #666;
  }
  
  .back-link {
    display: inline-block;
    margin-top: 1rem;
    padding: 10px 20px;
    background: #667eea;
    color: white;
    border-radius: 8px;
    text-decoration: none;
  }
  
  .back-link:hover {
    background: #764ba2;
  }
  
  .type-section {
    margin-top: 4rem;
  }
  
  .type-section h2 {
    margin-bottom: 1.5rem;
    color: #444;
    text-transform: capitalize;
  }
</style>
