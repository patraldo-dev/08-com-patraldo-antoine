<script>
  import { t } from '$lib/i18n';
  
  /**
   * @typedef {Object} Film
   * @property {string} title
   * @property {string} description
   * @property {number} duration
   * @property {number} view_count
   */
  
  /**
   * @typedef {Object} Props
   * @property {Film} film
   */
  
  /** @type {Props} */
  let { film } = $props();
  
  /**
   * @param {number} seconds
   * @returns {string}
   */
  function formatDuration(seconds) {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins}:${secs.toString().padStart(2, '0')}`;
  }
  
  /**
   * @param {number} count
   * @returns {string}
   */
  function formatViews(count) {
    if (count === 0) return $t('canal.hero.noViews');
    if (count === 1) return `1 ${$t('canal.hero.view')}`;
    return `${count} ${$t('canal.hero.views')}`;
  }
</script>

<div class="hero-overlay">
  <div class="brand">
    <a href="/" class="home-link">← {$t('canal.nav.home')}</a>
    <h1 class="channel-name">{$t('canal.hero.channelName')}</h1>
  </div>
  
  <div class="film-info">
    <h2 class="film-title">{film.title}</h2>
    <p class="film-description">{film.description}</p>
    <div class="metadata">
      <span class="duration">
        {$t('canal.hero.duration')}: {formatDuration(film.duration)}
      </span>
      <span class="views">
        {formatViews(film.view_count)}
      </span>
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
  }
  
  .duration, .views {
    color: #aaa;
    font-size: 0.9rem;
    text-shadow: 0 1px 4px rgba(0, 0, 0, 0.8);
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
  }
</style>
