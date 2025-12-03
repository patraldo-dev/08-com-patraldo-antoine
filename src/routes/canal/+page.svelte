<!-- src/routes/canal/+page.svelte -->
<script>
  import { t } from '$lib/i18n';
  import VideoPlayer from '$lib/components/canal/VideoPlayer.svelte';
  import HeroOverlay from '$lib/components/canal/HeroOverlay.svelte';
  import LanguageSwitcherUniversal from '$lib/components/ui/LanguageSwitcherUniversal.svelte';
  
  let { data } = $props();
</script>

<svelte:head>
  <title>{data.film ? data.film.title : $t('canal.error.noFilm')}</title>
</svelte:head>

{#if !data.film}
  <div class="error-page">
    <div class="language-switcher-container">
      <LanguageSwitcherUniversal />
    </div>
    <div class="error-content">
      <h1>{$t('canal.error.noFilm')}</h1>
      <p>{$t('canal.error.loadFailed')}</p>
      <a href="/" class="home-link">{$t('canal.nav.home')}</a>
    </div>
  </div>
{:else}
  <div class="canal-page">
    <div class="language-switcher-container">
      <LanguageSwitcherUniversal />
    </div>
    
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
    transition: background 0.2s;
  }
  
  .home-link:hover {
    background: rgba(255, 255, 255, 0.2);
  }
  
  .language-switcher-container {
    position: fixed;
    top: 2rem;
    right: 2rem;
    z-index: 100;
  }
</style>
