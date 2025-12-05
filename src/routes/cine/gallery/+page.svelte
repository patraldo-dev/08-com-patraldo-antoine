<!-- src/routes/cine/gallery/+page.svelte -->
<script>
  import { t } from '$lib/i18n';
  import VideoCard from '$lib/components/cine/VideoCard.svelte';
  
  let { data } = $props();
</script>

<svelte:head>
  <title>{$t('cine.gallery.title')} - Cine</title>
</svelte:head>

<div class="gallery-page">
  <header class="gallery-header">
    <a href="/cine" class="back-link">
      <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        <path d="M19 12H5M12 19l-7-7 7-7"/>
      </svg>
      {$t('cine.nav.back')}
    </a>
    <h1>{$t('cine.gallery.title')}</h1>
  </header>

  {#if data.films.length === 0}
    <div class="empty-state">
      <p>{$t('cine.gallery.empty')}</p>
      <a href="/" class="home-btn">Go Home</a>
    </div>
  {:else}
    <div class="gallery-content">
      {#each Object.entries(data.groupedFilms) as [type, films]}
        <section class="film-group">
          <h2>{type}</h2>
          <div class="video-grid">
            {#each films as film (film.id)}
              <VideoCard 
                {film} 
                customerCode={data.customerCode}
                cloudflareAccountHash={data.cloudflareAccountHash}
              />
            {/each}
          </div>
        </section>
      {/each}
    </div>
  {/if}
</div>

<style>
  .gallery-page {
    min-height: 100vh;
    background: #0a0a0a;
    color: white;
    padding: 2rem;
  }
  
  .gallery-header {
    max-width: 1400px;
    margin: 0 auto 2rem;
  }
  
  .back-link {
    display: inline-flex;
    align-items: center;
    gap: 0.5rem;
    color: white;
    text-decoration: none;
    margin-bottom: 1rem;
    opacity: 0.8;
    transition: opacity 0.2s;
  }
  
  .back-link:hover {
    opacity: 1;
  }
  
  .gallery-header h1 {
    font-size: 2.5rem;
    margin: 0;
  }
  
  .gallery-content {
    max-width: 1400px;
    margin: 0 auto;
  }
  
  .film-group {
    margin-bottom: 3rem;
  }
  
  .film-group h2 {
    font-size: 1.5rem;
    margin-bottom: 1.5rem;
    color: #999;
  }
  
  .video-grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
    gap: 2rem;
  }
  
  .empty-state {
    text-align: center;
    padding: 4rem 2rem;
    color: #666;
  }
  
  .home-btn {
    display: inline-block;
    margin-top: 1rem;
    padding: 0.75rem 1.5rem;
    background: rgba(255, 255, 255, 0.1);
    color: white;
    text-decoration: none;
    border-radius: 4px;
  }
  
  @media (max-width: 768px) {
    .gallery-page {
      padding: 1rem;
    }
    
    .gallery-header h1 {
      font-size: 1.8rem;
    }
    
    .video-grid {
      grid-template-columns: 1fr;
      gap: 1.5rem;
    }
  }
</style>
