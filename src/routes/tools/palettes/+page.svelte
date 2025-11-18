<!-- src/routes/tools/palettes/+page.svelte -->
<script>
  import { t } from '$lib/translations';
</script>

<svelte:head>
  <title>{$t('tools.palettes.pageTitle')} - Antoine Patraldo</title>
</svelte:head>

<div class="palettes-page">
  <header class="page-header">
    <a href="/tools" class="back-link">← {$t('tools.backToTools')}</a>
    <h1>{$t('tools.palettes.pageTitle')}</h1>
    <p class="subtitle">{$t('tools.palettes.pageDescription')}</p>
  </header>

  <div class="content">
    <div class="info-box">
      <h2>{$t('tools.palettes.howToTitle')}</h2>
      <ol>
        <li>{$t('tools.palettes.step1')}</li>
        <li>{$t('tools.palettes.step2')}</li>
        <li>{$t('tools.palettes.step3')}</li>
      </ol>
    </div>

    <div class="cta">
      <p>{$t('tools.palettes.explorePrompt')}</p>
      <a href="/" class="button">{$t('tools.palettes.browseArtworks')}</a>
    </div>
  </div>
</div>

<style>
  .palettes-page {
    min-height: 100vh;
    background: linear-gradient(180deg, #fafafa 0%, #ffffff 100%);
    padding: 6rem 2rem 4rem;
  }

  .page-header {
    max-width: 800px;
    margin: 0 auto 3rem;
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
  }

  .content {
    max-width: 800px;
    margin: 0 auto;
  }

  .info-box {
    background: white;
    border: 2px solid #e0e0e0;
    border-radius: 12px;
    padding: 2rem;
    margin-bottom: 2rem;
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
  }
</style>
