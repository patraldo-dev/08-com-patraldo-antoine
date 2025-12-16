<script>
  import { onMount } from 'svelte';
  
  /**
   * @typedef {Object} Props
   * @property {string} videoId
   * @property {string} customerCode
   * @property {boolean} [autoplay]
   * @property {boolean} [muted]
   * @property {boolean} [controls] - Show native controls (default: true)
   * @property {string} [poster] - Optional poster image URL
   */
  
  /** @type {Props} */
  let { 
    videoId, 
    customerCode, 
    autoplay = true, 
    muted = false,
    controls = true,
    poster = undefined
  } = $props();
  
  let isLoaded = $state(false);
  let streamElement = $state(null);
  let player = $state(null);
  
  onMount(async () => {
    // Load the Stream SDK
    const script = document.createElement('script');
    script.src = 'https://embed.cloudflarestream.com/embed/sdk.latest.js';
    script.async = true;
    document.head.appendChild(script);
    
    // Wait for SDK to load and initialize player
    script.onload = () => {
      if (streamElement && window.Stream) {
        player = window.Stream(streamElement);
        
        // Optional: Listen to player events
        player.addEventListener('play', () => {
          console.log('Video playing');
        });
        
        player.addEventListener('loadedmetadata', () => {
          isLoaded = true;
        });
      }
    };
    
    return () => {
      // Cleanup
      if (script.parentNode) {
        document.head.removeChild(script);
      }
    };
  });
</script>

<div class="video-wrapper">
  <stream
    bind:this={streamElement}
    src={videoId}
    controls={controls}
    autoplay={autoplay}
    muted={muted}
    poster={poster}
    preload="auto"
  ></stream>
  
  {#if !isLoaded}
    <div class="loading">
      <div class="spinner"></div>
    </div>
  {/if}
</div>

<style>
  .video-wrapper {
    position: relative;
    width: 100%;
    height: 100%;
    background: #000;
  }
  
  stream {
    width: 100%;
    height: 100%;
    display: block;
  }
  
  .loading {
    position: absolute;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    display: flex;
    align-items: center;
    justify-content: center;
    background: rgba(0, 0, 0, 0.9);
    z-index: 1;
  }
  
  .spinner {
    width: 40px;
    height: 40px;
    border: 3px solid rgba(255, 255, 255, 0.2);
    border-top-color: #fff;
    border-radius: 50%;
    animation: spin 0.8s linear infinite;
  }
  
  @keyframes spin {
    to { transform: rotate(360deg); }
  }
</style>
