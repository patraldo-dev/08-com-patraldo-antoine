<!-- src/routes/+page.svelte -->
<script>
  import Sketchbook from '$lib/components/Sketchbook.svelte';
  import StoryView from '$lib/components/StoryView.svelte';
  import EmailSignup from '$lib/components/EmailSignup.svelte';
  import { t, locale } from '$lib/translations';
  import { page } from '$app/stores'; // Import page store

  export let data;

  let selectedArtwork = null;

  function handleSelectArtwork(event) {
    selectedArtwork = event.detail;
  }

  function handleCloseStory() {
    selectedArtwork = null;
  }


// Title handling
  $: siteTitle = $t('site.title');
  $: pageMetaTitle = $t('pages.home.meta.title');
  $: fullTitle = (siteTitle && siteTitle !== 'site.title')
    ? (pageMetaTitle && pageMetaTitle !== 'pages.home.meta.title' 
        ? `${siteTitle} - ${pageMetaTitle}` 
        : siteTitle)
    : 'Antoine Patraldo';


</script>

<svelte:head>
  <title>{fullTitle}</title>
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

  <!-- Sketchbook Section -->
  <section id="work" class="sketchbook-section">
    {#if displayArtworks.length > 0}
      <Sketchbook
        artworks={displayArtworks}
        on:selectArtwork={handleSelectArtwork}
      />
    {:else}
      <div class="no-data-message">
        <h3>📭 No Artworks Yet</h3>
        <p>Add some artworks to your database to see the sketchbook!</p>
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
