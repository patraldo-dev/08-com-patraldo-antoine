<!-- src/routes/cine/+page.svelte -->
<script>
  import { t } from '$lib/i18n';
  import VideoPlayer from '$lib/components/cine/VideoPlayer.svelte';
  import HeroOverlay from '$lib/components/cine/HeroOverlay.svelte';
  import Navigation from '$lib/components/Navigation.svelte';
  
  let { data } = $props();
</script>

<svelte:head>
  <title>{data.film ? data.film.title : $t('cine.error.noFilm')}</title>
</svelte:head>

{#if !data.film}
  <div class="error-page">
    <Navigation />
    <div class="error-content">
      <h1>{$t('cine.error.noFilm')}</h1>
      <p>{$t('cine.error.loadFailed')}</p>
    </div>
  </div>
{:else}
  <div class="cine-page">
    <!-- Use your existing Navigation component -->
    <Navigation />
    
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
  .cine-page {
    position: relative;
    width: 100%;
    height: 100vh;
    overflow: hidden;
    background: #000;
  }
  
  .language-switcher {
    position: fixed;
    top: 2rem;
    right: 2rem;
    z-index: 1000;
  }
  
  .error-page {
    position: relative;
    width: 100%;
    height: 100vh;
    background: #000;
    display: flex;
    flex-direction: column;
  }
  
  .error-content {
    flex: 1;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
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
    color: #aaa;
  }
</style>
