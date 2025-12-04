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
    <!-- Fixed navigation buttons -->
    <nav class="canal-nav">
      <a href="/canal/gallery" class="nav-button gallery-link">
        <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <rect x="3" y="3" width="7" height="7"></rect>
          <rect x="14" y="3" width="7" height="7"></rect>
          <rect x="14" y="14" width="7" height="7"></rect>
          <rect x="3" y="14" width="7" height="7"></rect>
        </svg>
        <span>{$t('canal.nav.gallery')}</span>
      </a>
      <a href="/" class="nav-button home-link">
        <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"></path>
          <polyline points="9 22 9 12 15 12 15 22"></polyline>
        </svg>
        <span>{$t('canal.nav.home')}</span>
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
  .canal-page {
    position: relative;
    width: 100%;
    height: 100vh;
    overflow: hidden;
    background: #000;
  }
  
  .canal-nav {
    position: fixed;
    top: 2rem;
    right: 2rem;
    z-index: 100;
    display: flex;
    gap: 1rem;
  }
  
  .nav-button {
    display: flex;
    align-items: center;
    gap: 0.5rem;
    padding: 0.75rem 1rem;
    background: rgba(0, 0, 0, 0.7);
    backdrop-filter: blur(10px);
    border: 1px solid rgba(255, 255, 255, 0.2);
    border-radius: 8px;
    color: white;
    text-decoration: none;
    font-size: 0.9rem;
    transition: all 0.2s;
    cursor: pointer;
  }
  
  .nav-button:hover {
    background: rgba(0, 0, 0, 0.85);
    border-color: rgba(255, 255, 255, 0.4);
    transform: translateY(-2px);
  }
  
  .error-page {
    position: relative;
    width: 100%;
    height: 100vh;
    background: #000;
    display: flex;
    align-items: center;
    justify-content: center;
  }
  
  .error-content {
    text-align: center;
    color: #fff;
    padding: 2rem;
  }
  
  .error-content h1 {
    font-size: 2rem;
    margin-bottom: 1rem;
  }
  
  .error-content p {
    font-size: 1.1rem;
    margin-bottom: 2rem;
    color: #aaa;
  }
  
  .home-link {
    color: #fff;
    text-decoration: none;
    padding: 0.75rem 1.5rem;
    background: rgba(255, 255, 255, 0.1);
    border-radius: 4px;
    display: inline-block;
  }
  
  @media (max-width: 768px) {
    .canal-nav {
      top: 1rem;
      right: 1rem;
      gap: 0.5rem;
    }
    
    .nav-button span {
      display: none;
    }
  }
</style>
