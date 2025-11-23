<!-- src/routes/tools/palettes/+page.svelte -->
<script>
  import { t } from '$lib/i18n';
  import ColorPalette from '$lib/components/ColorPalette.svelte';

  let { data } = $props();
</script>

<svelte:head>
  <title>{$t('pages.home.metaTitle')} - {$t('common.navTools')}</title>
  <meta name="description" content={$t('pages.tools.metaDescription')} />
</svelte:head>

<div class="palettes-page">
  <header class="page-header">
    <a href="/tools" class="back-link">← {$t('pages.tools.palettesBackToTools')}</a>
    <h1>{$t('pages.tools.palettesPageTitle')}</h1>
    <p class="subtitle">{$t('pages.tools.palettesPageDescription')}</p>
  </header>

  <div class="content">
    <div class="info-box">
      <h2>{$t('pages.tools.palettesHowToTitle')}</h2>
      <ol>
        <li>{$t('pages.tools.palettesStep1')}</li>
        <li>{$t('pages.tools.palettesStep2')}</li>
        <li>{$t('pages.tools.palettesStep3')}</li>
      </ol>
    </div>

    <!-- Featured Palettes - REVAMPED -->
    <section class="featured-palettes">
      <h2>{$t('pages.tools.palettesFeatured')}</h2>
      <p class="section-description">{$t('pages.tools.palettesFeaturedDescription')}</p>
      
      <div class="palettes-grid">
        {#each data.artworks.slice(0, 10) as artwork}
          <a href="/#artwork-{artwork.id}" class="palette-card" title="Click to discover the source artwork">
            <!-- Color Palette Only - No Artwork Info -->
            <div class="palette-visual">
              <ColorPalette 
                imageUrl={artwork.thumbnailUrl}
                artworkTitle={artwork.display_name || artwork.title}
                preview={true}
              />
            </div>
            
            <!-- Minimal Info - Keep it Mysterious -->
            <div class="palette-info">
              <span class="discovery-hint">{$t('pages.tools.palettesClickToReveal')}</span>
            </div>
          </a>
        {/each}
      </div>
    </section>

    <div class="cta">
      <p>{$t('pages.tools.palettesExplorePrompt')}</p>
      <a href="/" class="button">{$t('pages.tools.palettesBrowseArtworks')}</a>
    </div>
  </div>
</div>

<style>
  /* ... keep all your existing styles ... */
  .palettes-page {
    min-height: 100vh;
    background: linear-gradient(180deg, #fafafa 0%, #ffffff 100%);
    padding: 6rem 2rem 4rem;
  }

  .page-header {
    max-width: 800px;
    margin: 0 auto 3rem;
    text-align: center;
  }

  .back-link {
    display: inline-block;
    color: #666;
    text-decoration: none;
    margin-bottom: 2rem;
    transition: color 0.2s ease;
  }

  .back-link:hover {
    color: #1a1a1a;
  }

  .page-header h1 {
    font-size: 2.5rem;
    font-weight: 600;
    color: #1a1a1a;
    margin: 0 0 1rem 0;
  }

  .subtitle {
    font-size: 1.125rem;
    color: #666;
    line-height: 1.6;
    max-width: 600px;
    margin: 0 auto;
  }

  .content {
    max-width: 1200px;
    margin: 0 auto;
  }

  .info-box {
    background: white;
    border: 2px solid #e0e0e0;
    border-radius: 12px;
    padding: 2rem;
    margin-bottom: 3rem;
  }

  .info-box h2 {
    font-size: 1.5rem;
    font-weight: 600;
    color: #1a1a1a;
    margin: 0 0 1.5rem 0;
  }

  .info-box ol {
    margin: 0;
    padding-left: 1.5rem;
    color: #666;
    line-height: 1.8;
  }

  .info-box li {
    margin-bottom: 0.75rem;
  }

  .featured-palettes {
    margin-bottom: 4rem;
  }

  .featured-palettes h2 {
    font-size: 2rem;
    font-weight: 600;
    color: #1a1a1a;
    margin: 0 0 1rem 0;
    text-align: center;
  }

  .section-description {
    text-align: center;
    color: #666;
    font-size: 1.125rem;
    margin: 0 0 3rem 0;
    max-width: 600px;
    margin-left: auto;
    margin-right: auto;
  }

  .palettes-grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(320px, 1fr));
    gap: 2rem;
    margin-top: 2rem;
  }

  .palette-card {
    display: block;
    background: white;
    border-radius: 16px;
    padding: 2rem;
    text-decoration: none;
    color: inherit;
    transition: all 0.3s ease;
    border: 2px solid #e0e0e0;
    box-shadow: 0 4px 12px rgba(0, 0, 0, 0.05);
  }

  .palette-card:hover {
    transform: translateY(-8px);
    box-shadow: 0 20px 40px rgba(0, 0, 0, 0.15);
    border-color: #1a1a1a;
  }

  .palette-visual {
    margin-bottom: 1.5rem;
  }

  .palette-info {
    text-align: center;
  }

  .discovery-hint {
    font-size: 0.9rem;
    color: #666;
    font-style: italic;
    opacity: 0.8;
    transition: opacity 0.2s ease;
  }

  .palette-card:hover .discovery-hint {
    opacity: 1;
  }

  .cta {
    text-align: center;
    padding: 3rem 2rem;
    background: white;
    border: 2px solid #e0e0e0;
    border-radius: 12px;
  }

  .cta p {
    font-size: 1.125rem;
    color: #666;
    margin: 0 0 1.5rem 0;
  }

  .button {
    display: inline-block;
    padding: 1rem 2.5rem;
    background: #1a1a1a;
    color: white;
    text-decoration: none;
    border-radius: 8px;
    font-weight: 600;
    transition: all 0.2s ease;
  }

  .button:hover {
    background: #333;
    transform: translateY(-2px);
  }

  @media (max-width: 768px) {
    .palettes-page {
      padding: 4rem 1.5rem 3rem;
    }

    .page-header h1 {
      font-size: 2rem;
    }

    .palettes-grid {
      grid-template-columns: 1fr;
      gap: 1.5rem;
    }

    .palette-card {
      padding: 1.5rem;
    }
  }
</style>
