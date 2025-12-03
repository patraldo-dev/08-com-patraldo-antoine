<script>
  import VideoPlayer from '$lib/components/channel/VideoPlayer.svelte';
  import HeroOverlay from '$lib/components/channel/HeroOverlay.svelte';
  import LanguageSwitcherUniversal from '$lib/components/ui/LanguageSwitcherUniversal.svelte';
  
  /**
   * @typedef {Object} PageData
   * @property {Object} film
   * @property {string} film.title
   * @property {string} film.description
   * @property {string} film.stream_video_id
   * @property {number} film.duration
   * @property {number} film.view_count
   * @property {string} customerCode
   * @property {string} locale
   */
  
  /** @type {{ data: PageData }} */
  let { data } = $props();
</script>

<svelte:head>
  <title>{data.film.title} - Canal de Animación</title>
  <meta name="description" content={data.film.description} />
</svelte:head>

<div class="channel-page">
  <div class="language-switcher-container">
    <LanguageSwitcherUniversal />
  </div>
  
  <VideoPlayer 
    videoId={data.film.stream_video_id}
    customerCode={data.customerCode}
    autoplay={true}
    muted={false}
  />
  
  <HeroOverlay film={data.film} locale={data.locale} />
</div>

<style>
  .channel-page {
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
    pointer-events: auto;
  }
</style>
