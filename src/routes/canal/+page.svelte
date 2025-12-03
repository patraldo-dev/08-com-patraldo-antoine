<!-- src/routes/canal/+page.svelte -->
<script>
  import { t } from '$lib/i18n';
  import VideoPlayer from '$lib/components/canal/VideoPlayer.svelte';
  import HeroOverlay from '$lib/components/canal/HeroOverlay.svelte';
  
  let { data } = $props();
</script>

<svelte:head>
  <title>{data.film ? data.film.title : $t('canal.error.noFilm')}</title>
</svelte:head>

{#if !data.film}
  <div class="error-page">
    <div class="error-content">
      <h1>{$t('canal.error.noFilm')}</h1>
      <p>{$t('canal.error.loadFailed')}</p>
      <a href="/" class="home-link">{$t('canal.nav.home')}</a>
    </div>
  </div>
{:else}
  <div class="canal-page">
    <!-- Add gallery nav button -->
    <nav class="canal-nav">
      <a href="/canal/gallery" class="gallery-link">
        <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <rect x="3" y="3" width="7" height="7"></rect>
          <rect x="14" y="3" width="7" height="7"></rect>
          <rect x="14" y="14" width="7" height="7"></rect>
          <rect x="3" y="14" width="7" height="7"></rect>
        </svg>
        {$t('canal.nav.gallery')}
      </a>
      <a href="/" class="home-link">
        <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"></path>
          <polyline points="9 22 9 12 15 12 15 22"></polyline>
        </svg>
        {$t('canal.nav.home')}
      </a>
    </nav>
    
    <VideoPlayer 
      videoId={data.film.stream_video_id}
      customerCode={data.customerCode}
      autoplay={true}
      muted={false}
    />
    
    <HeroOverlay film={data.film} />
  </div>
{/if}

<style>
  .canal-nav {
    position: absolute;
    top: 20px;
    right: 20px;
    z-index: 100;
    display: flex;
    gap: 10px;
  }
  
  .gallery-link, .home-link {
    display: flex;
    align-items: center;
    gap: 8px;
    background: rgba(255, 255, 255, 0.9);
    color: #333;
    padding: 10px 16px;
    border-radius: 8px;
    text-decoration: none;
    font-weight: 500;
    backdrop-filter: blur(10px);
    border: 1px solid rgba(255, 255, 255, 0.2);
    transition: all 0.2s ease;
  }
  
  .gallery-link:hover, .home-link:hover {
    background: white;
    transform: translateY(-2px);
    box-shadow: 0 4px 12px rgba(0,0,0,0.15);
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
    max-width: 400px;
  }
  
  .error-content h1 {
    margin-bottom: 1rem;
    color: #333;
  }
  
  .error-content p {
    margin-bottom: 2rem;
    color: #666;
  }
  
  .home-link {
    display: inline-block;
    background: #667eea;
    color: white;
    padding: 12px 24px;
    border-radius: 8px;
    text-decoration: none;
    transition: background 0.2s;
  }
  
  .home-link:hover {
    background: #764ba2;
  }
</style>
