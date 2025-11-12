<!-- src/routes/+page.svelte -->
<script>
  import Sketchbook from '$lib/components/Sketchbook.svelte';
  import StoryView from '$lib/components/StoryView.svelte';
  import EmailSignup from '$lib/components/EmailSignup.svelte';
  import { t } from '$lib/translations';
  
  export let data;
  
  let selectedArtwork = null;
  
  // Log data to console for debugging
  $: console.log('📦 Page data:', data);
  $: console.log('🎨 Artworks:', data?.artworks);
  
  function handleSelectArtwork(event) {
    selectedArtwork = event.detail;
  }
  
  function handleCloseStory() {
    selectedArtwork = null;
  }
  
  // Add placeholder images for artworks that don't have Cloudflare Images IDs yet
  $: displayArtworks = data?.artworks?.map(artwork => ({
    ...artwork,
    thumbnailUrl: artwork.thumbnailUrl || `https://picsum.photos/400/300?random=${artwork.id}`
  })) || [];
  
  $: console.log('🖼️ Display artworks:', displayArtworks);
</script>

<svelte:head>
  <title>{$t('site.title')} - {$t('pages.home.meta.title')}</title>
  <meta name="description" content={$t('pages.home.meta.description')} />
  <link rel="preconnect" href="https://fonts.googleapis.com" />
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin />
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@100;200;300;400;500&display=swap" rel="stylesheet" />
</svelte:head>

