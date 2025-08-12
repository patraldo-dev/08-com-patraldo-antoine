<script>
  export let artwork;
  import { CF_IMAGES_ACCOUNT_HASH, CUSTOM_DOMAIN } from '$lib/config.js';
  
  let showFullSize = false;
  let isLoading = true;
  
  // Function to create Cloudflare Images URL with custom domain and variant
  function createImageUrl(imageId, variant = '') {
    const baseUrl = `https://${CUSTOM_DOMAIN}/cdn-cgi/imagedelivery/${CF_IMAGES_ACCOUNT_HASH}/${imageId}`;
    return variant ? `${baseUrl}/${variant}` : baseUrl;
  }
  
  function handleClick() {
    if (artwork.type === 'still') {
      showFullSize = true;
      isLoading = true;
    }
  }
  
  function closeFullSize() {
    showFullSize = false;
  }
  
  function handleKeydown(event) {
    if (event.key === 'Enter' || event.key === ' ') {
      handleClick();
    }
    if (event.key === 'Escape') {
      closeFullSize();
    }
  }
  
  function handleContentKeydown(event) {
    if (event.key === 'Escape') {
      closeFullSize();
    }
  }
  
  function getThumbnailUrl(thumbnailId, variant = 'thumbnail') {
    return createImageUrl(thumbnailId, variant);
  }
</script>
<div class="art-piece">
  <div 
    class="media-container" 
    class:clickable={artwork.type === 'still'}
    on:click={handleClick} 
    on:keydown={handleKeydown}
    role="button" 
    tabindex="0"
    aria-label={artwork.type === 'still' ? `View ${artwork.title} full size` : artwork.title}
  >
    {#if artwork.type === 'still'}
      <img 
        src={getThumbnailUrl(artwork.thumbnailId, 'gallery')}
        alt={artwork.title}
        loading="lazy"
      />
      {#if showFullSize}
        <div 
          class="fullsize-overlay" 
          on:click={closeFullSize} 
          on:keydown={handleContentKeydown}
          role="dialog"
          aria-modal="true"
          aria-label="Full size image viewer"
          tabindex="0"
        >
          <div 
            class="fullsize-content" 
            role="document"
          >
            {#if isLoading}
              <div class="loading">Loading full resolution...</div>
            {/if}
            <img 
              src={createImageUrl(artwork.thumbnailId, 'desktop')}
              alt={artwork.title}
              on:load={() => isLoading = false}
              on:error={() => isLoading = false}
            />
            <button 
              class="close-btn" 
              on:click={closeFullSize} 
              aria-label="Close full size view"
            >
              &times;
            </button>
          </div>
        </div>
      {/if}
    {:else if artwork.type === 'animation'}
      <!-- svelte-ignore a11y_media_has_caption -->
      <video 
        src={artwork.videoUrl || artwork.imageUrl}
        poster={getThumbnailUrl(artwork.thumbnailId, 'thumbnail')}
        controls
        preload="metadata"
        aria-label={artwork.title}
      >
        Your browser doesn't support video.
        <track kind="captions" label="English captions" src="#" />
      </video>
    {:else if artwork.type === 'gif'}
      <div class="gif-container">
        <img 
          class="gif-thumbnail"
          src={getThumbnailUrl(artwork.thumbnailId, 'thumbnail')}
          alt={`${artwork.title} (static preview)`}
          loading="lazy"
        />
        <img 
          class="gif-animated"
          src={artwork.imageUrl}
          alt={artwork.title}
          loading="lazy"
        />
      </div>
    {/if}
  </div>
  
  <div class="info">
    <h4>{artwork.title}</h4>
    <p>{artwork.description}</p>
    <span class="type-badge {artwork.type}">
      {#if artwork.type === 'still'}
        📷 Still
      {:else if artwork.type === 'animation'}
        🎬 Video
      {:else if artwork.type === 'gif'}
        🎭 Animated
      {/if}
    </span>
    {#if artwork.type === 'still'}
      <span class="click-hint">Click to view full size</span>
    {/if}
  </div>
</div>
<style>
  .art-piece {
    border-radius: 8px;
    overflow: hidden;
    box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
    transition: transform 0.3s ease, box-shadow 0.3s ease;
    background: white;
  }
  
  .art-piece:hover {
    transform: translateY(-5px);
    box-shadow: 0 8px 24px rgba(0, 0, 0, 0.15);
  }
  
  .media-container {
    position: relative;
    width: 100%;
    height: 0;
    padding-bottom: 75%; /* 4:3 aspect ratio */
    overflow: hidden;
    background: #f5f5f5;
  }
  
  .media-container img {
    position: absolute;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    object-fit: cover;
    transition: transform 0.3s ease;
  }
  
  .media-container video {
    position: absolute;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    object-fit: cover;
  }
  
  .clickable {
    cursor: pointer;
  }
  
  .clickable:hover img {
    transform: scale(1.03);
  }
  
  .fullsize-overlay {
    position: fixed;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    background: rgba(0, 0, 0, 0.9);
    display: flex;
    align-items: center;
    justify-content: center;
    z-index: 1000;
    padding: 2rem;
  }
  
  .fullsize-content {
    position: relative;
    max-width: 100%;
    max-height: 100%;
  }
  
  .fullsize-content img {
    max-width: 100%;
    max-height: 90vh;
    object-fit: contain;
    border-radius: 4px;
  }
  
  .close-btn {
    position: absolute;
    top: -40px;
    right: 0;
    background: none;
    border: none;
    color: white;
    font-size: 2rem;
    cursor: pointer;
    padding: 0;
    width: 40px;
    height: 40px;
    display: flex;
    align-items: center;
    justify-content: center;
  }
  
  .loading {
    position: absolute;
    top: 50%;
    left: 50%;
    transform: translate(-50%, -50%);
    color: white;
    font-size: 1.2rem;
  }
  
  .gif-container {
    position: relative;
    width: 100%;
    height: 100%;
  }
  
  .gif-thumbnail {
    position: absolute;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    object-fit: cover;
    filter: blur(2px);
    z-index: 1;
  }
  
  .gif-animated {
    position: absolute;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    object-fit: contain;
    z-index: 2;
  }
  
  .info {
    padding: 1.5rem;
  }
  
  .info h4 {
    margin: 0 0 0.5rem;
    font-size: 1.25rem;
    font-weight: 600;
  }
  
  .info p {
    margin: 0 0 1rem;
    color: #555;
    font-size: 0.9rem;
    line-height: 1.5;
  }
  
  .type-badge {
    display: inline-block;
    padding: 0.25rem 0.75rem;
    border-radius: 20px;
    font-size: 0.8rem;
    font-weight: 500;
    margin-right: 0.5rem;
  }
  
  .type-badge.still {
    background: #e3f2fd;
    color: #1976d2;
  }
  
  .type-badge.animation {
    background: #e8f5e9;
    color: #388e3c;
  }
  
  .type-badge.gif {
    background: #fff3e0;
    color: #f57c00;
  }
  
  .click-hint {
    display: block;
    margin-top: 0.5rem;
    font-size: 0.8rem;
    color: #777;
    font-style: italic;
  }
</style>
