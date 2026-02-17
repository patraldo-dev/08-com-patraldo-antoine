<script>
  import Sketchbook from '$lib/components/Sketchbook.svelte';
  import StoryView from '$lib/components/StoryView.svelte';
  import EmailSignup from '$lib/components/EmailSignup.svelte';
  import Artwork3DShowcase from '$lib/components/Artwork3DShowcase.svelte';
  import { t, locale } from '$lib/i18n';
  import { page } from '$app/stores';
  import { goto } from '$app/navigation';
  import { onMount } from 'svelte';
  import { trackVisit } from '$lib/utils/visitTracker.js';
  import AboutDetailModal from '$lib/components/AboutDetailModal.svelte';
  import { browser } from '$app/environment';
  import { onNavigate } from '$app/navigation';

  const { data } = $props();

  let selectedArtwork = $state(null);
  let showAboutDetail = $state(false);
  let dailyVideo = $state(null); // ← ADD THIS LINE

$effect(() => {
  if (browser) {
    const updateModalState = () => {
      showAboutDetail = window.location.hash === '#about-detail';
    };
    
    updateModalState(); // Initial check
    
    const handleHashChange = () => {
      updateModalState();
    };
    
    window.addEventListener('hashchange', handleHashChange);
    return () => window.removeEventListener('hashchange', handleHashChange);
  }
});


$effect(() => {
  if (data.videos.length > 0 && !dailyVideo) {
    // Hourly rotation: seed random with current hour (0-23)
    const now = new Date();
    const hour = now.getHours();
    const seed = hour / 24; // 0 to 1
    const videoIndex = Math.floor(seed * data.videos.length);
    dailyVideo = data.videos[videoIndex];

    // Set up hourly reset (at the top of next hour)
    const nextHour = new Date(now);
    nextHour.setHours(nextHour.getHours() + 1);
    nextHour.setMinutes(0, 0, 0); // Top of next hour

    const msUntilNextHour = nextHour - now;

    const hourTimeout = setTimeout(() => {
      dailyVideo = null; // This will trigger re-selection
      console.log('Top of hour - rotating video');
    }, msUntilNextHour);

    return () => clearTimeout(hourTimeout);
  }
});

// Watch for hash changes to open specific artworks
$effect(() => {
  const hash = $page.url.hash;
  if (hash && hash.startsWith('#artwork-')) {
    const artworkId = hash.replace('#artwork-', '');
    const artwork = data.artworks.find(a => a.id == artworkId);
    if (artwork) {
      selectedArtwork = artwork;
      
      trackVisit(artwork.id, {
        display_name: artwork.display_name || artwork.title,
        title: artwork.title
      });
    }
  }
});

    // Also handle initial page load with hash
  onMount(() => {
    const hash = window.location.hash;
    if (hash && hash.startsWith('#artwork-')) {
      const artworkId = hash.replace('#artwork-', '');
      const artwork = data.artworks.find(a => a.id == artworkId);
      if (artwork) {
        selectedArtwork = artwork;
      }
    }
  });

  function openAboutDetail() {
    window.location.hash = '#about-detail';
  }

  function closeAboutDetail() {
    showAboutDetail = false;  // Add this to actually close the modal
    window.location.hash = '';
  }

  function handleSelectArtwork(event) {
    selectedArtwork = event.detail;
  }

  function handleCloseStory() {
    selectedArtwork = null;
    // Clear the hash when closing so back button works correctly
    history.replaceState(null, '', window.location.pathname);
  }

</script>

