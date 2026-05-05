<!-- src/lib/components/VideoDetailView.svelte -->
<script>
  import { onMount } from 'svelte';
  import { checkARSupport } from '$lib/ar-detect.js';
  
  let { artwork, onclose } = $props();
  
  let arStatus = $state('hidden');

  let videoId = $derived(artwork.video_id || artwork.videoId);
  let hasVideo = $derived(!!videoId);

  onMount(async () => { arStatus = await checkARSupport(); });
  
  function handleClose() {
    onclose?.();
  }
  
  function handleKeydown(event) {
    if (event.key === 'Escape') {
      handleClose();
    }
  }
  
  onMount(() => {
    window.addEventListener('keydown', handleKeydown);
    return () => window.removeEventListener('keydown', handleKeydown);
  });
</script>

{#snippet videocontent()}
  {#if hasVideo}
    <iframe
      title="Video: {artwork.display_name || artwork.title}"
      src="https://customer-9kroafxwku5qm6fx.cloudflarestream.com/{videoId}/iframe?autoplay=true"
      allow="accelerometer; gyroscope; autoplay; encrypted-media; picture-in-picture; fullscreen"
      allowfullscreen
    ></iframe>
  {:else}
    <div class="no-video">
      <p>No video available for this artwork</p>
      <button class="back-btn" onclick={handleClose}>
        Go Back
      </button>
    </div>
  {/if}
{/snippet}

<div class="video-detail-view">
  <button class="close-btn" onclick={handleClose} aria-label="Close video">
    <span class="close-icon">←</span>
    <span class="close-text">Back to story</span>
  </button>
  
  <div class="video-container">
    {@render videocontent()}
  </div>
  
  <div class="video-info">
    <h2>{artwork.display_name || artwork.title}</h2>
    {#if artwork.description}
      <p class="description">{artwork.description}</p>
    {/if}
    {#if hasVideo}
      {#if arStatus === 'supported'}
        <a href="/ar/video/{videoId}" class="ar-video-btn" target="_blank">👁️ Ver en AR</a>
      {:else if arStatus === 'teaser'}
        <span class="ar-video-btn teaser">👁️ AR</span>
      {/if}
    {/if}
  </div>
</div>

<style>
  .video-detail-view {
    position: fixed;
    top: 0;
    left: 0;
    width: 100vw;
    height: 100vh;
    background: #000;
    z-index: 200;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
  }
  
  .close-btn {
    position: fixed;
    top: 2rem;
    left: 2rem;
    display: flex;
    align-items: center;
    gap: 0.5rem;
    background: var(--color-surface-raised);
    border: 2px solid var(--color-gold);
    padding: 0.75rem 1.5rem;
    border-radius: 50px;
    cursor: pointer;
    z-index: 10;
    font-family: 'Georgia', serif;
    box-shadow: 0 4px 12px rgba(0,0,0,0.3);
    transition: all 0.3s ease;
  }
  
  .close-btn:hover {
    background: var(--color-surface-raised);
    transform: translateX(-5px);
    box-shadow: 0 6px 16px rgba(0,0,0,0.4);
  }
  
  .close-icon {
    font-size: 1.5rem;
    color: var(--color-green);
  }
  
  .close-text {
    font-size: 0.9rem;
    color: var(--color-text-dim);
  }
  
  .video-container {
    width: 90vw;
    max-width: 1400px;
    aspect-ratio: 16/9;
    background: #000;
    border-radius: 8px;
    overflow: hidden;
    box-shadow: 0 20px 60px rgba(0,0,0,0.5);
  }
  
  .video-container iframe {
    width: 100%;
    height: 100%;
    border: none;
  }
  
  .no-video {
    width: 100%;
    height: 100%;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    color: white;
    gap: 1rem;
  }
  
  .no-video p {
    font-size: 1.2rem;
    margin: 0;
  }
  
  .back-btn {
    padding: 0.75rem 1.5rem;
    background: var(--color-green);
    color: white;
    border: none;
    border-radius: 4px;
    cursor: pointer;
    font-size: 1rem;
    font-family: inherit;
    transition: background 0.3s;
  }
  
  .back-btn:hover {
    background: var(--color-green-hover);
  }
  
  .video-info {
    position: fixed;
    bottom: 2rem;
    left: 50%;
    transform: translateX(-50%);
    max-width: 800px;
    text-align: center;
    color: white;
    text-shadow: 0 2px 4px rgba(0,0,0,0.8);
    padding: 0 2rem;
  }
  
  .video-info h2 {
    font-family: 'Georgia', serif;
    font-size: 2rem;
    margin: 0 0 0.5rem;
    font-weight: 300;
  }
  
  .description {
    font-size: 1rem;
    opacity: 0.9;
    margin: 0;
  }

  .ar-video-btn {
    display: inline-block;
    margin-top: 0.75rem;
    padding: 0.5rem 1rem;
    background: rgba(44,94,61,0.9);
    color: white;
    border-radius: 8px;
    text-decoration: none;
    font-size: 0.85rem;
    font-weight: 600;
  }
  .ar-video-btn:active { opacity: 0.8; }
  .ar-video-btn.teaser { opacity: 0.4; pointer-events: none; }
  
  @media (max-width: 768px) {
    .close-btn {
      top: 1rem;
      left: 1rem;
      padding: 0.5rem 1rem;
    }
    
    .close-text {
      display: none;
    }
    
    .video-container {
      width: 100vw;
      height: 100vh;
      max-width: none;
      border-radius: 0;
      aspect-ratio: auto;
    }
    
    .video-info {
      bottom: 1rem;
      padding: 0 1rem;
    }
    
    .video-info h2 {
      font-size: 1.5rem;
    }
    
    .description {
      font-size: 0.9rem;
    }
  }
</style>
