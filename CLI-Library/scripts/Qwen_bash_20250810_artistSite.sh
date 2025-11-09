#!/bin/bash

# create-portfolio.sh
# Creates the full SvelteKit src/ and lib/ structure for your artist portfolio

set -e  # Exit on any error

echo "🎨 Creating artist portfolio structure..."

# Create directories
mkdir -p src/routes/api/subscribe
mkdir -p src/lib/components
mkdir -p static/artwork

# Create app.css
cat > src/app.css << 'EOF'
/* This file will be imported in +layout.svelte */
EOF

# Create +layout.svelte
cat > src/routes/+layout.svelte << 'EOF'
<script>
  import '../app.css';
</script>
<div class="app">
  <nav>
    <h1>MAYA CHEN</h1>
    <div class="nav-links">
      <a href="#work">Work</a>
      <a href="#about">About</a>
      <a href="#contact">Stay Updated</a>
    </div>
  </nav>
  <main>
    <slot />
  </main>
  <footer>
    <p>&copy; 2025 Maya Chen. All rights reserved.</p>
  </footer>
</div>
<style>
  :global(body) {
    margin: 0;
    padding: 0;
    font-family: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif;
    background: #fafafa;
    color: #2a2a2a;
    line-height: 1.6;
  }
  :global(*) {
    box-sizing: border-box;
  }
  .app {
    min-height: 100vh;
    display: flex;
    flex-direction: column;
  }
  nav {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 2rem 4rem;
    background: rgba(255, 255, 255, 0.95);
    backdrop-filter: blur(10px);
    position: fixed;
    top: 0;
    left: 0;
    right: 0;
    z-index: 100;
    border-bottom: 1px solid rgba(0, 0, 0, 0.05);
  }
  h1 {
    font-size: 1.5rem;
    font-weight: 300;
    letter-spacing: 2px;
    margin: 0;
  }
  .nav-links {
    display: flex;
    gap: 2rem;
  }
  .nav-links a {
    text-decoration: none;
    color: inherit;
    font-weight: 300;
    transition: opacity 0.3s;
  }
  .nav-links a:hover {
    opacity: 0.6;
  }
  main {
    flex: 1;
    margin-top: 80px;
  }
  footer {
    padding: 2rem 4rem;
    text-align: center;
    font-size: 0.9rem;
    color: #666;
    border-top: 1px solid rgba(0, 0, 0, 0.05);
  }
  @media (max-width: 768px) {
    nav {
      padding: 1rem 2rem;
      flex-direction: column;
      gap: 1rem;
    }
    .nav-links {
      gap: 1.5rem;
    }
    footer {
      padding: 1rem 2rem;
    }
  }
</style>
EOF

# Create +page.svelte
cat > src/routes/+page.svelte << 'EOF'
<script>
  import Gallery from '$lib/components/Gallery.svelte';
  import EmailSignup from '$lib/components/EmailSignup.svelte';
</script>
<svelte:head>
  <title>Maya Chen - Visual Artist</title>
  <meta name="description" content="Contemporary visual artist specializing in mixed media, digital art, and experimental forms." />
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
      <p>
        I create visual narratives that blur the boundaries between digital and physical spaces. 
        My work explores themes of identity, memory, and transformation through drawings, 
        video installations, and experimental digital media.
      </p>
      <p>
        Currently based in Brooklyn, NY, I exhibit internationally and collaborate 
        with musicians, writers, and technologists on interdisciplinary projects.
      </p>
    </div>
  </div>
</section>
<!-- Email Signup Section -->
<section id="contact" class="signup-section">
  <div class="container">
    <h3>Stay Connected</h3>
    <p>Get updates about new work, exhibitions, and studio insights.</p>
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
EOF

