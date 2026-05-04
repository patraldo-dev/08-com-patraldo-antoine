<script>
  export let artwork;
  import { CF_IMAGES_ACCOUNT_HASH, CUSTOM_DOMAIN } from '$lib/config.js';

  let showFullSize = false;
  let isLoading = true;
  let imageError = false;

  function createImageUrl(imageId, variant = '') {
    const baseUrl = `https://${CUSTOM_DOMAIN}/cdn-cgi/imagedelivery/${CF_IMAGES_ACCOUNT_HASH}/${imageId}`;
    return variant ? `${baseUrl}/${variant}` : baseUrl;
  }

  function handleClick() {
    if (artwork.type === 'still') {
      showFullSize = true;
      isLoading = true;
      imageError = false;
      if (typeof document !== 'undefined') {
        document.body.style.overflow = 'hidden';
      }
    }
  }

  function closeFullSize(event) {
    if (event) event.stopPropagation();
    showFullSize = false;
    if (typeof document !== 'undefined') {
      document.body.style.overflow = '';
    }
  }

  function handleKeydown(event) {
    if (event.key === 'Enter' || event.key === ' ') {
      handleClick();
    }
    if (event.key === 'Escape' && showFullSize) {
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

  $: posterUrl = artwork.thumbnailUrl
    ? artwork.thumbnailUrl.split('?')[0]
    : artwork.thumbnailId
      ? getThumbnailUrl(artwork.thumbnailId, 'thumbnail')
      : createImageUrl('f8a136eb-363e-4a24-0f54-70bb4f4bf800', 'thumbnail');
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
    {:else if artwork.type === 'animation' && artwork.videoId}
      <div class="video-responsive-wrapper">
        <iframe
          title="Video artwork: {artwork.title}"
          src="https://customer-9kroafxwku5qm6fx.cloudflarestream.com/{artwork.videoId}/iframe?poster={encodeURIComponent(posterUrl)}"
          loading="lazy"
          allow="accelerometer; gyroscope; autoplay; encrypted-media; picture-in-picture"
          allowfullscreen
        ></iframe>
      </div>
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
    <h4>{artwork.display_name || artwork.title}</h4>
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

{#if showFullSize}
  <div
    class="modal-overlay"
    on:click={closeFullSize}
    role="dialog"
    aria-modal="true"
    aria-label="Full size image viewer"
    tabindex="0"
    on:keydown={handleContentKeydown}
  >
    <div class="modal-content" on:click|stopPropagation={() => {}}>
      {#if isLoading}
        <div class="loading">Loading full resolution...</div>
      {/if}

      {#if imageError}
        <div class="error-message">
          <p>Failed to load image</p>
          <button class="retry-btn" on:click={handleClick}>Try Again</button>
        </div>
      {:else}
        <img
          src={createImageUrl(artwork.thumbnailId, 'desktop')}
          alt={artwork.title}
          class:loading={isLoading}
          on:load={() => (isLoading = false)}
          on:error={() => {
            isLoading = false;
            imageError = true;
          }}
        />
      {/if}

      <button
        class="close-btn"
        on:click={closeFullSize}
        aria-label="Close full size view"
      >
        <span class="close-icon">&times;</span>
      </button>
    </div>
  </div>
{/if}

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
    padding-bottom: 75%;
    overflow: hidden;
    background: #f5f5f5;
  }

  .media-container img,
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

  .video-responsive-wrapper {
    position: absolute;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
  }

  /* MODAL: z-index from app.css */
  .modal-overlay {
    position: fixed;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    background: rgba(0, 0, 0, 0.9);
    display: flex;
    align-items: center;
    justify-content: center;
    padding: 1rem;
    z-index: var(--z-modal); /* 1000 */
  }

  .modal-content {
    position: relative;
    max-width: 100%;
    max-height: 90vh;
    z-index: var(--z-modal-content); /* 1001 */
  }

  .modal-content img {
    max-width: 100%;
    max-height: 90vh;
    object-fit: contain;
    border-radius: 4px;
    opacity: 1;
    transition: opacity 0.3s ease;
  }

  .modal-content img.loading {
    opacity: 0;
  }

  .close-btn {
    position: absolute;
    top: 1rem;
    right: 1rem;
    background: rgba(255, 255, 255, 0.9);
    border: none;
    border-radius: 50%;
    width: 3rem;
    height: 3rem;
    display: flex;
    align-items: center;
    justify-content: center;
    cursor: pointer;
    box-shadow: 0 2px 8px rgba(0, 0, 0, 0.2);
  }

  .close-btn:hover {
    background: white;
    transform: scale(1.1);
  }

  .close-icon {
    font-size: 2rem;
    color: #333;
  }

  .loading,
  .error-message {
    position: absolute;
    top: 50%;
    left: 50%;
    transform: translate(-50%, -50%);
    color: white;
    text-align: center;
    padding: 1.5rem;
    background: rgba(0, 0, 0, 0.7);
    border-radius: 8px;
  }

  .error-message p {
    margin: 0 0 1rem;
  }

  .retry-btn {
    padding: 0.5rem 1rem;
    background: #667eea;
    color: white;
    border: none;
    border-radius: 4px;
    cursor: pointer;
  }

  .retry-btn:hover {
    background: #5a67d8;
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
    z-index: var(--z-content);      
  }

  .gif-animated {
    position: absolute;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    object-fit: contain;
    z-index: calc(var(--z-content) + 1); 
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
  }

  .type-badge {
    display: inline-block;
    padding: 0.25rem 0.75rem;
    border-radius: 20px;
    font-size: 0.8rem;
    font-weight: 500;
    margin-right: 0.5rem;
  }

  .type-badge.still { background: #e3f2fd; color: #1976d2; }
  .type-badge.animation { background: #e8f5e9; color: #388e3c; }
  .type-badge.gif { background: #fff3e0; color: #f57c00; }

  .click-hint {
    display: block;
    margin-top: 0.5rem;
    font-size: 0.8rem;
    color: #777;
    font-style: italic;
  }

  @media (max-width: 768px) {
    .modal-overlay { padding: 0; }
    .close-btn { width: 2.5rem; height: 2.5rem; top: 0.5rem; right: 0.5rem; }
    .close-icon { font-size: 1.5rem; }
    .modal-content img { max-height: 85vh; }
  }
</style>
