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

<!-- Hero Section -->
<section class="hero">
  <div class="hero-image-container">
    <img 
      src="https://antoine.patraldo.com/cdn-cgi/imagedelivery/4bRSwPonOXfEIBVZiDXg0w/92c712f4-aec1-4e68-1cec-fcd9682eae00/desktop" 
      alt="Antoine Patraldo Art" 
      class="hero-background"
      loading="eager"
      importance="high"
    />
    <div class="hero-overlay"></div>
  </div>
  <div class="hero-content">
    <h2>Descubrimiento</h2>
    <p>ilusión e improvisación a través de mis plumas</p>
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
  .hero {
    height: 70vh;
    position: relative;
    display: flex;
    align-items: center;
    justify-content: center;
    overflow: hidden;
  }
  
  .hero-image-container {
    position: absolute;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    z-index: 1;
  }
  
  .hero-background {
    width: 100%;
    height: 100%;
    object-fit: cover;
    transform: scale(1.1);
    transition: transform 10s ease-out;
  }
  
  .hero:hover .hero-background {
    transform: scale(1);
  }
  
  .hero-overlay {
    position: absolute;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    background: linear-gradient(to bottom, rgba(0,0,0,0.1), rgba(0,0,0,0.7));
    z-index: 2;
  }
  
  .hero-content {
    position: relative;
    z-index: 3;
    text-align: center;
    color: white;
    padding: 0 2rem;
    max-width: 800px;
  }
  
  .hero-content h2 {
    font-size: 3.5rem;
    font-weight: 100;
    margin: 0 0 1rem 0;
    letter-spacing: 3px;
    text-shadow: 0 2px 4px rgba(0,0,0,0.5);
  }
  
  .hero-content p {
    font-size: 1.2rem;
    font-weight: 300;
    opacity: 0.9;
    text-shadow: 0 1px 2px rgba(0,0,0,0.5);
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
    padding: 0 2rem;
  }
  
  .about-content {
    max-width: 600px;
    margin: 0 auto;
  }
  
  h3 {
    font-size: 2.5rem;
    font-weight: 200;
    margin-bottom: 2rem;
    text-align: center;
  }
  
  .about-content p {
    font-size: 1.1rem;
    margin-bottom: 1.5rem;
    color: #555;
  }
  
  .signup-section h3 {
    margin-bottom: 1rem;
  }
  
  .signup-section p {
    margin-bottom: 2rem;
    color: #666;
    font-size: 1.1rem;
  }
  
  @media (max-width: 768px) {
    .hero-content h2 {
      font-size: 2.5rem;
    }
    
    h3 {
      font-size: 2rem;
    }
    
    .container {
      padding: 0 1rem;
    }
  }
</style>