# Create Gallery.svelte
cat > src/lib/components/Gallery.svelte << 'EOF'
<script>
  import ArtPiece from './ArtPiece.svelte';
  // Sample artwork data - all files stored in R2, thumbnails in Cloudflare Images
  const artworks = [
    {
      id: 1,
      title: "Metamorphosis Series #1",
      type: "still",
      r2Url: "https://your-r2-bucket.r2.cloudflarestorage.com/stills/metamorphosis-1.jpg",
      thumbnailId: "thumb-meta-1", // Cloudflare Images ID for optimized thumbnail
      description: "Charcoal and digital manipulation, 2024",
      year: 2024
    },
    {
      id: 2,
      title: "Temporal Fragments",
      type: "animation",
      r2Url: "https://your-r2-bucket.r2.cloudflarestorage.com/videos/temporal-fragments.mp4",
      thumbnailId: "thumb-temporal", // Video thumbnail from Cloudflare Images
      description: "Video installation, 3:42 min, 2024",
      year: 2024
    },
    {
      id: 3,
      title: "Memory Loop",
      type: "gif",
      r2Url: "https://your-r2-bucket.r2.cloudflarestorage.com/gifs/memory-loop.gif",
      thumbnailId: "thumb-memory", // Static thumbnail of the GIF
      description: "Animated sequence, 2024",
      year: 2024
    },
    {
      id: 4,
      title: "Digital Archaeology",
      type: "still",
      r2Url: "https://your-r2-bucket.r2.cloudflarestorage.com/stills/digital-archaeology.jpg",
      thumbnailId: "thumb-arch", 
      description: "Mixed media on canvas, 2024",
      year: 2024
    },
    {
      id: 5,
      title: "Fluid Motion Study",
      type: "animation",
      r2Url: "https://your-r2-bucket.r2.cloudflarestorage.com/videos/fluid-motion.mp4",
      thumbnailId: "thumb-fluid",
      description: "Video study, 1:20 min, 2023",
      year: 2023
    },
    {
      id: 6,
      title: "Glitch Portrait",
      type: "gif",
      r2Url: "https://your-r2-bucket.r2.cloudflarestorage.com/gifs/glitch-portrait.gif",
      thumbnailId: "thumb-glitch",
      description: "Digital manipulation, 2023",
      year: 2023
    }
  ];
  // Cloudflare Images base URL for thumbnails only
  const CF_IMAGES_BASE = "https://imagedelivery.net/your-account-hash";
  let selectedType = 'all';
  // Filter artworks based on selected type
  $: filteredArtworks = selectedType === 'all' 
    ? artworks 
    : artworks.filter(artwork => artwork.type === selectedType);
  // Get unique types for filter dropdown
  const artworkTypes = [
    { value: 'all', label: 'All Work' },
    { value: 'still', label: 'Still Images' },
    { value: 'animation', label: 'Videos' },
    { value: 'gif', label: 'Animated GIFs' }
  ];
</script>
<div class="gallery">
  <div class="container">
    <div class="header">
      <h3>Recent Work</h3>
      <!-- Filter Dropdown -->
      <div class="filter-container">
        <select bind:value={selectedType} class="filter-select">
          {#each artworkTypes as type}
            <option value={type.value}>{type.label}</option>
          {/each}
        </select>
      </div>
    </div>
    <div class="grid">
      {#each filteredArtworks as artwork (artwork.id)}
        <ArtPiece {artwork} {CF_IMAGES_BASE} />
      {/each}
    </div>
    {#if filteredArtworks.length === 0}
      <div class="no-results">
        <p>No {selectedType} artworks to display yet.</p>
      </div>
    {/if}
  </div>
</div>
<style>
  .gallery {
    padding: 2rem 0;
  }
  .container {
    max-width: 1200px;
    margin: 0 auto;
    padding: 0 2rem;
  }
  .header {
    text-align: center;
    margin-bottom: 3rem;
  }
  h3 {
    font-size: 2.5rem;
    font-weight: 200;
    margin-bottom: 2rem;
    color: #2a2a2a;
  }
  .filter-container {
    display: flex;
    justify-content: center;
    margin-bottom: 1rem;
  }
  .filter-select {
    padding: 0.75rem 1.5rem;
    font-size: 1rem;
    border: 2px solid #e0e0e0;
    border-radius: 6px;
    background: white;
    color: #2a2a2a;
    cursor: pointer;
    outline: none;
    transition: border-color 0.3s, box-shadow 0.3s;
    font-family: inherit;
  }
  .filter-select:hover {
    border-color: #667eea;
  }
  .filter-select:focus {
    border-color: #667eea;
    box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.1);
  }
  .grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(350px, 1fr));
    gap: 2rem;
    transition: all 0.3s ease;
  }
  .no-results {
    text-align: center;
    padding: 4rem 0;
    color: #666;
    font-style: italic;
  }
  @media (max-width: 768px) {
    .container {
      padding: 0 1rem;
    }
    .grid {
      grid-template-columns: 1fr;
      gap: 1.5rem;
    }
    h3 {
      font-size: 2rem;
    }
  }
