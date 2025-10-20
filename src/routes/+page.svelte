<script>
  import Gallery from '$lib/components/Gallery.svelte';
  import EmailSignup from '$lib/components/EmailSignup.svelte';
</script>

<svelte:head>
  <title>Antoine PATRALDO - Arte</title>
  <meta name="description" content="Disfrutando la vida un dibujo a la vez." />
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@100;200;300;400;500&display=swap" rel="stylesheet" />
</svelte:head>

<!-- Hero Section with Video -->
<section class="hero">
  <div class="hero-video-container">
    <!-- Cloudflare Stream video -->

<div style="position: relative; padding-top: 100%;">
  <iframe
    src="https://customer-9kroafxwku5qm6fx.cloudflarestream.com/ae704cadc61df756c41bc2f3404f2cf0/iframe?poster=https%3A%2F%2Fcustomer-9kroafxwku5qm6fx.cloudflarestream.com%2Fae704cadc61df756c41bc2f3404f2cf0%2Fthumbnails%2Fthumbnail.jpg%3Ftime%3D%26height%3D600"
    loading="lazy"
    style="border: none; position: absolute; top: 0; left: 0; height: 100%; width: 100%;"
    allow="accelerometer; gyroscope; autoplay; encrypted-media; picture-in-picture;"
    allowfullscreen="true"
  ></iframe>
</div>
    
    <div class="hero-overlay"></div>
  </div>
  
  <div class="hero-content">
    <h2 class="fade-in-up">Descubrimiento</h2>
    <p class="fade-in-up delay">ilustración, ilusión e improvisación</p>
    <div class="scroll-indicator fade-in delay-2">
      <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        <path d="M12 5v14M19 12l-7 7-7-7"/>
      </svg>
    </div>
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
      <h3>Acerca</h3>
      <p>Dibujando lo que me da la gana, cuando me da la gana, para quienes me dan las ganas</p>
      <p>Trabajo muy a gusto en mi estudio en Santa Teresita, Guadalajara, México.</p>
    </div>
  </div>
</section>

<!-- Email Signup Section -->
<section id="contact" class="signup-section">
  <div class="container">
    <h3>Manténgase al día</h3>
    <p>Recibe noticias - muy de vez en cuando - e invitaciones a exhibiciones en mi galería La Musa que Más Aplauda en Santa Tere.</p>
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
  
  /* h2 appears at 8 seconds */
  .hero-content h2.fade-in-up {
    animation-delay: 8s;
  }
  
  /* p appears at 10 seconds */
  .hero-content p.fade-in-up.delay {
    animation-delay: 10s;
  }
  
  /* Scroll indicator appears at 12 seconds */
  .fade-in.delay-2 {
    animation: fadeInUp 1s ease-out 12s forwards;
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
    position: absolute;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    z-index: 1;
    padding: 0 !important; /* Override any inline padding */
  }
  
  .hero-video {
    width: 100%;
    height: 100%;
    border: none;
    object-fit: cover;
    position: absolute;
    top: 0;
    left: 0;
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
