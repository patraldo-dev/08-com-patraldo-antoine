<!-- src/lib/components/StoryView.svelte -->
<script>
  import { onMount, createEventDispatcher } from 'svelte';
  import { CF_IMAGES_ACCOUNT_HASH, CUSTOM_DOMAIN } from '$lib/config.js';
  import InkReveal from './ui/InkReveal.svelte';
  import VideoDetailView from './VideoDetailView.svelte';
  import ColorPalette from '$lib/components/ColorPalette.svelte';  
  import VideoPlayer from '$lib/components/VideoPlayer.svelte';

  const dispatch = createEventDispatcher();
  
  export let artwork;
  
  let isLoading = true;
  let imageError = false;
  let scrollY = 0;
  let contentEl;
  let storyContent = [];
  let showVideoDetail = false;
  
  function createImageUrl(imageId, variant = '') {
    const baseUrl = `https://${CUSTOM_DOMAIN}/cdn-cgi/imagedelivery/${CF_IMAGES_ACCOUNT_HASH}/${imageId}`;
    return variant ? `${baseUrl}/${variant}` : baseUrl;
  }
  
 function handleClose() {
  // Restore scrolling BEFORE dispatching close
  if (typeof document !== 'undefined') {
    document.body.style.overflow = '';
  }
  dispatch('close');
} 

  function openVideoDetail() {
    showVideoDetail = true;
  }
  
  function closeVideoDetail() {
    showVideoDetail = false;
  }
  
  function handleKeydown(event) {
    if (event.key === 'Escape') {
      if (showVideoDetail) {
        closeVideoDetail();
      } else {
        handleClose();
      }
    }
  }
  
  onMount(async () => {
    if (typeof document !== 'undefined') {
      document.body.style.overflow = 'hidden';
    }
    
    // Fetch story content if story is enabled
    if (artwork.story_enabled) {
      await fetchStoryContent();
    }
    
    return () => {
      if (typeof document !== 'undefined') {
        document.body.style.overflow = '';
      }
    };
  });
  
  async function fetchStoryContent() {
    try {
      // Fetch from your API endpoint
      const response = await fetch(`/api/story/${artwork.id}`);
      if (response.ok) {
        const data = await response.json();
        storyContent = data.content || [];
      }
    } catch (error) {
      console.error('Failed to load story content:', error);
    }
  }
  
  $: heroImageUrl = artwork.type === 'still' && artwork.image_id
    ? createImageUrl(artwork.image_id, 'desktop')
    : null;

  $: colorPaletteImageUrl = (() => {
  // For still images, use image_id
  if (artwork.image_id) {
    return createImageUrl(artwork.image_id, 'desktop');
  }
  
  // For animations, use thumbnailId (same as Sketchbook)
  if (artwork.thumbnailId) {
    return createImageUrl(artwork.thumbnailId, 'desktop');
  }
  
  // Fallback
  return artwork.imageUrl || null;
})(); 
    
  $: parallaxOffset = scrollY * 0.3;
  
  $: hasStoryContent = storyContent.length > 0;
  
  $: hasVideo = !!(artwork.video_id || artwork.videoId);
</script>

<svelte:window on:keydown={handleKeydown} />

