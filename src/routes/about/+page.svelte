<!-- src/routes/about/+page.svelte -->
<script>
  import InkRevealVideo from '$lib/components/ui/InkRevealVideo.svelte';
  import { t } from '$lib/translations';

  function scrollToContent() {
    const contentSection = document.getElementById('about-content');
    contentSection?.scrollIntoView({ behavior: 'smooth' });
  }
</script>

<svelte:head>
  <title>{$t('site.title')} - About</title>
  <meta name="description" content="Learn more about Antoine and his creative journey" />
</svelte:head>

<!-- Hero Section with Video -->
<section class="hero">
  <div class="hero-video-container">
    <iframe
      src="https://customer-9kroafxwku5qm6fx.cloudflarestream.com/fd7341d70b1a5517bb56a569d2a0cb38/iframe?muted=true&loop=true&autoplay=true&controls=false"
      class="hero-video"
      allow="accelerometer; gyroscope; autoplay; encrypted-media; picture-in-picture; fullscreen"
      allowfullscreen
      loading="eager"
      title="About Antoine - Creative Journey"
    ></iframe>
    <div class="hero-overlay"></div>
  </div>
  
  <div class="hero-content">
    <h2>
      <InkRevealVideo 
        text="The Artist's Journey"
        fadeInAt={8}
        fadeOutAt={15}
      />
    </h2>
    <p>
      <InkRevealVideo 
        text="Every sketch tells a story"
        fadeInAt={10}
        fadeOutAt={15}
      />
    </p>
    <InkRevealVideo
      isScroll
      fadeInAt={12}
      fadeOutAt={15}
      on:click={scrollToContent}
    />
  </div>
</section>

<!-- Content Section -->
<section id="about-content" class="content-section">
  <div class="container">
    <div class="about-grid">
      <div class="about-text">
        <h3>About Antoine</h3>
        <p>{$t('pages.home.about.p1')}</p>
        <p>{$t('pages.home.about.p2')}</p>
        
        <h4>Creative Process</h4>
        <p>
          Each piece begins with observation—a moment captured in time, 
          a feeling distilled into lines and shadows. Through daily sketches 
          and weekly stories, the journey unfolds.
        </p>
        
        <h4>Philosophy</h4>
        <p>
          Art is not about perfection; it's about presence. Every sketch, 
          every story, is an invitation to pause and see the world through 
          different eyes.
        </p>
      </div>
      
      <div class="about-sidebar">
        <div class="info-box">
          <h5>Connect</h5>
          <ul>
            <li>Email: contact@antoine.patraldo.com</li>
            <li>Based in: Guadalajara, Mexico</li>
          </ul>
        </div>
        
        <div class="info-box">
          <h5>Newsletter</h5>
          <p>
            Weekly stories and sketches delivered to your inbox. 
            No spam, just art.
          </p>
          <a href="/#contact" class="cta-button">Subscribe</a>
        </div>
      </div>
    </div>
  </div>
</section>

<style>
  /* Hero with video */
  .hero {
    position: relative;
    height: 100vh;
    display: flex;
    align-items: center;
    justify-content: center;
    overflow: hidden;
    margin: 0;
    padding: 0;
    background: #000;
  }

  .hero-video-container,
  .hero-video {
    position: absolute;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    z-index: 1;
  }

  .hero-overlay {
    position: absolute;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    background: linear-gradient(to bottom, rgba(0,0,0,0.1), rgba(0,0,0,0.5));
    z-index: 2;
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
    margin: 0 0 1rem;
    letter-spacing: 2px;
    text-shadow: 0 2px 4px rgba(0,0,0,0.5);
  }

  .hero-content p {
    font-size: 1rem;
    font-weight: 300;
    text-shadow: 0 1px 2px rgba(0,0,0,0.5);
  }

  /* Content Section */
  .content-section {
    padding: 4rem 0;
    background: white;
  }

  .container {
    max-width: 1200px;
    margin: 0 auto;
    padding: 0 2rem;
  }

  .about-grid {
    display: grid;
    grid-template-columns: 1fr;
    gap: 3rem;
  }

  .about-text h3 {
    font-size: 2.5rem;
    font-weight: 200;
    margin-bottom: 2rem;
    color: #2c5e3d;
  }

  .about-text h4 {
    font-size: 1.5rem;
    font-weight: 300;
    margin: 2rem 0 1rem;
    color: #4a4a3c;
  }

  .about-text p {
    font-size: 1.1rem;
    line-height: 1.8;
    margin-bottom: 1.5rem;
    color: #555;
  }

  .info-box {
    background: #f8f7f4;
    padding: 2rem;
    border-radius: 8px;
    margin-bottom: 1.5rem;
  }

  .info-box h5 {
    font-size: 1.2rem;
    font-weight: 400;
    margin-bottom: 1rem;
    color: #2c5e3d;
  }

  .info-box ul {
    list-style: none;
    padding: 0;
  }

  .info-box li {
    margin-bottom: 0.5rem;
    color: #555;
  }

  .info-box p {
    color: #666;
    font-size: 0.95rem;
    line-height: 1.6;
  }

  .cta-button {
    display: inline-block;
    margin-top: 1rem;
    padding: 0.75rem 1.5rem;
    background: #2c5e3d;
    color: white;
    text-decoration: none;
    border-radius: 4px;
    transition: background 0.3s ease;
  }

  .cta-button:hover {
    background: #234a31;
  }

  /* Tablet and up */
  @media (min-width: 768px) {
    .hero-content h2 {
      font-size: 3rem;
    }

    .hero-content p {
      font-size: 1.2rem;
    }

    .about-grid {
      grid-template-columns: 2fr 1fr;
      gap: 4rem;
    }
  }

  /* Mobile */
  @media (max-width: 768px) {
    .hero {
      height: 70vh;
    }

    .about-text h3 {
      font-size: 1.8rem;
    }

    .about-text h4 {
      font-size: 1.2rem;
    }

    .about-text p {
      font-size: 1rem;
    }

    .container {
      padding: 0 1rem;
    }
  }
</style>
