<!-- src/routes/tools/+page.svelte -->
<script>
  import { t } from '$lib/translations';

<script>
  onMount(() => {
    console.log('Tools translation structure:', {
      directTitle: $t('pages.tools.title'),
      metaTitle: $t('pages.tools.metaTitle'), 
      subtitle: $t('pages.tools.subtitle')
    });
  });

</script>

<svelte:head>
  <title>{$t('pages.home.metaTitle')} - {$t('common.navTools')}</title>
  <meta name="description" content={$t('pages.tools.metaDescription')} />
</svelte:head>

<div class="tools-page">
  <header class="tools-header">
    <h1>{$t('pages.tools.title')}</h1>
    <p class="subtitle">{$t('pages.tools.subtitle')}</p>
  </header>

  <div class="tools-grid">
    <!-- Color Palettes - LIVE -->
    <a href="/tools/palettes" class="tool-card available">
      <div class="tool-icon">🎨</div>
      <h3>{$t('pages.tools.palettesTitle')}</h3>
      <p>{$t('pages.tools.palettesDescription')}</p>
      <span class="status-badge live">{$t('pages.tools.statusAvailable')}</span>
    </a>

    <!-- Wallpapers - Coming Soon -->
    <div class="tool-card coming-soon">
      <div class="tool-icon">🖼️</div>
      <h3>{$t('pages.tools.wallpapersTitle')}</h3>
      <p>{$t('pages.tools.wallpapersDescription')}</p>
      <span class="status-badge">{$t('pages.tools.statusComingSoon')}</span>
    </div>

    <!-- Avatar Creator - Coming Soon -->
    <div class="tool-card coming-soon">
      <div class="tool-icon">👤</div>
      <h3>{$t('pages.tools.avatarCreatorTitle')}</h3>
      <p>{$t('pages.tools.avatarCreatorDescription')}</p>
      <span class="status-badge">{$t('pages.tools.statusComingSoon')}</span>
    </div>

    <!-- Stickers - Coming Soon -->
    <div class="tool-card coming-soon">
      <div class="tool-icon">✨</div>
      <h3>{$t('pages.tools.stickersTitle')}</h3>
      <p>{$t('pages.tools.stickersDescription')}</p>
      <span class="status-badge">{$t('pages.tools.statusComingSoon')}</span>
    </div>

    <!-- AR Try-On - Coming Soon -->
    <div class="tool-card coming-soon">
      <div class="tool-icon">📱</div>
      <h3>{$t('pages.tools.arTryOnTitle')}</h3>
      <p>{$t('pages.tools.arTryOnDescription')}</p>
      <span class="status-badge">{$t('pages.tools.statusComingSoon')}</span>
    </div>

    <!-- NFTs - Future -->
    <div class="tool-card future">
      <div class="tool-icon">🔗</div>
      <h3>{$t('pages.tools.nftsTitle')}</h3>
      <p>{$t('pages.tools.nftsDescription')}</p>
      <span class="status-badge">{$t('pages.tools.statusFuture')}</span>
    </div>
  </div>

  <!-- Call to Action -->
  <section class="tools-cta">
    <h2>{$t('pages.tools.ctaTitle')}</h2>
    <p>{$t('pages.tools.ctaDescription')}</p>
    <a href="/#contact" class="cta-button">{$t('pages.tools.ctaButton')}</a>
  </section>
</div>

<style>
  .tools-page {
    min-height: 100vh;
    background: linear-gradient(180deg, #fafafa 0%, #ffffff 100%);
    padding: 6rem 2rem 4rem;
  }

  .tools-header {
    max-width: 800px;
    margin: 0 auto 4rem;
    text-align: center;
  }

  .tools-header h1 {
    font-size: 3rem;
    font-weight: 600;
    color: #1a1a1a;
    margin: 0 0 1rem 0;
    letter-spacing: -0.02em;
  }

  .subtitle {
    font-size: 1.25rem;
    color: #666;
    line-height: 1.6;
    margin: 0;
  }

  .tools-grid {
    max-width: 1200px;
    margin: 0 auto 4rem;
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(320px, 1fr));
    gap: 2rem;
  }

  .tool-card {
    background: white;
    border: 2px solid #e0e0e0;
    border-radius: 16px;
    padding: 2.5rem;
    text-decoration: none;
    color: inherit;
    transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
    position: relative;
    display: flex;
    flex-direction: column;
    align-items: center;
    text-align: center;
  }

  .tool-card.available {
    cursor: pointer;
    border-color: #1a1a1a;
  }

  .tool-card.available:hover {
    transform: translateY(-8px);
    box-shadow: 0 16px 32px rgba(0, 0, 0, 0.15);
    border-color: #000;
  }

  .tool-card.coming-soon {
    opacity: 0.7;
    border-style: dashed;
  }

  .tool-card.future {
    opacity: 0.5;
    border-style: dotted;
  }

  .tool-icon {
    font-size: 4rem;
    margin-bottom: 1.5rem;
    filter: grayscale(0);
    transition: filter 0.3s ease;
  }

  .tool-card.coming-soon .tool-icon,
  .tool-card.future .tool-icon {
    filter: grayscale(1);
  }

  .tool-card.available:hover .tool-icon {
    transform: scale(1.1);
  }

  .tool-card h3 {
    font-size: 1.5rem;
    font-weight: 600;
    color: #1a1a1a;
    margin: 0 0 1rem 0;
  }

  .tool-card p {
    font-size: 1rem;
    color: #666;
    line-height: 1.6;
    margin: 0 0 1.5rem 0;
    flex: 1;
  }

  .status-badge {
    display: inline-block;
    padding: 0.5rem 1rem;
    background: #f0f0f0;
    color: #666;
    border-radius: 20px;
    font-size: 0.875rem;
    font-weight: 600;
    text-transform: uppercase;
    letter-spacing: 0.5px;
  }

  .status-badge.live {
    background: #1a1a1a;
    color: white;
  }

  .tools-cta {
    max-width: 700px;
    margin: 0 auto;
    text-align: center;
    padding: 3rem 2rem;
    background: white;
    border-radius: 16px;
    border: 2px solid #e0e0e0;
  }

  .tools-cta h2 {
    font-size: 2rem;
    font-weight: 600;
    color: #1a1a1a;
    margin: 0 0 1rem 0;
  }

  .tools-cta p {
    font-size: 1.125rem;
    color: #666;
    line-height: 1.6;
    margin: 0 0 2rem 0;
  }

  .cta-button {
    display: inline-block;
    padding: 1rem 2.5rem;
    background: #1a1a1a;
    color: white;
    text-decoration: none;
    border-radius: 8px;
    font-weight: 600;
    font-size: 1rem;
    transition: all 0.2s ease;
  }

  .cta-button:hover {
    background: #333;
    transform: translateY(-2px);
    box-shadow: 0 8px 16px rgba(0, 0, 0, 0.2);
  }

  @media (max-width: 768px) {
    .tools-page {
      padding: 4rem 1.5rem 3rem;
    }

    .tools-header h1 {
      font-size: 2rem;
    }

    .subtitle {
      font-size: 1.125rem;
    }

    .tools-grid {
      grid-template-columns: 1fr;
      gap: 1.5rem;
    }

    .tool-card {
      padding: 2rem;
    }

    .tool-icon {
      font-size: 3rem;
    }
  }
</style>
