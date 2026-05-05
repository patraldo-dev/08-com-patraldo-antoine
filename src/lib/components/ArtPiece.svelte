<script>
  import { CF_IMAGES_ACCOUNT_HASH, CUSTOM_DOMAIN } from '$lib/config.js';
  import { goto } from '$app/navigation';
  import { onMount } from 'svelte';
  import { checkARSupport } from '$lib/ar-detect.js';

  let { artwork } = $props();

  let arStatus = $state('hidden'); // hidden | teaser | supported

  let showFullSize = $state(false);
  let isLoading = $state(true);
  let imageError = $state(false);

  onMount(async () => {
    arStatus = await checkARSupport();
  });

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

  let posterUrl = $derived(
    artwork.thumbnailUrl
      ? artwork.thumbnailUrl.split('?')[0]
      : artwork.thumbnailId
        ? getThumbnailUrl(artwork.thumbnailId, 'thumbnail')
        : createImageUrl('f8a136eb-363e-4a24-0f54-70bb4f4bf800', 'thumbnail')
  );
</script>

<div class="art-piece">
  <div
    class="media-container {artwork.type === 'still' ? 'clickable' : ''}"
    onclick={handleClick}
    onkeydown={handleKeydown}
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
    {#if arStatus === 'supported'}
      <button class="ar-badge" onclick={(e) => { e.stopPropagation(); goto('/ar/image/' + encodeURIComponent(artwork.imageId)); }}>
        👤 Ver en AR
      </button>
    {:else if arStatus === 'teaser'}
      <a class="ar-badge teaser" href="/ar/image/{artwork.imageId}" onclick={(e) => e.stopPropagation();}>👤 AR</a>
    {/if}
    {#if artwork.type === 'animation' && artwork.videoId}
      {#if arStatus === 'supported'}
        <button class="ar-badge video" onclick={(e) => { e.stopPropagation(); goto('/ar/video/' + encodeURIComponent(artwork.videoId)); }}>
          👁️ Ver en AR
        </button>
      {:else if arStatus === 'teaser'}
        <a class="ar-badge video teaser" href="/ar/video/{artwork.videoId}" onclick={(e) => e.stopPropagation();}>👁️ AR</a>
      {/if}
    {/if}
  </div>
</div>

{#if showFullSize}
  <div
    class="modal-overlay"
    onclick={closeFullSize}
    role="dialog"
    aria-modal="true"
    aria-label="Full size image viewer"
    tabindex="0"
    onkeydown={handleContentKeydown}
  >
    <div class="modal-content" onclick={(e) => e.stopPropagation()}>
      {#if isLoading}
        <div class="loading">Loading full resolution...</div>
      {/if}

      {#if imageError}
        <div class="error-message">
          <p>Failed to load image</p>
          <button class="retry-btn" onclick={handleClick}>Try Again</button>
        </div>
      {:else}
        <img
          src={createImageUrl(artwork.thumbnailId, 'desktop')}
          alt={artwork.title}
          class={isLoading ? 'loading' : ''}
          onload={() => (isLoading = false)}
          onerror={() => {
            isLoading = false;
            imageError = true;
          }}
        />
      {/if}

      <button
        class="close-btn"
        onclick={closeFullSize}
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
    background: var(--color-surface-raised);
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
    background: var(--color-surface);
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
    z-index: var(--z-modal);
  }

  .modal-content {
    position: relative;
    max-width: 100%;
    max-height: 90vh;
    z-index: var(--z-modal-content);
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
    top: -40px;
    right: 0;
    background: rgba(255, 255, 255, 0.2);
    border: none;
    color: white;
    width: 36px;
    height: 36px;
    border-radius: 50%;
    font-size: 1.5rem;
    cursor: pointer;
    display: flex;
    align-items: center;
    justify-content: center;
    transition: background 0.2s;
  }

  .close-btn:hover {
    background: rgba(255, 255, 255, 0.3);
  }

  .close-icon {
    line-height: 1;
    margin-top: -2px;
  }

  .loading {
    display: flex;
    align-items: center;
    justify-content: center;
    position: absolute;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    background: var(--color-surface);
    color: var(--color-text-muted);
    font-size: 0.9rem;
  }

  .error-message {
    text-align: center;
    padding: 2rem;
    color: white;
  }

  .error-message p {
    margin-bottom: 1rem;
  }

  .retry-btn {
    background: var(--color-gold);
    border: none;
    color: var(--color-text);
    padding: 0.5rem 1.5rem;
    border-radius: 4px;
    cursor: pointer;
  }

  .info {
    padding: 1rem;
  }

  .info h4 {
    margin: 0 0 0.5rem;
    font-size: 1.25rem;
    font-weight: 600;
  }

  .info p {
    margin: 0 0 1rem;
    color: var(--color-text-dim);
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

  .ar-badge {
    display: inline-block;
    margin-top: 0.5rem;
    padding: 0.3rem 0.8rem;
    border-radius: 20px;
    font-size: 0.8rem;
    font-weight: 600;
    background: #c9a87c;
    color: #1a1a1a;
    border: none;
    cursor: pointer;
    transition: transform 0.1s;
  }
  .ar-badge:hover { transform: scale(1.05); }
  .ar-badge.teaser {
    opacity: 0.5;
    text-decoration: none;
    cursor: default;
  }
  .ar-badge.teaser:hover { transform: none; }

  @media (max-width: 768px) {
    .modal-overlay { padding: 0; }
    .close-btn { width: 2.5rem; height: 2.5rem; top: -35px; right: 5px; }
    .close-icon { font-size: 1.5rem; }
    .modal-content img { max-height: 85vh; }
  }
</style>