{#if showAboutDetail}
  <AboutDetailModal 
    open={showAboutDetail} 
    onClose={closeAboutDetail}
    dailyVideo={dailyVideo}
  />
{/if}

<svelte:head>
  <title>{$t('pages.home.metaTitle')}</title>
  <meta name="description" content={$t('pages.home.metaDescription')} />
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
      <h1>{$t('pages.home.heroTitle')}</h1>
      <p class="subtitle">{$t('pages.home.heroSubtitle')}</p>
    </div>
  </section>

  <!-- About Section - Video Only -->
  <section id="about" class="about-section">
    <div class="about-video-full">
      <div class="video-wrapper" onclick={openAboutDetail} role="button" tabindex="0">
        {#if dailyVideo}
          <iframe
            src="https://customer-9kroafxwku5qm6fx.cloudflarestream.com/{dailyVideo.video_id}/iframe?muted=true&loop=true&autoplay=true&controls=false"
            allow="accelerometer; gyroscope; autoplay; encrypted-media; picture-in-picture"
            allowfullscreen
            loading="lazy"
            title={dailyVideo.title || "Featured Video"}
          ></iframe>
        {:else}
          <iframe
            src="https://customer-9kroafxwku5qm6fx.cloudflarestream.com/fd7341d70b1a5517bb56a569d2a0cb38/iframe?muted=true&loop=true&autoplay=true&controls=false"
            allow="accelerometer; gyroscope; autoplay; encrypted-media; picture-in-picture"
            allowfullscreen
            loading="lazy"
            title="About Antoine - Creative Journey"
          ></iframe>
        {/if}
        <div class="click-overlay"></div>
        <div class="video-overlay">
          <span>{$t('pages.home.clickToLearnMore')}</span>
        </div>
      </div>
    </div>
  </section>

  <!-- 3D Showcase Section -->
  {#if data?.artworks?.length > 0}
    <section class="showcase-label-section">
      <div class="showcase-label">
        <h2>{$t('pages.home.explore3D')}</h2>
      </div>
      <Artwork3DShowcase artworks={data.artworks} />
    </section>
  {/if}

  <!-- Sketchbook Section -->
  <section id="work" class="sketchbook-section">
    <div class="section-label">
      <h2>{$t('pages.home.sketchbook')}</h2>
    </div>
    {#if data?.artworks?.length > 0}
      <Sketchbook
        artworks={data.artworks}
        on:selectArtwork={handleSelectArtwork}
      />
    {:else}
      <div class="no-data-message">
        <h3>📭 No Artworks Yet</h3>
        <p>Add some artworks to your database to see the sketchbook!</p>
      </div>
    {/if}
  </section>
{/if}


  <!-- Email Signup Section -->
  <section id="contact" class="signup-section">
    <div class="container">
      <h3>{$t('pages.home.signupTitle')}</h3>
      <p>{$t('pages.home.signupDescription')}</p>
      <EmailSignup />
    </div>
  </section>

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
    margin: 0 0 0.5rem;
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

  /* Section Labels */
  .showcase-label-section {
    padding: 0 2rem 2rem;
    background: linear-gradient(180deg, #fafafa 0%, #f5f5f5 100%);
  }

  .showcase-label,
  .section-label {
    text-align: center;
    margin-bottom: 1rem;
  }

  .showcase-label h2,
  .section-label h2 {
    font-family: 'Georgia', serif;
    font-size: 2rem;
    font-weight: 300;
    color: #2c5e3d;
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
  
  /* About Section - Video Full Width */
  .about-section {
    padding: 2rem 2rem;
    background: linear-gradient(180deg, #fafafa 0%, #f5f5f5 100%);
  }

  .about-video-full {
    max-width: 900px;
    margin: 0 auto;
  }

  .video-wrapper {
    position: relative;
    width: 100%;
    padding-bottom: 56.25%; /* 16:9 aspect ratio */
    border-radius: 12px;
    overflow: hidden;
    box-shadow: 
      0 20px 60px rgba(0,0,0,0.15),
      0 0 0 8px white,
      0 0 0 10px #d4c9a8;
  }
  
  .video-wrapper iframe {
    position: absolute;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    border: none;
  }
  
  /* Signup Section */
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
  
  h3 {
    font-size: 1.75rem;
    font-weight: 200;
    margin-bottom: 2rem;
    text-align: center;
  }
  
  .signup-section h3 {
    margin-bottom: 1rem;
  }
  
  .signup-section p {
    margin-bottom: 2rem;
    color: #666;
    font-size: 1rem;
  }
  
  /* Desktop Responsive */
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
    
    .signup-section p {
      font-size: 1.1rem;
    }
  }
  
  /* Tablet Responsive */
  @media (max-width: 968px) {
    .about-container {
      grid-template-columns: 1fr;
      gap: 3rem;
    }
    
    .about-content h3 {
      font-size: 2rem;
      text-align: center;
    }
    
    .about-text p {
      font-size: 1rem;
      text-align: center;
    }
    
    .about-section {
      padding: 4rem 1.5rem;
    }
  }
  
  /* Mobile Responsive */
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
      padding: 1rem 0;
      min-height: auto;
    }

    .about-section {
      padding: 2rem 1rem;
    }

    .about-video-full {
      max-width: 100%;
    }
  }

.video-wrapper {
  position: relative;
  cursor: pointer;
}

.video-overlay {
  position: absolute;
  bottom: 0;
  left: 0;
  right: 0;
  background: linear-gradient(to top, rgba(0,0,0,0.7), transparent);
  padding: 2rem;
  opacity: 0;
  transition: opacity 0.3s ease;
  display: flex;
  justify-content: center;
  align-items: flex-end;
  pointer-events: none;
}

.video-wrapper:hover .video-overlay {
  opacity: 1;
}

.video-overlay span {
  color: white;
  font-size: 1.1rem;
  font-weight: 500;
  text-shadow: 0 2px 4px rgba(0,0,0,0.5);
}

/* Mobile: Always show the overlay hint since there's no hover */
@media (max-width: 768px) {
  .video-overlay {
    opacity: 0.8;
    padding: 1rem;
  }
  
  .video-overlay span {
    font-size: 0.95rem;
  }
}

/* Touch devices: Show overlay by default */
@media (hover: none) and (pointer: coarse) {
  .video-overlay {
    opacity: 0.8;
  }
}

.click-overlay {
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  z-index: 2;
  cursor: pointer;
}

.video-overlay {
  position: absolute;
  bottom: 0;
  left: 0;
  right: 0;
  background: linear-gradient(to top, rgba(0,0,0,0.7), transparent);
  padding: 2rem;
  opacity: 0;
  transition: opacity 0.3s ease;
  display: flex;
  justify-content: center;
  align-items: flex-end;
  pointer-events: none;
  z-index: 3; /* Above click overlay */
}

</style>
