<script>
  import VideoPlayer from '$lib/components/canal/VideoPlayer.svelte';
  import HeroOverlay from '$lib/components/canal/HeroOverlay.svelte';
  import LanguageSwitcherUniversal from '$lib/components/ui/LanguageSwitcherUniversal.svelte';
  
  /** @type {{ data: any }} */
  let { data } = $props();
</script>

<svelte:head>
  <title>{data.film.title}</title>
  <meta name="description" content={data.film.description} />
</svelte:head>

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

<style>
  .canal-page {
    position: relative;
    width: 100%;
    height: 100vh;
    overflow: hidden;
    background: #000;
  }
  
  .language-switcher-container {
    position: fixed;
    top: 2rem;
    right: 2rem;
    z-index: 100;
  }
  
  @media (max-width: 768px) {
    .language-switcher-container {
      top: 1rem;
      right: 1rem;
    }
  }
</style>
