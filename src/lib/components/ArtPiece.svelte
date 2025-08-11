<script>
  export let artwork;
  import { CF_IMAGES_ACCOUNT_HASH, CUSTOM_DOMAIN } from '$lib/config.js';
  
  let showFullSize = false;
  let isLoading = true;
  
  // Function to create Cloudflare Images URL with custom domain
  function createImageUrl(imageId, variant = 'full') {
    return `https://${CUSTOM_DOMAIN}/cdn-cgi/imagedelivery/${CF_IMAGES_ACCOUNT_HASH}/${imageId}/${variant}`;
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
            tabindex="0"
          >
            {#if isLoading}
              <div class="loading">Loading full resolution...</div>
            {/if}
            <img 
              src={artwork.imageUrl}
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
        src={artwork.imageUrl}
        poster={getThumbnailUrl(artwork.thumbnailId, 'poster')}
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
          src={getThumbnailUrl(artwork.thumbnailId, 'static')}
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

<!-- Style section remains the same -->
