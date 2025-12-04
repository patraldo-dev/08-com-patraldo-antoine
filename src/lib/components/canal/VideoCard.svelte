<!-- src/lib/components/canal/VideoCard.svelte -->
<script>
  let { film, customerCode, cloudflareAccountHash = '' } = $props();
  
  // Reactive thumbnail URL
  const thumbnailUrl = $derived(
    film.thumbnail_url && cloudflareAccountHash
      ? `https://imagedelivery.net/${cloudflareAccountHash}/${film.thumbnail_url}/public`
      : film.thumbnail_url?.startsWith('http')
      ? film.thumbnail_url
      : ''
  );
  
  let imageError = $state(false);
  
  function formatDuration(seconds) {
    if (!seconds || seconds === 0) return '0:15'; // Default for artworks without duration
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins}:${secs.toString().padStart(2, '0')}`;
  }
  
  function handleImageError() {
    imageError = true;
  }
</script>

<a href={`/canal/watch/${film.id}`} class="video-card">
  <div class="thumbnail-container">
    {#if thumbnailUrl && !imageError}
      <img 
        src={thumbnailUrl} 
        alt={film.title}
        loading="lazy"
        onerror={handleImageError}
      />
    {:else}
      <div class="thumbnail-placeholder">
        <div class="play-icon">
          <svg width="48" height="48" viewBox="0 0 24 24" fill="white">
            <path d="M8 5v14l11-7z"/>
          </svg>
        </div>
      </div>
    {/if}
    
    <div class="duration-badge">
      {formatDuration(film.duration)}
    </div>
  </div>
  
  <div class="video-info">
    <h3>{film.title}</h3>
    {#if film.description}
      <p class="description">{film.description.slice(0, 100)}{film.description.length > 100 ? '...' : ''}</p>
    {/if}
    <div class="metadata">
      <span class="views">{film.view_count || 0} {film.view_count === 1 ? 'view' : 'views'}</span>
      {#if film.type}
        <span class="type">{film.type}</span>
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
    cursor: pointer;
  }
  
  .video-card:hover {
    transform: translateY(-4px);
  }
  
  .thumbnail-container {
    position: relative;
    width: 100%;
    padding-bottom: 56.25%; /* 16:9 */
    background: #1a1a1a;
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
    display: flex;
    align-items: center;
    justify-content: center;
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  }
  
  .play-icon {
    opacity: 0.8;
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
    font-weight: 500;
  }
  
  .video-info {
    padding: 1rem 0;
  }
  
  .video-info h3 {
    margin: 0 0 0.5rem;
    font-size: 1.1rem;
    font-weight: 600;
    color: #fff;
  }
  
  .description {
    color: #aaa;
    font-size: 0.9rem;
    margin: 0 0 0.5rem;
    line-height: 1.4;
  }
  
  .metadata {
    display: flex;
    gap: 1rem;
    font-size: 0.85rem;
    color: #666;
  }
  
  .type {
    text-transform: capitalize;
  }
</style>
