<!-- src/lib/components/canal/VideoCard.svelte -->
<script>
  let { film, customerCode, cloudflareAccountHash = '' } = $props();
  
  // Reactive thumbnail URL
  const thumbnailUrl = $derived(
    film.thumbnail_url?.startsWith('http') 
      ? film.thumbnail_url
      : cloudflareAccountHash && film.thumbnail_url
      ? `https://imagedelivery.net/${cloudflareAccountHash}/${film.thumbnail_url}/public`
      : ''
  );
  
  function formatDuration(seconds) {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins}:${secs.toString().padStart(2, '0')}`;
  }
  
  function handleImageError(event) {
    event.target.style.display = 'none';
    const placeholder = event.target.nextElementSibling;
    if (placeholder?.classList.contains('thumbnail-placeholder')) {
      placeholder.style.display = 'flex';
    }
  }
</script>

<a href={`/canal/watch/${film.id}`} class="video-card">
  <div class="thumbnail-container">
    {#if thumbnailUrl}
      <img 
        src={thumbnailUrl} 
        alt={film.title}
        loading="lazy"
        onerror={handleImageError}
      />
    {/if}
    
    <div class="thumbnail-placeholder" class:show={!thumbnailUrl}>
      <div class="play-icon">
        <svg width="48" height="48" viewBox="0 0 24 24" fill="white">
          <path d="M8 5v14l11-7z"/>
        </svg>
      </div>
    </div>
    
    <div class="duration-badge">
      {formatDuration(film.duration)}
    </div>
  </div>
  
  <div class="video-info">
    <h3>{film.title}</h3>
    {#if film.description}
      <p class="description">{film.description.slice(0, 100)}...</p>
    {/if}
    <div class="metadata">
      <span class="views">{film.view_count} views</span>
      {#if film.artwork?.type}
        <span class="type">{film.artwork.type}</span>
      {/if}
    </div>
  </div>
</a>

<style>
  .video-card {
    display: block;
    text-decoration: none;
    color: inherit;
    transition: transform 0.2s;
  }
  
  .video-card:hover {
    transform: translateY(-4px);
  }
  
  .thumbnail-container {
    position: relative;
    width: 100%;
    padding-bottom: 56.25%; /* 16:9 */
    background: #000;
    border-radius: 8px;
    overflow: hidden;
  }
  
  .thumbnail-container img {
    position: absolute;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    object-fit: cover;
  }
  
  .thumbnail-placeholder {
    position: absolute;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    display: none;
    align-items: center;
    justify-content: center;
    background: #1a1a1a;
  }
  
  .thumbnail-placeholder.show {
    display: flex;
  }
  
  .duration-badge {
    position: absolute;
    bottom: 8px;
    right: 8px;
    background: rgba(0, 0, 0, 0.8);
    color: white;
    padding: 4px 8px;
    border-radius: 4px;
    font-size: 0.85rem;
  }
  
  .video-info {
    padding: 1rem 0;
  }
  
  .video-info h3 {
    margin: 0 0 0.5rem;
    font-size: 1.1rem;
  }
  
  .description {
    color: #666;
    font-size: 0.9rem;
    margin: 0 0 0.5rem;
  }
  
  .metadata {
    display: flex;
    gap: 1rem;
    font-size: 0.85rem;
    color: #999;
  }
</style>