{#if selectedArtwork}
  <StoryView 
    artwork={selectedArtwork} 
    on:close={handleCloseStory} 
  />
{:else}
  <!-- Hero Section -->
  <section class="hero-simple">
    <div class="hero-content">
      <h1>{$t('pages.home.hero.title')}</h1>
      <p class="subtitle">{$t('pages.home.hero.subtitle')}</p>
    </div>
  </section>

  <!-- ENHANCED DEBUG SECTION -->
  <div class="debug-panel">
    <h3>🔍 Debug Information</h3>
    
    <div class="debug-row">
      <strong>Data object exists:</strong> 
      <span class:success={data} class:error={!data}>
        {data ? '✅ Yes' : '❌ No'}
      </span>
    </div>
    
    <div class="debug-row">
      <strong>Artworks array exists:</strong>
      <span class:success={data?.artworks} class:error={!data?.artworks}>
        {data?.artworks ? '✅ Yes' : '❌ No'}
      </span>
    </div>
    
    <div class="debug-row">
      <strong>Artworks count:</strong>
      <span class:success={data?.artworks?.length > 0} class:error={data?.artworks?.length === 0}>
        {data?.artworks?.length || 0}
      </span>
    </div>
    
    {#if data?.debug}
      <div class="debug-row">
        <strong>Server debug info:</strong>
        <pre>{JSON.stringify(data.debug, null, 2)}</pre>
      </div>
    {/if}
    
    {#if data?.artworks && data.artworks.length > 0}
      <details class="debug-details">
        <summary>📋 View all artwork data</summary>
        <pre>{JSON.stringify(data.artworks, null, 2)}</pre>
      </details>
    {/if}
    
    <div class="debug-hint">
      💡 Check browser console (F12) for server-side logs
    </div>
  </div>

  <!-- Sketchbook Section -->
  <section id="work" class="sketchbook-section">
    {#if displayArtworks.length > 0}
      <Sketchbook 
        artworks={displayArtworks} 
        on:selectArtwork={handleSelectArtwork}
      />
    {:else}
      <div class="no-data-message">
        <h3>📭 No Published Artworks</h3>
        <p>The query returned 0 artworks.</p>
        
        {#if data?.debug}
          <div class="debug-help">
            <p><strong>Database status:</strong></p>
            <ul>
              <li>Total in DB: {data.debug.totalInDb || '?'}</li>
              <li>Published: {data.debug.publishedCount || '?'}</li>
              <li>Returned: {data.debug.returnedCount || '?'}</li>
            </ul>
          </div>
        {/if}
        
        <details class="help-details">
          <summary>🔧 How to fix this</summary>
          <div class="help-content">
            <p><strong>Option 1: Set existing artworks to published</strong></p>
            <code>
              npx wrangler d1 execute antoine-artworks --remote --command 
              "UPDATE artworks SET published = 1"
            </code>
            
            <p><strong>Option 2: Check what's in your database</strong></p>
            <code>
              npx wrangler d1 execute antoine-artworks --remote --command 
              "SELECT id, title, published FROM artworks"
            </code>
          </div>
        </details>
      </div>
    {/if}
  </section>

  <!-- About Section -->
  <section id="about" class="about-section">
    <div class="container">
      <div class="about-content">
        <h3>{$t('pages.home.about.title')}</h3>
        <p>{$t('pages.home.about.p1')}</p>
        <p>{$t('pages.home.about.p2')}</p>
      </div>
    </div>
  </section>

  <!-- Email Signup Section -->
  <section id="contact" class="signup-section">
    <div class="container">
      <h3>{$t('pages.home.signup.title')}</h3>
      <p>{$t('pages.home.signup.description')}</p>
      <EmailSignup />
    </div>
  </section>
{/if}

<style>
  .hero-simple {
    min-height: 60vh;
    display: flex;
    align-items: center;
    justify-content: center;
    background: linear-gradient(135deg, #f8f7f4 0%, #edebe8 100%);
    padding: 4rem 2rem;
    text-align: center;
  }
  
  .hero-content {
    max-width: 800px;
  }
  
  .hero-content h1 {
    font-family: 'Georgia', serif;
    font-size: 3rem;
    font-weight: 100;
    margin: 0 0 1.5rem;
    letter-spacing: 2px;
    color: #2c5e3d;
    line-height: 1.2;
  }
  
  .subtitle {
    font-size: 1.2rem;
    font-weight: 300;
    color: #4a4a3c;
    font-style: italic;
    margin: 0;
  }
  
  /* Debug Panel */
  .debug-panel {
    max-width: 800px;
    margin: 2rem auto;
    padding: 1.5rem;
    background: #fff3cd;
    border: 2px solid #ffc107;
    border-radius: 8px;
  }
  
  .debug-panel h3 {
    margin: 0 0 1rem;
    font-size: 1.2rem;
    color: #856404;
  }
  
  .debug-row {
    display: flex;
    justify-content: space-between;
    padding: 0.5rem 0;
    border-bottom: 1px solid #ffecb5;
  }
  
  .debug-row:last-of-type {
    border-bottom: none;
  }
  
  .success {
    color: #28a745;
    font-weight: 600;
  }
  
  .error {
    color: #dc3545;
    font-weight: 600;
  }
  
  .debug-details {
    margin-top: 1rem;
    cursor: pointer;
  }
  
  .debug-details pre {
    background: #fff;
    padding: 1rem;
    border-radius: 4px;
    overflow: auto;
    max-height: 300px;
    font-size: 0.85rem;
  }
  
  .debug-hint {
    margin-top: 1rem;
    padding: 0.75rem;
    background: rgba(255, 255, 255, 0.5);
    border-radius: 4px;
    font-size: 0.9rem;
    color: #856404;
  }
  
  .sketchbook-section {
    padding: 4rem 0;
    background: linear-gradient(180deg, #edebe8 0%, #fafafa 100%);
    min-height: 70vh;
  }
  
  .no-data-message {
    max-width: 600px;
    margin: 0 auto;
    text-align: center;
    padding: 3rem 2rem;
    background: white;
    border-radius: 8px;
    box-shadow: 0 2px 8px rgba(0,0,0,0.1);
  }
  
  .no-data-message h3 {
    color: #666;
    margin-bottom: 1rem;
  }
  
  .debug-help {
    margin: 2rem 0;
    padding: 1rem;
    background: #f8f9fa;
    border-radius: 4px;
    text-align: left;
  }
  
  .debug-help ul {
    margin: 0.5rem 0 0 1.5rem;
  }
  
  .help-details {
    margin-top: 2rem;
    text-align: left;
  }
  
  .help-content {
    padding: 1rem;
    background: #f8f9fa;
    border-radius: 4px;
  }
  
  .help-content code {
    display: block;
    margin: 0.5rem 0 1rem;
    padding: 0.75rem;
    background: #2d2d2d;
    color: #f8f8f2;
    border-radius: 4px;
    overflow-x: auto;
    font-size: 0.85rem;
  }
  
  .about-section {
    padding: 4rem 0;
    background: white;
  }
  
  .signup-section {
    padding: 4rem 0;
    background: #f8f9fa;
    text-align: center;
  }
  
  .container {
    max-width: 800px;
    margin: 0 auto;
    padding: 0 1rem;
  }
  
  .about-content {
    max-width: 600px;
    margin: 0 auto;
  }
  
  h3 {
    font-size: 1.75rem;
    font-weight: 200;
    margin-bottom: 2rem;
    text-align: center;
  }
  
  .about-content p {
    font-size: 1rem;
    margin-bottom: 1.5rem;
    color: #555;
  }
  
  .signup-section h3 {
    margin-bottom: 1rem;
  }
  
  .signup-section p {
    margin-bottom: 2rem;
    color: #666;
    font-size: 1rem;
  }
  
  @media (min-width: 768px) {
    .hero-content h1 {
      font-size: 4rem;
    }
    
    .subtitle {
      font-size: 1.4rem;
    }
    
    .container {
      padding: 0 2rem;
    }
    
    h3 {
      font-size: 2.5rem;
    }
    
    .about-content p {
      font-size: 1.1rem;
    }
    
    .signup-section p {
      font-size: 1.1rem;
    }
  }
  
  @media (max-width: 768px) {
    .hero-simple {
      min-height: 50vh;
      padding: 3rem 1rem;
    }
    
    .hero-content h1 {
      font-size: 2rem;
    }
    
    .subtitle {
      font-size: 1rem;
    }
    
    .sketchbook-section {
      padding: 2rem 0;
    }
  }
</style>
