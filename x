<!-- src/routes/tools/palettes/+page.svelte -->
<script>
  import { t } from '$lib/translations';
  import ColorPalette from '$lib/components/ColorPalette.svelte';
  
  let { data } = $props();
</script>

<svelte:head>
  <title>{$t('pages.tools.palettesPageTitle')} - Antoine Patraldo</title>
</svelte:head>

<div class="palettes-page">
  <header class="page-header">
    <a href="/tools" class="back-link">← {$t('pages.tools.palettesBackToTools')}</a>
    <h1>{$t('pages.tools.palettesPageTitle')}</h1>
    <p class="subtitle">{$t('pages.tools.palettesPageDescription')}</p>
  </header>

  <div class="content">
    <!-- Info Box -->
    <div class="info-box">
      <h2>{$t('pages.tools.palettesHowToTitle')}</h2>
      <ul>
        <li>{$t('pages.tools.palettesStep1')}</li>
        <li>{$t('pages.tools.palettesStep2')}</li>
        <li>{$t('pages.tools.palettesStep3')}</li>
      </ul>
    </div>

    <!-- Featured Palettes -->
    <section class="featured-palettes">
      <h2>{$t('pages.tools.palettesFeatured')}</h2>
      <p class="section-description">{$$t('pages.tools.palettesFeaturedDescription')}</p>
      
      <div class="palettes-grid">
        {#each data.artworks.slice(0, 10) as artwork}
          <a href="/#artwork-{artwork.id}" class="palette-card">
            <div class="artwork-preview">
              <img 
                src={artwork.thumbnailUrl} 
                alt={artwork.display_name || artwork.title}
                loading="lazy"
              />
            </div>
            
            <div class="palette-info">
              <h3>{artwork.display_name || artwork.title}</h3>
              {#if artwork.year}
                <span class="year">{artwork.year}</span>
              {/if}
            </div>
            
            <div class="palette-preview">
              <ColorPalette 
                imageUrl={artwork.thumbnailUrl}
                artworkTitle={artwork.display_name || artwork.title}
                compact={true}
              />
            </div>
          </a>
        {/each}
      </div>
    </section>

    <!-- CTA to explore more -->
    <div class="cta">
      <p>{$t('pages.tools.palettesExplorePrompt')}</p>
      <a href="/" class="button">{$t('pages.tools.palettesBrowseArtworks')}</a>
    </div>
  </div>
</div>

<style>
  /* ... keep all your existing CSS styles exactly as they are ... */
</style>