</style>
EOF

# Create ArtPiece.svelte
cat > src/lib/components/ArtPiece.svelte << 'EOF'
<script>
  export let artwork;
  export let CF_IMAGES_BASE;
  let showFullSize = false;
  let isLoading = false;
  // Build Cloudflare Images URL for thumbnails only
  function getThumbnailUrl(thumbnailId, variant = 'thumbnail') {
    return `${CF_IMAGES_BASE}/${thumbnailId}/${variant}`;
  }
  // Handle click to show full-size version
  function handleClick() {
    if (artwork.type === 'still') {
      showFullSize = true;
    }
    // For videos and gifs, they already show the full version inline
  }
  // Close full-size view
  function closeFullSize() {
    showFullSize = false;
  }
</script>
<div class="art-piece">
  <div class="media-container" on:click={handleClick} role="button" tabindex="0">
    {#if artwork.type === 'still'}
      <!-- Show thumbnail from Cloudflare Images, full-size from R2 -->
      <img 
        src={getThumbnailUrl(artwork.thumbnailId, 'gallery')}
        alt={artwork.title}
        loading="lazy"
      />
      {#if showFullSize}
        <!-- Full-size overlay -->
        <div class="fullsize-overlay" on:click={closeFullSize} role="button" tabindex="0">
          <div class="fullsize-content" on:click|stopPropagation>
            {#if isLoading}
              <div class="loading">Loading full resolution...</div>
            {/if}
            <img 
              src={artwork.r2Url}
              alt={artwork.title}
              on:load={() => isLoading = false}
              on:error={() => isLoading = false}
            />
            <button class="close-btn" on:click={closeFullSize}>&times;</button>
          </div>
        </div>
      {/if}
    {:else if artwork.type === 'animation'}
      <!-- Show thumbnail as poster, full video from R2 -->
      <video 
        src={artwork.r2Url}
        poster={getThumbnailUrl(artwork.thumbnailId, 'poster')}
        controls
        preload="metadata"
      >
        Your browser doesn't support video.
      </video>
    {:else if artwork.type === 'gif'}
      <!-- Show static thumbnail, full GIF from R2 on hover -->
      <div class="gif-container">
        <img 
          class="gif-thumbnail"
          src={getThumbnailUrl(artwork.thumbnailId, 'static')}
          alt={artwork.title}
          loading="lazy"
        />
        <img 
          class="gif-animated"
          src={artwork.r2Url}
          alt={artwork.title}
          loading="lazy"
        />
      </div>
    {/if}
  </div>
  <div class="info">
    <h4>{artwork.title}</h4>
    <p>{artwork.description}</p>
    <span class="type-badge {artwork.type}">
      {#if artwork.type === 'still'}
        📷 Still
      {:else if artwork.type === 'animation'}
        🎬 Video
      {:else if artwork.type === 'gif'}
        🎭 Animated
      {/if}
    </span>
    {#if artwork.type === 'still'}
      <span class="click-hint">Click to view full size</span>
    {/if}
  </div>
</div>
<style>
  .art-piece {
    background: white;
    border-radius: 8px;
    overflow: hidden;
    box-shadow: 0 4px 20px rgba(0, 0, 0, 0.08);
    transition: transform 0.3s, box-shadow 0.3s;
    position: relative;
  }
  .art-piece:hover {
    transform: translateY(-5px);
    box-shadow: 0 8px 30px rgba(0, 0, 0, 0.12);
  }
  .media-container {
    aspect-ratio: 4/3;
    overflow: hidden;
    background: #f8f9fa;
    position: relative;
  }
  .media-container[role="button"] {
    cursor: pointer;
  }
  img, video {
    width: 100%;
    height: 100%;
    object-fit: cover;
    transition: scale 0.3s;
  }
  .art-piece:hover img,
  .art-piece:hover video {
    scale: 1.05;
  }
  /* GIF container with hover effect */
  .gif-container {
    position: relative;
    width: 100%;
    height: 100%;
  }
  .gif-thumbnail {
    position: absolute;
    top: 0;
    left: 0;
    opacity: 1;
    transition: opacity 0.3s;
  }
  .gif-animated {
    position: absolute;
    top: 0;
    left: 0;
    opacity: 0;
    transition: opacity 0.3s;
  }
  .gif-container:hover .gif-thumbnail {
    opacity: 0;
  }
  .gif-container:hover .gif-animated {
    opacity: 1;
  }
  /* Full-size overlay */
  .fullsize-overlay {
    position: fixed;
    top: 0;
    left: 0;
    width: 100vw;
    height: 100vh;
    background: rgba(0, 0, 0, 0.9);
    display: flex;
    align-items: center;
    justify-content: center;
    z-index: 1000;
    cursor: pointer;
  }
  .fullsize-content {
    position: relative;
    max-width: 90vw;
    max-height: 90vh;
    cursor: default;
  }
  .fullsize-content img {
    max-width: 100%;
    max-height: 100%;
    object-fit: contain;
  }
  .close-btn {
    position: absolute;
    top: -40px;
    right: 0;
    background: none;
    border: none;
    color: white;
    font-size: 3rem;
    cursor: pointer;
    line-height: 1;
  }
  .loading {
    color: white;
    text-align: center;
    padding: 2rem;
  }
  .info {
    padding: 1.5rem;
    position: relative;
  }
  h4 {
    margin: 0 0 0.5rem 0;
    font-size: 1.3rem;
    font-weight: 400;
    color: #2a2a2a;
  }
  p {
    margin: 0 0 1rem 0;
    color: #666;
    font-size: 0.95rem;
    font-style: italic;
  }
  .type-badge {
    position: absolute;
    top: 1rem;
    right: 1rem;
    padding: 0.25rem 0.75rem;
    border-radius: 20px;
    font-size: 0.8rem;
    font-weight: 500;
    letter-spacing: 0.5px;
  }
  .type-badge.still {
    background: #e3f2fd;
    color: #1565c0;
  }
  .type-badge.animation {
    background: #f3e5f5;
    color: #7b1fa2;
  }
  .type-badge.gif {
    background: #e8f5e8;
    color: #2e7d32;
  }
  .click-hint {
    font-size: 0.8rem;
    color: #999;
    font-style: italic;
  }
  @media (max-width: 768px) {
    .fullsize-content {
      max-width: 95vw;
      max-height: 95vh;
    }
    .close-btn {
      top: -30px;
      font-size: 2rem;
    }
  }
</style>
EOF

# Create EmailSignup.svelte
cat > src/lib/components/EmailSignup.svelte << 'EOF'
<script>
  let email = '';
  let isSubmitting = false;
  let message = '';
  let messageType = '';
  async function handleSubmit() {
    if (!email) return;
    isSubmitting = true;
    message = '';
    try {
      const response = await fetch('/api/subscribe', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({ email })
      });
      const result = await response.json();
      if (response.ok) {
        message = 'Please check your email to confirm your subscription!';
        messageType = 'success';
        email = '';
      } else {
        message = result.message || 'Something went wrong. Please try again.';
        messageType = 'error';
      }
    } catch (error) {
      message = 'Network error. Please try again.';
      messageType = 'error';
    }
    isSubmitting = false;
  }
</script>
<form on:submit|preventDefault={handleSubmit} class="signup-form">
  <div class="input-group">
    <input
      type="email"
      bind:value={email}
      placeholder="your@email.com"
      required
      disabled={isSubmitting}
    />
    <button type="submit" disabled={isSubmitting || !email}>
      {isSubmitting ? 'Joining...' : 'Join'}
    </button>
  </div>
  {#if message}
    <div class="message {messageType}">
      {message}
    </div>
  {/if}
</form>
<style>
  .signup-form {
    max-width: 400px;
    margin: 0 auto;
  }
  .input-group {
    display: flex;
    gap: 0;
    border-radius: 6px;
    overflow: hidden;
    box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
  }
  input {
    flex: 1;
    padding: 1rem 1.5rem;
    border: none;
    font-size: 1rem;
    outline: none;
    background: white;
  }
  button {
    padding: 1rem 2rem;
    border: none;
    background: #667eea;
    color: white;
    font-size: 1rem;
    font-weight: 500;
    cursor: pointer;
    transition: background-color 0.3s;
  }
  button:hover:not(:disabled) {
    background: #5a6fd8;
  }
  button:disabled {
    background: #ccc;
    cursor: not-allowed;
  }
  .message {
    margin-top: 1rem;
    padding: 0.75rem;
    border-radius: 4px;
    text-align: center;
    font-size: 0.9rem;
  }
  .message.success {
    background: #d4edda;
    color: #155724;
    border: 1px solid #c3e6cb;
  }
  .message.error {
    background: #f8d7da;
    color: #721c24;
    border: 1px solid #f1aeb5;
  }
  @media (max-width: 480px) {
    .input-group {
      flex-direction: column;
    }
    button {
      padding: 1rem;
    }
  }
</style>
EOF

# Create API route
mkdir -p src/routes/api/subscribe
cat > src/routes/api/subscribe/+server.js << 'EOF'
/**
 * @type {import('./$types').RequestHandler}
 */
export async function POST({ request }) {
  try {
    const { email } = await request.json();
    if (!email) {
      return new Response(
        JSON.stringify({ message: 'Email is required' }),
        { 
          status: 400, 
          headers: { 'Content-Type': 'application/json' } 
        }
      );
    }
    // Send to Cloudflare Worker
    const workerResponse = await fetch('https://your-worker.your-subdomain.workers.dev/subscribe', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ email })
    });
    if (!workerResponse.ok) {
      const error = await workerResponse.text();
      throw new Error(`Worker error: ${error}`);
    }
    const result = await workerResponse.json();
    return new Response(
      JSON.stringify({ message: result.message }),
      { 
        status: 200, 
        headers: { 'Content-Type': 'application/json' } 
      }
    );
  } catch (error) {
    console.error('Subscription error:', error);
    return new Response(
      JSON.stringify({ message: 'Failed to subscribe. Please try again.' }),
      { 
        status: 500, 
        headers: { 'Content-Type': 'application/json' } 
      }
    );
  }
}
EOF

echo "✅ All src/ and lib/ files created successfully!"
echo "💡 Next steps:"
echo "   1. Run 'npm init' and set up package.json"
echo "   2. Install SvelteKit: npm install -D svelte @sveltejs/kit @sveltejs/adapter-static"
echo "   3. Add svelte.config.js"
echo "   4. Add your artwork to static/artwork/"