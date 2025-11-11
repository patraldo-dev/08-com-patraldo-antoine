<!-- src/lib/components/StoryView.svelte -->
<script>
  import { onMount, createEventDispatcher } from 'svelte';
  import { CF_IMAGES_ACCOUNT_HASH, CUSTOM_DOMAIN } from '$lib/config.js';
  import InkReveal from './ui/InkReveal.svelte';
  
  const dispatch = createEventDispatcher();
  
  export let artwork;
  
  let isLoading = true;
  let imageError = false;
  let scrollY = 0;
  let contentEl;
  
  function createImageUrl(imageId, variant = '') {
    const baseUrl = `https://${CUSTOM_DOMAIN}/cdn-cgi/imagedelivery/${CF_IMAGES_ACCOUNT_HASH}/${imageId}`;
    return variant ? `${baseUrl}/${variant}` : baseUrl;
  }
  
  function handleClose() {
    dispatch('close');
  }
  
  function handleKeydown(event) {
    if (event.key === 'Escape') {
      handleClose();
    }
  }
  
  onMount(() => {
    if (typeof document !== 'undefined') {
      document.body.style.overflow = 'hidden';
    }
    return () => {
      if (typeof document !== 'undefined') {
        document.body.style.overflow = '';
      }
    };
  });
  
  $: imageUrl = artwork.type === 'still' && artwork.thumbnailId
    ? createImageUrl(artwork.thumbnailId, 'desktop')
    : artwork.imageUrl;
    
  $: parallaxOffset = scrollY * 0.3;
</script>

<svelte:window on:keydown={handleKeydown} />

