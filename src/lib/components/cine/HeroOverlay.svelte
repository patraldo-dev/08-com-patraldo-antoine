<!-- src/lib/components/cine/HeroOverlay.svelte -->
<script>
  import { t } from '$lib/i18n';
  
  let { film } = $props();
  
  function formatDuration(seconds) {
    if (!seconds || seconds === 0) return '0:15';
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins}:${secs.toString().padStart(2, '0')}`;
  }
  
  function formatViews(count) {
    if (count === 0) return $t('cine.hero.noViews');
    if (count === 1) return `1 ${$t('cine.hero.view')}`;
    return `${count} ${$t('cine.hero.views')}`;
  }
</script>

<div class="hero-overlay">
  <div class="brand">
    <a href="/" class="home-link">← {$t('cine.nav.home')}</a>
    <h1 class="channel-name">{$t('cine.hero.channelName')}</h1>
  </div>
  
  <div class="film-info">
    <h2 class="film-title">{film.title}</h2>
    <p class="film-description">{film.description}</p>
    <div class="metadata">
      <span class="duration">
        {$t('cine.hero.duration')}: {formatDuration(film.duration)}
      </span>
      <span class="views">
        {formatViews(film.view_count)}
      </span>
    </div>
    
    <!-- Gallery Button -->
    <div class="actions">
      <a href="/cine/gallery" class="gallery-btn">
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <rect x="3" y="3" width="7" height="7"></rect>
          <rect x="14" y="3" width="7" height="7"></rect>
          <rect x="14" y="14" width="7" height="7"></rect>
          <rect x="3" y="14" width="7" height="7"></rect>
        </svg>
        {$t('cine.nav.gallery')}
      </a>
    </div>
  </div>
</div>

<style>
  .hero-overlay {
    position: fixed;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    pointer-events: none;
    z-index: 10;
    background: linear-gradient(
      to top,
      rgba(0, 0, 0, 0.8) 0%,
      rgba(0, 0, 0, 0.4) 30%,
      transparent 50%
    );
  }
  
  .brand {
    position: absolute;
    top: 2rem;
    left: 2rem;
    pointer-events: auto;
  }
  
  .home-link {
    display: inline-block;
    color: #fff;
    text-decoration: none;
    margin-bottom: 1rem;
    opacity: 0.8;
    transition: opacity 0.2s;
    font-size: 0.95rem;
  }
  
  .home-link:hover {
    opacity: 1;
  }
  
  .channel-name {
    font-size: 1.5rem;
    font-weight: 700;
    color: #fff;
    text-shadow: 0 2px 8px rgba(0, 0, 0, 0.8);
    margin: 0;
  }
  
  .film-info {
    position: absolute;
    bottom: 4rem;
    left: 2rem;
    max-width: 600px;
    pointer-events: auto;
  }
  
  .film-title {
    font-size: 3rem;
    font-weight: 700;
    color: #fff;
    margin: 0 0 1rem;
    text-shadow: 0 2px 16px rgba(0, 0, 0, 0.9);
    line-height: 1.1;
  }
  
  .film-description {
    font-size: 1.1rem;
    color: #e0e0e0;
    margin: 0 0 1rem;
    text-shadow: 0 1px 8px rgba(0, 0, 0, 0.9);
    line-height: 1.5;
  }
  
  .metadata {
    display: flex;
    gap: 1.5rem;
    flex-wrap: wrap;
    margin-bottom: 1.5rem;
  }
  
  .duration, .views {
    color: #aaa;
    font-size: 0.9rem;
    text-shadow: 0 1px 4px rgba(0, 0, 0, 0.8);
  }
  
  /* Gallery Button Styles */
  .actions {
    margin-top: 1.5rem;
  }
  
  .gallery-btn {
    display: inline-flex;
    align-items: center;
    gap: 0.5rem;
    padding: 0.75rem 1.5rem;
    background: rgba(255, 255, 255, 0.15);
    backdrop-filter: blur(10px);
    border: 1px solid rgba(255, 255, 255, 0.3);
    border-radius: 8px;
    color: #fff;
    text-decoration: none;
    font-size: 0.95rem;
    font-weight: 500;
    transition: all 0.2s;
    cursor: pointer;
  }
  
  .gallery-btn:hover {
    background: rgba(255, 255, 255, 0.25);
    border-color: rgba(255, 255, 255, 0.5);
    transform: translateY(-2px);
    box-shadow: 0 4px 12px rgba(0, 0, 0, 0.3);
  }
  
  .gallery-btn svg {
    flex-shrink: 0;
  }
  
  @media (max-width: 768px) {
    .brand {
      top: 1rem;
      left: 1rem;
    }
    
    .film-title {
      font-size: 2rem;
    }
    
    .film-info {
      left: 1rem;
      right: 1rem;
      bottom: 2rem;
    }
    
    .gallery-btn {
      padding: 0.6rem 1.2rem;
      font-size: 0.9rem;
    }
  }
</style>
