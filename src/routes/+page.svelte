<script>
  import Gallery from '$lib/components/Gallery.svelte';
  import EmailSignup from '$lib/components/EmailSignup.svelte';
</script>
<svelte:head>
  <title>Antoine Patraldo - Arte</title>
  <meta name="description" content="Disfrutando la vida un dibujo a la vez." />
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@100;200;300;400;500&display=swap" rel="stylesheet">
</svelte:head>
<!-- Hero Section -->
<section class="hero">
  <div class="hero-content">
    <h2>Visual Narratives</h2>
    <p>Exploring the intersection of digital and traditional media</p>
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
      <h3>About</h3>
      <p>Dibujando lo que me da la ganas, cuando me da la ganas, para quienes me dan la ganas"</p>
      <p>Trabajando de mi studio en Santa Teresita, Guadalajara, México.</p>
    </div>
  </div>
</section>
<!-- Email Signup Section -->
<section id="contact" class="signup-section">
  <div class="container">
    <h3>Mantente al dia</h3>
    <p>Recibe - muy de vez en cuand - invitaciones a exhibiciones en mi galería La Musa que Más Aplauda en Santa Tere.</p>
    <EmailSignup />
  </div>
</section>
<style>
  .hero {
    height: 70vh;
    display: flex;
    align-items: center;
    justify-content: center;
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    color: white;
    text-align: center;
  }
  .hero-content h2 {
    font-size: 3.5rem;
    font-weight: 100;
    margin: 0 0 1rem 0;
    letter-spacing: 3px;
  }
  .hero-content p {
    font-size: 1.2rem;
    font-weight: 300;
    opacity: 0.9;
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