<div class="story-view">
  <button class="close-btn" on:click={handleClose} aria-label="Close story">
    <span class="close-icon">←</span>
    <span class="close-text">Back to sketchbook</span>
  </button>

  <div class="story-content" bind:this={contentEl} on:scroll={(e) => scrollY = e.target.scrollTop}>
    <!-- Hero Image with Parallax -->
    <div class="hero-section" style="transform: translateY({parallaxOffset}px)">
      {#if artwork.type === 'animation' && artwork.videoId}
        <div class="video-container">
          <iframe
            title="Video: {artwork.title}"
            src="https://customer-9kroafxwku5qm6fx.cloudflarestream.com/{artwork.videoId}/iframe?poster={encodeURIComponent(artwork.thumbnailUrl || '')}"
            allow="accelerometer; gyroscope; autoplay; encrypted-media; picture-in-picture"
            allowfullscreen
          ></iframe>
        </div>
      {:else}
        {#if isLoading}
          <div class="loading-state">
            <div class="sketch-loader"></div>
          </div>
        {/if}
        {#if imageError}
          <div class="error-message">
            <p>Failed to load image</p>
            <button class="retry-btn" on:click={() => { isLoading = true; imageError = false; }}>
              Try Again
            </button>
          </div>
        {:else}
          <img
            src={imageUrl}
            alt={artwork.title}
            class:loading={isLoading}
            on:load={() => isLoading = false}
            on:error={() => {
              isLoading = false;
              imageError = true;
            }}
          />
        {/if}
      {/if}
    </div>

    <!-- Story Content with Ink Reveal -->
    <div class="story-text">
      <InkReveal>
        <h1>{artwork.title}</h1>
      </InkReveal>
      
      <InkReveal delay={200}>
        <div class="meta">
          <span class="date">{artwork.date || 'Recently'}</span>
          <span class="type-badge {artwork.type}">
            {#if artwork.type === 'still'}📷
            {:else if artwork.type === 'animation'}🎬
            {:else if artwork.type === 'gif'}🎭
            {/if}
          </span>
        </div>
      </InkReveal>
      
      <InkReveal delay={400}>
        <div class="description">
          {artwork.description}
        </div>
      </InkReveal>
      
      {#if artwork.story}
        <InkReveal delay={600}>
          <div class="full-story">
            {artwork.story}
          </div>
        </InkReveal>
      {/if}
      
      {#if artwork.tags && artwork.tags.length > 0}
        <InkReveal delay={800}>
          <div class="tags">
            {#each artwork.tags as tag}
              <span class="tag">#{tag}</span>
            {/each}
          </div>
        </InkReveal>
      {/if}
    </div>
  </div>
</div>

<style>
  .story-view {
    position: fixed;
    top: 0;
    left: 0;
    width: 100vw;
    height: 100vh;
    background: linear-gradient(135deg, #f8f7f4 0%, #edebe8 100%);
    z-index: 100;
    overflow: hidden;
  }

  .close-btn {
    position: fixed;
    top: 2rem;
    left: 2rem;
    display: flex;
    align-items: center;
    gap: 0.5rem;
    background: rgba(255, 255, 255, 0.95);
    border: 2px solid #d4c9a8;
    padding: 0.75rem 1.5rem;
    border-radius: 50px;
    cursor: pointer;
    z-index: 10;
    font-family: 'Georgia', serif;
    box-shadow: 0 4px 12px rgba(0,0,0,0.1);
    transition: all 0.3s ease;
  }

  .close-btn:hover {
    background: white;
    transform: translateX(-5px);
    box-shadow: 0 6px 16px rgba(0,0,0,0.15);
  }

  .close-icon {
    font-size: 1.5rem;
    color: #2c5e3d;
  }

  .close-text {
    font-size: 0.9rem;
    color: #4a4a3c;
  }

  .story-content {
    width: 100%;
    height: 100vh;
    overflow-y: auto;
    scroll-behavior: smooth;
  }

  .hero-section {
    width: 100%;
    height: 70vh;
    position: relative;
    display: flex;
    align-items: center;
    justify-content: center;
    overflow: hidden;
    background: linear-gradient(180deg, rgba(212, 201, 168, 0.1) 0%, transparent 100%);
  }

  .hero-section img {
    max-width: 90%;
    max-height: 90%;
    object-fit: contain;
    border: 8px solid white;
    box-shadow: 0 10px 40px rgba(0,0,0,0.2);
    border-radius: 4px;
    opacity: 1;
    transition: opacity 0.6s ease;
  }

  .hero-section img.loading {
    opacity: 0;
  }

  .video-container {
    width: 90%;
    max-width: 1200px;
    aspect-ratio: 16/9;
    border: 8px solid white;
    box-shadow: 0 10px 40px rgba(0,0,0,0.2);
    border-radius: 4px;
    overflow: hidden;
  }

  .video-container iframe {
    width: 100%;
    height: 100%;
    border: none;
  }

  .loading-state {
    position: absolute;
    top: 50%;
    left: 50%;
    transform: translate(-50%, -50%);
  }

  .sketch-loader {
    width: 60px;
    height: 60px;
    border: 3px solid #d4c9a8;
    border-top-color: #4a4a3c;
    border-radius: 50%;
    animation: spin 1s linear infinite;
  }

  @keyframes spin {
    to { transform: rotate(360deg); }
  }

  .error-message {
    position: absolute;
    top: 50%;
    left: 50%;
    transform: translate(-50%, -50%);
    text-align: center;
    padding: 2rem;
    background: rgba(255, 255, 255, 0.9);
    border-radius: 8px;
    box-shadow: 0 4px 12px rgba(0,0,0,0.1);
  }

  .error-message p {
    margin: 0 0 1rem;
    color: #4a4a3c;
  }

  .retry-btn {
    padding: 0.5rem 1rem;
    background: #2c5e3d;
    color: white;
    border: none;
    border-radius: 4px;
    cursor: pointer;
    font-family: inherit;
  }

  .retry-btn:hover {
    background: #234a31;
  }

  .story-text {
    max-width: 700px;
    margin: 0 auto;
    padding: 3rem 2rem 5rem;
  }

  .story-text h1 {
    font-family: 'Georgia', serif;
    font-size: 2.5rem;
    color: #2c5e3d;
    margin-bottom: 1rem;
    line-height: 1.2;
  }

  .meta {
    display: flex;
    align-items: center;
    gap: 1rem;
    margin-bottom: 2rem;
    padding-bottom: 1rem;
    border-bottom: 1px dotted #d4c9a8;
  }

  .date {
    font-style: italic;
    color: #666;
    font-size: 0.9rem;
  }

  .type-badge {
    padding: 0.25rem 0.75rem;
    border-radius: 20px;
    font-size: 0.85rem;
  }

  .type-badge.still { background: #e3f2fd; }
  .type-badge.animation { background: #e8f5e9; }
  .type-badge.gif { background: #fff3e0; }

  .description, .full-story {
    font-family: 'Georgia', serif;
    font-size: 1.1rem;
    line-height: 1.8;
    color: #4a4a3c;
    margin-bottom: 2rem;
  }

  .full-story {
    white-space: pre-wrap;
  }

  .tags {
    display: flex;
    flex-wrap: wrap;
    gap: 0.5rem;
    margin-top: 2rem;
  }

  .tag {
    background: rgba(212, 201, 168, 0.3);
    padding: 0.25rem 0.75rem;
    border-radius: 15px;
    font-size: 0.85rem;
    color: #4a4a3c;
  }

  @media (max-width: 768px) {
    .close-btn {
      top: 1rem;
      left: 1rem;
      padding: 0.5rem 1rem;
    }
    
    .close-text {
      display: none;
    }
    
    .story-text h1 {
      font-size: 1.8rem;
    }
    
    .story-text {
      padding: 2rem 1.5rem 3rem;
    }
  }
</style>
