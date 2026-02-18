<!-- src/lib/components/VideoDetailView.svelte -->
<script>
  import { createEventDispatcher } from 'svelte';
  
  const dispatch = createEventDispatcher();
  
  export let artwork;
  
  function handleClose() {
    dispatch('close');
  }
  
  function handleKeydown(event) {
    if (event.key === 'Escape') {
      handleClose();
    }
  }
  
  // Use video_id if it exists, otherwise fallback
  $: videoId = artwork.video_id || artwork.videoId;
  $: hasVideo = !!videoId;
</script>

<svelte:window on:keydown={handleKeydown} />

<div class="video-detail-view">
  <button class="close-btn" on:click={handleClose} aria-label="Close video">
    <span class="close-icon">←</span>
    <span class="close-text">Back to story</span>
  </button>
  
  <div class="video-container">
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
        <button class="back-btn" on:click={handleClose}>
          Go Back
        </button>
      </div>
    {/if}
  </div>
  
  <div class="video-info">
    <h2>{artwork.display_name || artwork.title}</h2>
    {#if artwork.description}
      <p class="description">{artwork.description}</p>
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
    background: rgba(255, 255, 255, 0.95);
    border: 2px solid #d4c9a8;
    padding: 0.75rem 1.5rem;
    border-radius: 50px;
    cursor: pointer;
    z-index: 10;
    font-family: 'Georgia', serif;
    box-shadow: 0 4px 12px rgba(0,0,0,0.3);
    transition: all 0.3s ease;
  }
  
  .close-btn:hover {
    background: white;
    transform: translateX(-5px);
    box-shadow: 0 6px 16px rgba(0,0,0,0.4);
  }
  
  .close-icon {
    font-size: 1.5rem;
    color: #2c5e3d;
  }
  
  .close-text {
    font-size: 0.9rem;
    color: #4a4a3c;
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
    background: #2c5e3d;
    color: white;
    border: none;
    border-radius: 4px;
    cursor: pointer;
    font-size: 1rem;
    font-family: inherit;
    transition: background 0.3s;
  }
  
  .back-btn:hover {
    background: #234a31;
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
