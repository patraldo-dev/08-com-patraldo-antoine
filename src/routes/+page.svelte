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
    height: 100vh;
    position: relative;
    display: flex;
    align-items: center;
    justify-content: center;
    overflow: hidden;
  }
  
  /* Text Animations */
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
  
  /* New animations for Option 4: Ink Reveal Effect */
  @keyframes inkReveal {
    0% {
      opacity: 0;
      clip-path: polygon(0 100%, 100% 100%, 100% 100%, 0 100%);
    }
    50% {
      opacity: 0.7;
      clip-path: polygon(0 0, 100% 0, 100% 100%, 0 100%);
    }
    100% {
      opacity: 1;
      clip-path: polygon(0 0, 100% 0, 100% 100%, 0 100%);
    }
  }
  
  @keyframes fadeInRight {
    from {
      opacity: 0;
      transform: translateX(30px);
    }
    to {
      opacity: 1;
      transform: translateX(0);
    }
  }
  
  @keyframes backgroundShift {
    to {
      background-position: 0 0;
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
  
  .fade-in-up.delay {
    animation-delay: 0.3s;
  }
  
  .fade-in.delay-2 {
    animation: fadeInUp 1s ease-out 0.8s forwards;
    opacity: 0;
  }
  
  .scroll-indicator {
    margin-top: 2rem;
    animation: float 2s ease-in-out infinite;
    animation-delay: 1.5s;
  }
  
  .scroll-indicator svg {
    filter: drop-shadow(0 2px 4px rgba(0,0,0,0.5));
  }
  
  .hero-video-container {
    position: absolute;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    z-index: 1;
  }
  
  .hero-video {
    width: 100%;
    height: 100%;
    border: none;
    object-fit: cover;
    position: absolute;
    top: 0;
    left: 0;
    filter: brightness(1.2) contrast(1.05) saturate(1.1);
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
  /* Remove all opacity and animation properties - InkReveal handles it */
}
  
  .hero-content p {
  font-size: 1rem;
  font-weight: 300;
  text-shadow: 0 1px 2px rgba(0,0,0,0.5);
  color: white;
  /* Remove all opacity and animation properties - InkReveal handles it */
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
  
  /* Tablet and up - Other sections */
  @media (min-width: 768px) {
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
