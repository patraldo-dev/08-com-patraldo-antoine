<script>
  /**
   * @typedef {Object} Props
   * @property {string} videoId
   * @property {string} customerCode
   * @property {boolean} [autoplay]
   * @property {boolean} [muted]
   */
  
  /** @type {Props} */
  let { videoId, customerCode, autoplay = true, muted = false } = $props();
  let isLoaded = $state(false);
</script>

<div class="video-wrapper">
  <iframe
    src={`https://customer-${customerCode}.cloudflarestream.com/${videoId}/iframe?autoplay=${autoplay}&muted=${muted}`}
    style="border: none; position: absolute; top: 0; left: 0; height: 100%; width: 100%;"
    allow="accelerometer; gyroscope; autoplay; encrypted-media; picture-in-picture;"
    allowfullscreen={true}
    onload={() => isLoaded = true}
    title="Video player"
  ></iframe>
  
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
    height: 100vh;
    background: #000;
  }
  
  .loading {
    position: absolute;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    display: flex;
    align-items: center;
    justify-content: center;
    background: #000;
    z-index: 5;
  }
  
  .spinner {
    width: 50px;
    height: 50px;
    border: 4px solid rgba(255, 255, 255, 0.1);
    border-top-color: #fff;
    border-radius: 50%;
    animation: spin 1s linear infinite;
  }
  
  @keyframes spin {
    to { transform: rotate(360deg); }
  }
</style>