{#if showVideoDetail}
  <VideoDetailView 
    artwork={artwork}
    on:close={closeVideoDetail}
  />
{:else}
  <div class="story-view">
    <button class="close-btn" on:click={handleClose} aria-label="Close story">
      <span class="close-icon">←</span>
      <span class="close-text">Back to sketchbook</span>
    </button>
    
    <div 
      class="story-content" 
      bind:this={contentEl} 
      on:scroll={(e) => scrollY = e.target.scrollTop}
    >
      <!-- Hero Section -->
      <div 
        class="hero-section" 
        class:clickable={hasVideo && artwork.type === 'still'}
        style="transform: translateY({parallaxOffset}px)"
        on:click={hasVideo && artwork.type === 'still' ? openVideoDetail : null}
        role={hasVideo && artwork.type === 'still' ? "button" : undefined}
        tabindex={hasVideo && artwork.type === 'still' ? "0" : undefined}
        on:keydown={hasVideo && artwork.type === 'still' ? (e) => e.key === 'Enter' && openVideoDetail() : null}
      >
{#if artwork.type === 'animation' && artwork.video_id}
  <div class="video-container">
    <VideoPlayer 
      videoId={artwork.video_id}
      customerCode="9kroafxwku5qm6fx"
      autoplay={true}
      muted={false}
      poster={artwork.thumbnailId 
    ? `https://imagedelivery.net/4bRSwPonOXfEIBVZiDXg0w/${artwork.thumbnailId}/gallery`
    : `https://customer-9kroafxwku5qm6fx.cloudflarestream.com/${artwork.video_id}/thumbnails/thumbnail.jpg?time=1s`}
    />
  </div>
        {:else if heroImageUrl}
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
              src={heroImageUrl}
              alt={artwork.display_name || artwork.title}
              class:loading={isLoading}
              on:load={() => isLoading = false}
              on:error={() => {
                isLoading = false;
                imageError = true;
              }}
            />
            {#if hasVideo && artwork.type === 'still'}
              <div class="play-overlay">
                <div class="play-button">
                  <svg width="60" height="60" viewBox="0 0 60 60" fill="none">
                    <circle cx="30" cy="30" r="28" fill="rgba(255,255,255,0.9)" stroke="#2c5e3d" stroke-width="2"/>
                    <path d="M24 18 L24 42 L42 30 Z" fill="#2c5e3d"/>
                  </svg>
                </div>
                <p class="play-hint">Click to watch video</p>
              </div>
            {/if}
          {/if}
        {/if}
      </div>
      
      <!-- Story Title & Meta -->
      <div class="story-text">
        <InkReveal>
          <h1>{artwork.display_name || artwork.title}</h1>
        </InkReveal>
        
        <InkReveal delay={200}>
          <div class="meta">
            <span class="date">{artwork.year || 'Recently'}</span>
            <span class="type-badge {artwork.type}">
              {#if artwork.type === 'still'}📷 Still
              {:else if artwork.type === 'animation'}🎬 Animation
              {:else if artwork.type === 'gif'}🎭 GIF
              {/if}
            </span>
          </div>
        </InkReveal>
        
        <!-- Main Description -->
        <InkReveal delay={400}>
          <div class="description">
            {artwork.description}
          </div>
        </InkReveal>
        
<InkReveal delay={600}>
  {#if colorPaletteImageUrl}
    <ColorPalette 
      imageUrl={colorPaletteImageUrl} 
      artworkTitle={artwork.display_name || artwork.title}
    />
  {/if}
</InkReveal>


        <!-- Story Intro (if exists) -->
        {#if artwork.story_intro}
          <InkReveal delay={800}>
            <div class="story-intro">
              {artwork.story_intro}
            </div>
          </InkReveal>
        {/if}
        
        <!-- Multi-media Story Content -->
        {#if hasStoryContent}
          {#each storyContent as item, index}
            <InkReveal delay={800 + (index * 200)}>
              <div class="story-block {item.content_type}">
                {#if item.content_type === 'heading'}
                  <h2 class="story-heading">{item.content_text}</h2>
                  
                {:else if item.content_type === 'text'}
                  <div class="story-paragraph">
                    {item.content_text}
                  </div>
                  
                {:else if item.content_type === 'image' && item.media_id}
                  <div class="story-image">
                    <img 
                      src={createImageUrl(item.media_id, 'desktop')} 
                      alt="Story illustration"
                      loading="lazy"
                    />
                  </div>
                  
                {:else if item.content_type === 'video' && item.video_id}
                  <div class="story-video">
                    <iframe
                      title="Story video clip"
                      src="https://customer-9kroafxwku5qm6fx.cloudflarestream.com/{item.video_id}/iframe"
                      allow="accelerometer; gyroscope; autoplay; encrypted-media; picture-in-picture"
                      allowfullscreen
                    ></iframe>
                  </div>
                {/if}
              </div>
            </InkReveal>
          {/each}
        {/if}
        
        <!-- Tags (if you implement them) -->
        {#if artwork.tags && artwork.tags.length > 0}
          <InkReveal delay={1000 + (storyContent.length * 200)}>
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
{/if}

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
  
  .hero-section.clickable {
    cursor: pointer;
  }
  
  .hero-section.clickable:hover img {
    transform: scale(1.02);
  }
  
  .hero-section img {
    max-width: 90%;
    max-height: 90%;
    object-fit: contain;
    border: 8px solid white;
    box-shadow: 0 10px 40px rgba(0,0,0,0.2);
    border-radius: 4px;
    opacity: 1;
    transition: opacity 0.6s ease, transform 0.3s ease;
  }
  
  .hero-section img.loading {
    opacity: 0;
  }
  
  .play-overlay {
    position: absolute;
    top: 50%;
    left: 50%;
    transform: translate(-50%, -50%);
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 1rem;
    pointer-events: none;
    transition: opacity 0.3s;
    opacity: 0;
  }
  
  .hero-section.clickable:hover .play-overlay {
    opacity: 1;
  }
  
  .play-button {
    animation: pulse 2s ease-in-out infinite;
  }
  
  @keyframes pulse {
    0%, 100% {
      transform: scale(1);
      opacity: 0.9;
    }
    50% {
      transform: scale(1.1);
      opacity: 1;
    }
  }
  
  .play-hint {
    color: white;
    font-size: 1rem;
    font-family: 'Georgia', serif;
    text-shadow: 0 2px 8px rgba(0,0,0,0.8);
    background: rgba(0,0,0,0.6);
    padding: 0.5rem 1rem;
    border-radius: 20px;
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
  
  .type-badge.still { background: #e3f2fd; color: #1976d2; }
  .type-badge.animation { background: #e8f5e9; color: #388e3c; }
  .type-badge.gif { background: #fff3e0; color: #f57c00; }
  
  .description, .story-intro {
    font-family: 'Georgia', serif;
    font-size: 1.1rem;
    line-height: 1.8;
    color: #4a4a3c;
    margin-bottom: 2rem;
  }
  
  .story-intro {
    font-style: italic;
    padding-left: 1rem;
    border-left: 3px solid #d4c9a8;
  }
  
  /* Story Content Blocks */
  .story-block {
    margin-bottom: 2rem;
  }
  
  .story-heading {
    font-family: 'Georgia', serif;
    font-size: 1.8rem;
    color: #2c5e3d;
    margin: 2.5rem 0 1rem;
    font-weight: 600;
  }
  
  .story-paragraph {
    font-family: 'Georgia', serif;
    font-size: 1.1rem;
    line-height: 1.8;
    color: #4a4a3c;
    white-space: pre-wrap;
  }
  
  .story-image {
    margin: 2rem 0;
    border-radius: 8px;
    overflow: hidden;
    box-shadow: 0 4px 20px rgba(0,0,0,0.1);
  }
  
  .story-image img {
    width: 100%;
    height: auto;
    display: block;
  }
  
  .story-video {
    margin: 2rem 0;
    aspect-ratio: 16/9;
    border-radius: 8px;
    overflow: hidden;
    box-shadow: 0 4px 20px rgba(0,0,0,0.1);
  }
  
  .story-video iframe {
    width: 100%;
    height: 100%;
    border: none;
  }
  
  .tags {
    display: flex;
    flex-wrap: wrap;
    gap: 0.5rem;
    margin-top: 3rem;
    padding-top: 2rem;
    border-top: 1px dotted #d4c9a8;
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
    
    .hero-section {
      height: 50vh;
    }
    
    .story-text h1 {
      font-size: 1.8rem;
    }
    
    .story-text {
      padding: 2rem 1.5rem 3rem;
    }
    
    .story-heading {
      font-size: 1.4rem;
    }
    
    .story-paragraph {
      font-size: 1rem;
    }
  }
</style>
