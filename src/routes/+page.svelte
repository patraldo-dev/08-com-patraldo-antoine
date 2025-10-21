<script>
  import Gallery from '$lib/components/Gallery.svelte';
  import EmailSignup from '$lib/components/EmailSignup.svelte';
  import InkReveal from '$lib/components/ui/InkReveal.svelte';
  import { t } from '$lib/translations';
  import { onMount } from 'svelte';

  // Smooth scroll to gallery
  function scrollToGallery() {
    const gallerySection = document.getElementById('work');
    gallerySection?.scrollIntoView({ behavior: 'smooth' });
  }

  // No more manual animation reset!
  // The InkReveal component handles timing via CSS
</script>

<svelte:head>
  <title>{$t('site.title')} - {$t('pages.home.meta.title')}</title>
  <meta name="description" content={$t('pages.home.meta.description')} />
  <link rel="preconnect" href="https://fonts.googleapis.com" />
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin />
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@100;200;300;400;500&display=swap" rel="stylesheet" />
</svelte:head>

<!-- Hero Section -->
<section class="hero">
  <div class="hero-video-container">
    <iframe
      src="https://customer-9kroafxwku5qm6fx.cloudflarestream.com/fd7341d70b1a5517bb56a569d2a0cb38/iframe?muted=true&loop=true&autoplay=true&controls=false"
      class="hero-video"
      allow="accelerometer; gyroscope; autoplay; encrypted-media; picture-in-picture; fullscreen"
      allowfullscreen
      loading="eager"
      title={$t('pages.home.hero.videoTitle')}
    ></iframe>
    <div class="hero-overlay"></div>
  </div>

  <div class="hero-content">
    <h2>
      <InkReveal 
        text={$t('pages.home.hero.title')}
        fadeInAt={8}
        fadeOutAt={15}
      />
    </h2>
    <p>
      <InkReveal 
        text={$t('pages.home.hero.subtitle')}
        fadeInAt={10}
        fadeOutAt={15}
      />
    </p>
    <InkReveal
      isScroll
      fadeInAt={12}
      fadeOutAt={15}
      on:click={scrollToGallery}
      role="button"
      tabindex="0"
      on:keydown={(e) => e.key === 'Enter' && scrollToGallery()}
    />
  </div>
</section>

<!-- Gallery Section -->
<section id="work" class="work-section">
  <Gallery />
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


