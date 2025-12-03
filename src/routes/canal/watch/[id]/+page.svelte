<!-- src/routes/canal/watch/[id]/+page.svelte -->
<script>
  import { t } from '$lib/i18n';
  import VideoPlayer from '$lib/components/canal/VideoPlayer.svelte';
  import VideoCard from '$lib/components/canal/VideoCard.svelte';
  
  let { data } = $props();
  let { film, customerCode, relatedFilms } = data;
  
  function formatDuration(seconds) {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins}:${secs.toString().padStart(2, '0')}`;
  }
</script>

<svelte:head>
  <title>{film?.title || 'Video'} - {$t('canal.gallery.title')}</title>
</svelte:head>

{#if !film}
  <div class="error-page">
    <div class="error-content">
      <h1>Video Not Found</h1>
      <p>The requested video could not be found.</p>
      <a href="/canal/gallery" class="gallery-link">
        {$t('canal.nav.backToGallery')}
      </a>
    </div>
  </div>
{:else}
  <div class="watch-page">
    <!-- Navigation -->
    <nav class="watch-nav">
      <a href="/canal/gallery" class="back-link">
        <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <line x1="19" y1="12" x2="5" y2="12"></line>
          <polyline points="12 19 5 12 12 5"></polyline>
        </svg>
        {$t('canal.nav.backToGallery')}
      </a>
      <a href="/canal" class="featured-link">
        Featured Video
      </a>
    </nav>
    
    <!-- Main video -->
    <div class="video-container">
      <VideoPlayer 
        videoId={film.stream_video_id}
        customerCode={customerCode}
        autoplay={true}
        muted={false}
      />
    </div>
    
    <!-- Video info -->
    <div class="video-info">
      <h1>{film.title}</h1>
      {#if film.description}
        <p class="description">{film.description}</p>
      {/if}
      
      <div class="metadata">
        {#if film.duration > 0}
          <span class="duration">
            {$t('canal.hero.duration')}: {formatDuration(film.duration)}
          </span>
        {/if}
        <span class="views">
          {film.view_count || 0} {$t('canal.hero.views')}
        </span>
        {#if film.artwork?.type}
          <span class="type">Type: {film.artwork.type}</span>
        {/if}
        {#if film.artwork?.year}
          <span class="year">Year: {film.artwork.year}</span>
        {/if}
      </div>
      
      {#if film.artwork}
        <div class="artwork-link">
          <a href="/works/{film.artwork.slug || film.artwork.id}" target="_blank">
            View related artwork →
          </a>
        </div>
      {/if}
    </div>
    
    <!-- Related videos -->
    {#if relatedFilms && relatedFilms.length > 0}
      <div class="related-videos">
        <h2>Related Videos</h2>
        <div class="related-grid">
          {#each relatedFilms as relatedFilm (relatedFilm.id)}
            {#if relatedFilm.id !== film.id}
              <VideoCard 
                film={relatedFilm} 
                customerCode={customerCode} 
              />
            {/if}
          {/each}
        </div>
      </div>
    {/if}
  </div>
{/if}

<style>
  .watch-page {
    max-width: 1200px;
    margin: 0 auto;
    padding: 2rem;
  }
  
  .watch-nav {
    display: flex;
    justify-content: space-between;
    margin-bottom: 2rem;
  }
  
  .back-link, .featured-link {
    display: flex;
    align-items: center;
    gap: 8px;
    padding: 10px 16px;
    background: #f5f5f5;
    border-radius: 8px;
    text-decoration: none;
    color: #333;
    transition: background 0.2s;
  }
  
  .back-link:hover, .featured-link:hover {
    background: #e0e0e0;
  }
  
  .video-container {
    margin-bottom: 2rem;
    border-radius: 12px;
    overflow: hidden;
    box-shadow: 0 4px 20px rgba(0,0,0,0.1);
  }
  
  .video-info {
    margin-bottom: 3rem;
  }
  
  .video-info h1 {
    margin: 0 0 1rem 0;
    font-size: 2rem;
  }
  
  .description {
    font-size: 1.1rem;
    line-height: 1.6;
    color: #444;
    margin-bottom: 1.5rem;
  }
  
  .metadata {
    display: flex;
    flex-wrap: wrap;
    gap: 1rem;
    color: #666;
    font-size: 0.9rem;
    margin-bottom: 1.5rem;
  }
  
  .artwork-link a {
    color: #667eea;
    text-decoration: none;
    font-weight: 500;
  }
  
  .artwork-link a:hover {
    text-decoration: underline;
  }
  
  .related-videos {
    margin-top: 4rem;
  }
  
  .related-videos h2 {
    margin-bottom: 1.5rem;
  }
  
  .related-grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
    gap: 1.5rem;
  }
  
  .error-page {
    display: flex;
    align-items: center;
    justify-content: center;
    min-height: 100vh;
    padding: 2rem;
  }
  
  .error-content {
    text-align: center;
  }
  
  .gallery-link {
    display: inline-block;
    margin-top: 1rem;
    padding: 10px 20px;
    background: #667eea;
    color: white;
    border-radius: 8px;
    text-decoration: none;
  }
</style>
