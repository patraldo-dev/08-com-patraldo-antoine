<!-- src/routes/tools/palettes/+page.svelte -->
<script>
  import { t } from '$lib/i18n';
  import ColorPalette from '$lib/components/ColorPalette.svelte';
  let { data } = $props();
</script>

<svelte:head>
  <title>{$t('pages.home.metaTitle')} - {$t('pages.tools.palettes.title')}</title>
  <meta name="description" content={$t('pages.tools.palettes.metaDescription')} />
</svelte:head>

<div class="palettes-page">
  <header class="page-header">
    <a href="/tools" class="back-link">← {$t('pages.tools.palettesbacktotools')}</a>
    <h1>{$t('pages.tools.palettes.heading')}</h1>
    <p class="subtitle">{$t('pages.tools.palettes.subtitle')}</p>
  </header>

  <div class="content">
    <!-- Artist's Note -->
    <div class="artist-note">
      <div class="quote-mark">"</div>
      <p class="note-text">
        {$t('pages.tools.palettes.artistNote')}
      </p>
      <p class="signature">{$t('pages.tools.palettes.signature')}</p>
    </div>

    <!-- How It Works -->
    <div class="info-section">
      <h2>{$t('pages.tools.palettes.processTitle')}</h2>
      <div class="process-steps">
        <div class="step">
          <div class="step-number">1</div>
          <div class="step-content">
            <h3>{$t('pages.tools.palettes.step1Title')}</h3>
            <p>{$t('pages.tools.palettes.step1Description')}</p>
          </div>
        </div>
        
        <div class="step">
          <div class="step-number">2</div>
          <div class="step-content">
            <h3>{$t('pages.tools.palettes.step2Title')}</h3>
            <p>{$t('pages.tools.palettes.step2Description')}</p>
          </div>
        </div>
        
        <div class="step">
          <div class="step-number">3</div>
          <div class="step-content">
            <h3>{$t('pages.tools.palettes.step3Title')}</h3>
            <p>{$t('pages.tools.palettes.step3Description')}</p>
          </div>
        </div>
      </div>
    </div>

    <!-- Featured Palettes -->
    <section class="featured-palettes">
      <h2>{$t('pages.tools.palettes.recentTitle')}</h2>
      <p class="section-description">
        {$t('pages.tools.palettes.recentDescription')}
      </p>
      
      <div class="palettes-grid">
        {#each data.artworks.slice(0, 10) as artwork}
          <a href="/#artwork-{artwork.id}" class="palette-card" title={$t('pages.tools.palettes.cardTitle')}>
            <div class="palette-visual">
              <ColorPalette 
                imageUrl={artwork.thumbnailUrl}
                artworkTitle={artwork.display_name || artwork.title}
                preview={true}
              />
            </div>
            
            <div class="palette-info">
              <div class="artwork-hint">
                {#if artwork.year}
                  <span class="year">{artwork.year}</span>
                  <span class="separator">·</span>
                {/if}
                <span class="type-badge">
                  {#if artwork.type === 'still'}📷
                  {:else if artwork.type === 'animation'}🎬
                  {:else if artwork.type === 'gif'}🎭
                  {/if}
                </span>
              </div>
              <span class="discovery-hint">{$t('pages.tools.palettes.viewArtwork')}</span>
            </div>
          </a>
        {/each}
      </div>
    </section>

    <!-- Call to Action -->
    <div class="cta">
      <h2>{$t('pages.tools.palettes.ctaHeading')}</h2>
      <p>{$t('pages.tools.palettes.ctaDescription')}</p>
      <a href="/" class="button">{$t('pages.tools.palettes.ctaButton')}</a>
    </div>
  </div>
</div>

<style>
  .palettes-page {
    min-height: 100vh;
    background: linear-gradient(180deg, var(--color-surface) 0%, var(--color-surface-raised) 100%);
    padding: 6rem 2rem 4rem;
  }

  .page-header {
    max-width: 800px;
    margin: 0 auto 4rem;
    text-align: center;
  }

  .back-link {
    display: inline-block;
    color: var(--color-text-muted);
    text-decoration: none;
    margin-bottom: 2rem;
    transition: color 0.2s ease;
    font-size: 0.95rem;
  }

  .back-link:hover {
    color: var(--color-text);
  }

  .page-header h1 {
    font-size: clamp(2rem, 5vw, 2.75rem);
    font-weight: 600;
    color: var(--color-text);
    margin: 0 0 1rem 0;
    line-height: 1.2;
  }

  .subtitle {
    font-size: 1.125rem;
    color: var(--color-text-muted);
    line-height: 1.6;
    max-width: 600px;
    margin: 0 auto;
  }

  .content {
    max-width: 1200px;
    margin: 0 auto;
  }

  /* Artist's Note */
  .artist-note {
    background: linear-gradient(135deg, var(--color-surface) 0%, var(--color-surface-raised) 100%);
    border-left: 4px solid var(--color-text);
    border-radius: 12px;
    padding: 2.5rem;
    margin-bottom: 4rem;
    position: relative;
    box-shadow: 0 4px 12px rgba(0, 0, 0, 0.05);
  }

  .quote-mark {
    position: absolute;
    top: -10px;
    left: 20px;
    font-size: 4rem;
    color: var(--color-border);
    font-family: Georgia, serif;
    line-height: 1;
  }

  .note-text {
    font-size: 1.125rem;
    color: var(--color-text-dim);
    line-height: 1.7;
    margin: 0 0 1rem 0;
    font-style: italic;
  }

  .signature {
    text-align: right;
    color: var(--color-text-muted);
    font-size: 1rem;
    margin: 0;
  }

  /* Process Steps */
  .info-section {
    margin-bottom: 4rem;
  }

  .info-section h2 {
    font-size: 2rem;
    font-weight: 600;
    color: var(--color-text);
    margin: 0 0 2rem 0;
    text-align: center;
  }

  .process-steps {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
    gap: 2rem;
  }

  .step {
    display: flex;
    gap: 1rem;
    background: var(--color-surface-raised);
    border: 2px solid var(--color-border);
    border-radius: 12px;
    padding: 1.5rem;
    transition: all 0.3s ease;
  }

  .step:hover {
    border-color: var(--color-text);
    transform: translateY(-4px);
    box-shadow: 0 8px 24px rgba(0, 0, 0, 0.1);
  }

  .step-number {
    flex-shrink: 0;
    width: 40px;
    height: 40px;
    background: var(--color-text);
    color: var(--color-surface-raised);
    border-radius: 50%;
    display: flex;
    align-items: center;
    justify-content: center;
    font-weight: 600;
    font-size: 1.125rem;
  }

  .step-content h3 {
    font-size: 1.125rem;
    font-weight: 600;
    color: var(--color-text);
    margin: 0 0 0.5rem 0;
  }

  .step-content p {
    font-size: 0.95rem;
    color: var(--color-text-muted);
    line-height: 1.6;
    margin: 0;
  }

  /* Featured Palettes */
  .featured-palettes {
    margin-bottom: 4rem;
  }

  .featured-palettes h2 {
    font-size: 2rem;
    font-weight: 600;
    color: var(--color-text);
    margin: 0 0 1rem 0;
    text-align: center;
  }

  .section-description {
    text-align: center;
    color: var(--color-text-muted);
    font-size: 1.125rem;
    line-height: 1.6;
    margin: 0 0 3rem 0;
    max-width: 600px;
    margin-left: auto;
    margin-right: auto;
  }

  .palettes-grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(320px, 1fr));
    gap: 2rem;
  }

  .palette-card {
    display: block;
    background: var(--color-surface-raised);
    border-radius: 16px;
    padding: 2rem;
    text-decoration: none;
    color: inherit;
    transition: all 0.3s ease;
    border: 2px solid var(--color-border);
    box-shadow: 0 4px 12px rgba(0, 0, 0, 0.05);
  }

  .palette-card:hover {
    transform: translateY(-8px);
    box-shadow: 0 20px 40px rgba(0, 0, 0, 0.15);
    border-color: var(--color-text);
  }

  .palette-visual {
    margin-bottom: 1.5rem;
  }

  .palette-info {
    text-align: center;
  }

  .artwork-hint {
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 0.5rem;
    margin-bottom: 0.75rem;
    font-size: 0.875rem;
    color: var(--color-text-muted);
  }

  .year {
    font-weight: 500;
  }

  .separator {
    opacity: 0.5;
  }

  .type-badge {
    font-size: 1rem;
  }

  .discovery-hint {
    display: block;
    font-size: 0.9rem;
    color: var(--color-text-muted);
    font-weight: 500;
    opacity: 0.7;
    transition: all 0.2s ease;
  }

  .palette-card:hover .discovery-hint {
    opacity: 1;
    color: var(--color-text);
  }

  /* Call to Action */
  .cta {
    text-align: center;
    padding: 3rem 2rem;
    background: linear-gradient(135deg, var(--color-text) 0%, var(--color-text-dim) 100%);
    border-radius: 16px;
    color: white;
  }

  .cta h2 {
    font-size: 1.75rem;
    font-weight: 600;
    margin: 0 0 1rem 0;
  }

  .cta p {
    font-size: 1.125rem;
    opacity: 0.9;
    margin: 0 0 2rem 0;
    max-width: 600px;
    margin-left: auto;
    margin-right: auto;
  }

  .button {
    display: inline-block;
    padding: 1rem 2.5rem;
    background: var(--color-surface-raised);
    color: var(--color-text);
    text-decoration: none;
    border-radius: 8px;
    font-weight: 600;
    transition: all 0.2s ease;
  }

  .button:hover {
    background: var(--color-surface);
    transform: translateY(-2px);
    box-shadow: 0 8px 24px rgba(255, 255, 255, 0.2);
  }

  /* Responsive */
  @media (max-width: 768px) {
    .palettes-page {
      padding: 4rem 1.5rem 3rem;
    }

    .artist-note {
      padding: 2rem 1.5rem;
    }

    .note-text {
      font-size: 1rem;
    }

    .process-steps {
      grid-template-columns: 1fr;
    }

    .palettes-grid {
      grid-template-columns: 1fr;
      gap: 1.5rem;
    }

    .palette-card {
      padding: 1.5rem;
    }

    .cta {
      padding: 2rem 1.5rem;
    }

    .cta h2 {
      font-size: 1.5rem;
    }

    .cta p {
      font-size: 1rem;
    }
  }
</style>
