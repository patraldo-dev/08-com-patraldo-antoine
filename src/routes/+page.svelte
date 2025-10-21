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

<style>
  /* Mobile-first base styles */
  .hero {
    height: 70vh;
    position: relative;
    display: flex;
    align-items: center;
    justify-content: center;
    overflow: hidden;
    margin: 0;
    padding: 0;
    background-color: #1a1a1a; /* Dark background to reduce flash - adjust to match video */
  }
  
  /* Text Animations - with specific delays */
  @keyframes fadeInUp {
    from {
      opacity: 0;
      transform: translateY(20px);
    }
    to {
      opacity: 1;
      transform: translateY(0);
    }
  }
  
  @keyframes fadeOutDown {
    from {
      opacity: 1;
      transform: translateY(0);
    }
    to {
      opacity: 0;
      transform: translateY(20px);
    }
  }
  
  @keyframes float {
    0%, 100% {
      transform: translateY(0);
    }
    50% {
      transform: translateY(-8px);
    }
  }
  
  .fade-in-up {
    animation: fadeInUp 1s ease-out forwards;
    opacity: 0;
  }
  
  /* h2 appears at 8 seconds, fades out at 15 seconds */
  .hero-content h2.fade-in-up {
    animation: fadeInUp 1s ease-out 8s forwards, fadeOutDown 1s ease-out 15s forwards;
  }
  
  /* p appears at 10 seconds, fades out at 15 seconds */
  .hero-content p.fade-in-up.delay {
    animation: fadeInUp 1s ease-out 10s forwards, fadeOutDown 1s ease-out 15s forwards;
  }
  
  /* Scroll indicator appears at 12 seconds, fades out at 15 seconds */
  .fade-in.delay-2 {
    animation: fadeInUp 1s ease-out 12s forwards, fadeOutDown 1s ease-out 15s forwards;
    opacity: 0;
  }
  
  .scroll-indicator {
    margin-top: 2rem;
    animation: float 2s ease-in-out infinite;
    animation-delay: 13s;
    opacity: 0;
  }
  
  /* Make scroll indicator visible after fade-in */
  .scroll-indicator.fade-in.delay-2 {
    opacity: 0;
  }
  
  @keyframes floatVisible {
    0% { 
      opacity: 1;
      transform: translateY(0);
    }
    50% { 
      opacity: 1;
      transform: translateY(-8px);
    }
    100% { 
      opacity: 1;
      transform: translateY(0);
    }
  }
  
  .scroll-indicator {
    animation: fadeInUp 1s ease-out 12s forwards, floatVisible 2s ease-in-out 13s infinite;
  }
  
  .scroll-indicator svg {
    filter: drop-shadow(0 2px 4px rgba(0,0,0,0.5));
  }
  
  .hero-video-container {
    position: absolute !important;
    top: 0 !important;
    left: 0 !important;
    width: 100% !important;
    height: 100% !important;
    z-index: 1;
    padding: 0 !important;
    margin: 0 !important;
  }
  
  .hero-video {
    width: 100% !important;
    height: 100% !important;
    border: none !important;
    object-fit: cover;
    position: absolute !important;
    top: 0 !important;
    left: 0 !important;
    filter: brightness(1.3) contrast(1.15) saturate(1.3);
  }
  
  .hero-overlay {
    position: absolute;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    background: linear-gradient(to bottom, rgba(0,0,0,0.1), rgba(0,0,0,0.5));
    z-index: 2;
    pointer-events: none;
  }
  
  .hero-content {
    position: relative;
    z-index: 3;
    text-align: center;
    color: white;
    padding: 0 1rem;
    max-width: 800px;
  }
  
  .hero-content h2 {
    font-size: 2rem;
    font-weight: 100;
    margin: 0 0 1rem 0;
    letter-spacing: 2px;
    text-shadow: 0 2px 4px rgba(0,0,0,0.5);
    color: white;
    opacity: 0; /* Start hidden */
  }
  
  .hero-content p {
    font-size: 1rem;
    font-weight: 300;
    text-shadow: 0 1px 2px rgba(0,0,0,0.5);
    color: white;
    opacity: 0; /* Start hidden */
  }
  
  .work-section {
    padding: 4rem 0;
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
  
  /* Tablet and up */
  @media (min-width: 768px) {
    .hero-content {
      padding: 0 2rem;
    }
    
    .hero-content h2 {
      font-size: 2.5rem;
      letter-spacing: 2.5px;
    }
    
    .hero-content p {
      font-size: 1.1rem;
    }
    
    .scroll-indicator {
      margin-top: 2.5rem;
    }
    
    @keyframes float {
      0%, 100% {
        transform: translateY(0);
      }
      50% {
        transform: translateY(-10px);
      }
    }
    
    @keyframes floatVisible {
      0% { 
        opacity: 1;
        transform: translateY(0);
      }
      50% { 
        opacity: 1;
        transform: translateY(-10px);
      }
      100% { 
        opacity: 1;
        transform: translateY(0);
      }
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
  
  /* Desktop and up */
  @media (min-width: 1024px) {
    .hero-content h2 {
      font-size: 3.5rem;
      letter-spacing: 3px;
    }
    
    .hero-content p {
      font-size: 1.2rem;
    }
    
    .scroll-indicator {
      margin-top: 3rem;
    }
    
    @keyframes fadeInUp {
      from {
        opacity: 0;
        transform: translateY(30px);
      }
      to {
        opacity: 1;
        transform: translateY(0);
      }
    }
  }
</style>
