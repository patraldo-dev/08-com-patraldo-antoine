<!-- src/lib/components/canal/VideoCard.svelte -->
<script>
  let { film, customerCode } = $props();
  
  function formatDuration(seconds) {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins}:${secs.toString().padStart(2, '0')}`;
  }
</script>

<a href={`/canal/watch/${film.id}`} class="video-card">
  <div class="thumbnail-container">
    {#if film.thumbnail_url}
      <img 
        src={film.thumbnail_url} 
        alt={film.title}
        loading="lazy"
      />
    {:else}
      <div class="thumbnail-placeholder">
        <span>Video</span>
      </div>
    {/if}
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
    background: white;
    border-radius: 8px;
    overflow: hidden;
    box-shadow: 0 2px 8px rgba(0,0,0,0.1);
    transition: transform 0.2s, box-shadow 0.2s;
  }
  
  .video-card:hover {
    transform: translateY(-4px);
    box-shadow: 0 4px 16px rgba(0,0,0,0.15);
  }
  
  .thumbnail-container {
    position: relative;
    aspect-ratio: 16/9;
    background: #f0f0f0;
    overflow: hidden;
  }
  
  .thumbnail-container img {
    width: 100%;
    height: 100%;
    object-fit: cover;
  }
  
  .thumbnail-placeholder {
    width: 100%;
    height: 100%;
    display: flex;
    align-items: center;
    justify-content: center;
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    color: white;
    font-size: 1.5rem;
  }
  
  .duration-badge {
    position: absolute;
    bottom: 8px;
    right: 8px;
    background: rgba(0,0,0,0.8);
    color: white;
    padding: 4px 8px;
    border-radius: 4px;
    font-size: 0.8rem;
  }
  
  .video-info {
    padding: 1rem;
  }
  
  .video-info h3 {
    margin: 0 0 0.5rem 0;
    font-size: 1.1rem;
    line-height: 1.3;
  }
  
  .description {
    margin: 0 0 0.5rem 0;
    color: #666;
    font-size: 0.9rem;
    line-height: 1.4;
  }
  
  .metadata {
    display: flex;
    justify-content: space-between;
    font-size: 0.8rem;
    color: #888;
  }
  
  .type {
    text-transform: capitalize;
  }
</style>
