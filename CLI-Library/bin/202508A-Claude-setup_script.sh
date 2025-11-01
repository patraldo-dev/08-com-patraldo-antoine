#!/bin/bash

# Artist Portfolio Setup Script - For Existing Cloudflare SvelteKit Project
# This script adds the artist portfolio files to your existing project structure

set -e  # Exit on any error

echo "🎨 Setting up Artist Portfolio in existing Cloudflare SvelteKit project"
echo "📁 Current directory: $(pwd)"

# Verify we're in the right place
if [ ! -f "wrangler.jsonc" ] || [ ! -d "src" ]; then
    echo "❌ Error: This doesn't appear to be a Cloudflare SvelteKit project"
    echo "Please run this script from your project root (where wrangler.jsonc exists)"
    exit 1
fi

echo "✅ Confirmed: Cloudflare SvelteKit project detected"

# Create additional directories we need
echo "📂 Creating additional directories..."
mkdir -p src/lib/components
mkdir -p src/routes/api/subscribe
mkdir -p static/artwork

echo "🎨 Creating global styles..."

# Create or update src/app.css
cat > src/app.css << 'EOF'
/* Reset and base styles */
* {
  box-sizing: border-box;
}

body {
  margin: 0;
  padding: 0;
  font-family: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif;
  background: #fafafa;
  color: #2a2a2a;
  line-height: 1.6;
}

/* Smooth scrolling */
html {
  scroll-behavior: smooth;
}
EOF

echo "🏗️ Updating layout and main page..."

# Update src/routes/+layout.svelte
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

    main {
      margin-top: 120px;
    }
  }
</style>
EOF

# Update src/routes/+page.svelte
cat > src/routes/+page.svelte << 'EOF'
<script>
  import Gallery from '$lib/components/Gallery.svelte';
  import EmailSignup from '$lib/components/EmailSignup.svelte';
</script>

<svelte:head>
  <title>Maya Chen - Visual Artist</title>
  <meta name="description" content="Contemporary visual artist specializing in mixed media, digital art, and experimental forms." />
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

echo "🖼️ Creating gallery components..."

# Create src/lib/components/Gallery.svelte
cat > src/lib/components/Gallery.svelte << 'EOF'
<script>
  import ArtPiece from './ArtPiece.svelte';
  
  // Sample artwork data - update with your actual URLs
  const artworks = [
    {
      id: 1,
      title: "Metamorphosis Series #1",
      type: "still",
      r2Url: "https://your-r2-bucket.r2.cloudflarestorage.com/stills/metamorphosis-1.jpg",
      thumbnailId: "thumb-meta-1",
      description: "Charcoal and digital manipulation, 2024",
      year: 2024
    },
    {
      id: 2,
      title: "Temporal Fragments",
      type: "animation",
      r2Url: "https://your-r2-bucket.r2.cloudflarestorage.com/videos/temporal-fragments.mp4",
      thumbnailId: "thumb-temporal",
      description: "Video installation, 3:42 min, 2024",
      year: 2024
    },
    {
      id: 3,
      title: "Memory Loop",
      type: "gif",
      r2Url: "https://your-r2-bucket.r2.cloudflarestorage.com/gifs/memory-loop.gif",
      thumbnailId: "thumb-memory",
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

  // Update with your actual Cloudflare Images URL
  const CF_IMAGES_BASE = "https://imagedelivery.net/your-account-hash";
  
  let selectedType = 'all';
  
  $: filteredArtworks = selectedType === 'all' 
    ? artworks 
    : artworks.filter(artwork => artwork.type === selectedType);
  
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

# Create src/lib/components/ArtPiece.svelte
cat > src/lib/components/ArtPiece.svelte << 'EOF'
<script>
  export let artwork;
  export let CF_IMAGES_BASE;
  
  let showFullSize = false;
  let isLoading = true;
  
  function getThumbnailUrl(thumbnailId, variant = 'thumbnail') {
    return `${CF_IMAGES_BASE}/${thumbnailId}/${variant}`;
  }
  
  function handleClick() {
    if (artwork.type === 'still') {
      showFullSize = true;
      isLoading = true;
    }
  }
  
  function closeFullSize() {
    showFullSize = false;
  }

  function handleKeydown(event) {
    if (event.key === 'Enter' || event.key === ' ') {
      handleClick();
    }
    if (event.key === 'Escape') {
      closeFullSize();
    }
  }
</script>

<div class="art-piece">
  <div 
    class="media-container" 
    class:clickable={artwork.type === 'still'}
    on:click={handleClick} 
    on:keydown={handleKeydown}
    role="button" 
    tabindex="0"
    aria-label={artwork.type === 'still' ? `View ${artwork.title} full size` : artwork.title}
  >
    {#if artwork.type === 'still'}
      <img 
        src={getThumbnailUrl(artwork.thumbnailId, 'gallery')}
        alt={artwork.title}
        loading="lazy"
      />
      {#if showFullSize}
        <div class="fullsize-overlay" on:click={closeFullSize} on:keydown={handleKeydown} role="button" tabindex="0">
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
            <button class="close-btn" on:click={closeFullSize} aria-label="Close full size view">&times;</button>
          </div>
        </div>
      {/if}
    {:else if artwork.type === 'animation'}
      <video 
        src={artwork.r2Url}
        poster={getThumbnailUrl(artwork.thumbnailId, 'poster')}
        controls
        preload="metadata"
        aria-label={artwork.title}
      >
        Your browser doesn't support video.
      </video>
    {:else if artwork.type === 'gif'}
      <div class="gif-container">
        <img 
          class="gif-thumbnail"
          src={getThumbnailUrl(artwork.thumbnailId, 'static')}
          alt={`${artwork.title} (static preview)`}
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

  .media-container.clickable {
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
    display: block;
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
    padding: 0;
  }

  .close-btn:hover {
    opacity: 0.7;
  }

  .loading {
    color: white;
    text-align: center;
    padding: 2rem;
    font-size: 1.1rem;
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

# Create src/lib/components/EmailSignup.svelte
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
      aria-label="Email address"
    />
    <button type="submit" disabled={isSubmitting || !email}>
      {isSubmitting ? 'Joining...' : 'Join'}
    </button>
  </div>
  
  {#if message}
    <div class="message {messageType}" role="alert">
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
    font-family: inherit;
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
    font-family: inherit;
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

echo "🔌 Creating API routes..."

# Create src/routes/api/subscribe/+server.js
cat > src/routes/api/subscribe/+server.js << 'EOF'
/**
 * @type {import('./$types').RequestHandler}
 */
export async function POST({ request }) {
  try {
    const { email } = await request.json();

    if (!email || !isValidEmail(email)) {
      return new Response(
        JSON.stringify({ message: 'Valid email is required' }),
        { 
          status: 400, 
          headers: { 'Content-Type': 'application/json' } 
        }
      );
    }

    // Send to Cloudflare Worker - update with your actual worker URL
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

function isValidEmail(email) {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
}
EOF

echo "🏗️ Creating Cloudflare Worker..."

# Create worker.js in root
cat > worker.js << 'EOF'
// Artist Portfolio Email Worker
export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    
    // Handle CORS
    if (request.method === 'OPTIONS') {
      return new Response(null, {
        headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'POST, GET, OPTIONS',
          'Access-Control-Allow-Headers': 'Content-Type'
        }
      });
    }

    // Handle email subscription
    if (request.method === 'POST' && url.pathname === '/subscribe') {
      try {
        const { email } = await request.json();

        if (!email || !isValidEmail(email)) {
          return jsonResponse({ message: 'Invalid email address' }, 400);
        }

        // Check if already subscribed
        const existingSubscriber = await env.DB.prepare(`
          SELECT confirmed FROM subscribers 
          WHERE email = ? AND type = 'art-updates'
        `).bind(email).first();

        if (existingSubscriber && existingSubscriber.confirmed) {
          return jsonResponse({ message: 'You\'re already subscribed!' }, 200);
        }

        // Send verification email
        await sendVerificationEmail(email, env);

        return jsonResponse({ message: 'Please check your email to confirm your subscription!' }, 200);

      } catch (error) {
        console.error('Subscription error:', error);
        return jsonResponse({ message: 'Failed to send verification email. Please try again.' }, 500);
      }
    }

    // Handle email verification
    if (request.method === 'GET' && url.pathname === '/verify') {
      try {
        const token = url.searchParams.get('token');

        if (!token) {
          return new Response(getErrorPage('Missing verification token'), { 
            status: 400,
            headers: { 'Content-Type': 'text/html' }
          });
        }

        const verification = await verifyEmailToken(token, env);
        if (!verification.success) {
          return new Response(getErrorPage(verification.error), {
            status: 400,
            headers: { 'Content-Type': 'text/html' }
          });
        }

        const email = verification.email;

        // Add to Mailgun mailing list
        const mailgunResponse = await fetch(
          `https://api.mailgun.net/v3/lists/art-updates@${env.MAILGUN_DOMAIN}/members`,
          {
            method: 'POST',
            headers: {
              'Authorization': `Basic ${btoa(`api:${env.MAILGUN_API_KEY}`)}`,
              'Content-Type': 'application/x-www-form-urlencoded'
            },
            body: new URLSearchParams({
              'address': email,
              'subscribed': 'true',
              'upsert': 'true'
            })
          }
        );

        if (!mailgunResponse.ok) {
          const error = await mailgunResponse.text();
          console.error('Mailgun error:', error);
          throw new Error('Failed to confirm subscription');
        }

        // Send welcome email
        await sendWelcomeEmail(email, env);

        // Clean up old expired tokens
        await cleanupExpiredTokens(env);

        return new Response(getSuccessPage(), {
          headers: { 'Content-Type': 'text/html' }
        });

      } catch (error) {
        console.error('Verification error:', error);
        return new Response(getErrorPage('Sorry, we couldn\'t verify your subscription. Please try subscribing again.'), {
          status: 500,
          headers: { 'Content-Type': 'text/html' }
        });
      }
    }

    return new Response('Not found', { status: 404 });
  }
};

// Helper functions
function jsonResponse(data, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { 
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*'
    }
  });
}

function isValidEmail(email) {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
}

async function sendVerificationEmail(email, env) {
  const token = crypto.randomUUID();
  const now = new Date().toISOString();
  const expiresAt = new Date(Date.now() + (24 * 60 * 60 * 1000)).toISOString(); // 24 hours
  
  // Store verification record in D1
  try {
    await env.DB.prepare(`
      INSERT INTO subscribers (email, type, confirmation_token, token_expires_at, created_at) 
      VALUES (?, ?, ?, ?, ?)
      ON CONFLICT(email, type) DO UPDATE SET
        confirmation_token = excluded.confirmation_token,
        token_expires_at = excluded.token_expires_at,
        confirmed = false,
        confirmed_at = NULL
    `).bind(email, 'art-updates', token, expiresAt, now).run();
  } catch (error) {
    console.error('Database error:', error);
    throw new Error('Failed to store verification record');
  }
  
  const verificationLink = `https://your-worker-domain.workers.dev/verify?token=${token}`;

  const formData = new FormData();
  formData.append('from', `Maya Chen <maya@${env.MAILGUN_DOMAIN}>`);
  formData.append('to', email);
  formData.append('subject', 'Please confirm your subscription');
  formData.append('html', getVerificationEmailHTML(verificationLink));

  const response = await fetch(`https://api.mailgun.net/v3/${env.MAILGUN_DOMAIN}/messages`, {
    method: 'POST',
    headers: {
      'Authorization': `Basic ${btoa(`api:${env.MAILGUN_API_KEY}`)}`
    },
    body: formData
  });

  if (!response.ok) {
    const error = await response.text();
    console.error('Mailgun send error:', error);
    throw new Error('Failed to send verification email');
  }
}

async function sendWelcomeEmail(email, env) {
  const formData = new FormData();
  formData.append('from', `Maya Chen <maya@${env.MAILGUN_DOMAIN}>`);
  formData.append('to', email);
  formData.append('subject', 'Welcome! You\'re now subscribed');
  formData.append('html', getWelcomeEmailHTML());

  await fetch(`https://api.mailgun.net/v3/${env.MAILGUN_DOMAIN}/messages`, {
    method: 'POST',
    headers: {
      'Authorization': `Basic ${btoa(`api:${env.MAILGUN_API_KEY}`)}`
    },
    body: formData
  });
}

async function verifyEmailToken(token, env) {
  try {
    const result = await env.DB.prepare(`
      SELECT email, token_expires_at, confirmed 
      FROM subscribers 
      WHERE confirmation_token = ? AND type = 'art-updates'
    `).bind(token).first();
    
    if (!result) {
      return { success: false, error: 'Invalid verification token' };
    }
    
    if (result.confirmed) {
      return { success: false, error: 'Email already verified' };
    }
    
    if (new Date() > new Date(result.token_expires_at)) {
      return { success: false, error: 'Verification token expired' };
    }
    
    // Mark as confirmed
    const confirmedAt = new Date().toISOString();
    await env.DB.prepare(`
      UPDATE subscribers 
      SET confirmed = true, confirmed_at = ?, confirmation_token = NULL
      WHERE confirmation_token = ? AND type = 'art-updates'
    `).bind(confirmedAt, token).run();
    
    return { success: true, email: result.email };
    
  } catch (error) {
    console.error('Database error:', error);
    return { success: false, error: 'Database error' };
  }
}

async function cleanupExpiredTokens(env) {
  const now = new Date().toISOString();
  await env.DB.prepare(`
    DELETE FROM subscribers 
    WHERE token_expires_at < ? AND confirmed = false
  `).bind(now).run();
}

// HTML Templates
function getVerificationEmailHTML(verificationLink) {
  return `
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <style>
    body { font-family: 'Inter', Arial, sans-serif; line-height: 1.6; color: #2a2a2a; max-width: 600px; margin: 0 auto; }
    .container { padding: 2rem; }
    .header { text-align: center; margin-bottom: 2rem; }
    .button { display: inline-block; padding: 1rem 2rem; background: #667eea; color: white; text-decoration: none; border-radius: 6px; margin: 1rem 0; }
    .footer { font-size: 0.9rem; color: #666; margin-top: 2rem; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1 style="font-weight: 200; letter-spacing: 2px;">MAYA CHEN</h1>
    </div>
    
    <p>Hi there,</p>
    
    <p>Thanks for your interest in my art updates! To complete your subscription, please confirm your email address by clicking the button below:</p>
    
    <p style="text-align: center;">
      <a href="${verificationLink}" class="button">Confirm Subscription</a>
    </p>
    
    <p>If the button doesn't work, you can copy and paste this link into your browser:</p>
    <p style="word-break: break-all; color: #667eea;">${verificationLink}</p>
    
    <p>This link will expire in 24 hours for security.</p>
    
    <div class="footer">
      <p>If you didn't sign up for this, you can safely ignore this email.</p>
      <p>Best,<br>Maya Chen</p>
    </div>
  </div>
</body>
</html>`;
}

function getWelcomeEmailHTML() {
  return `
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <style>
    body { font-family: 'Inter', Arial, sans-serif; line-height: 1.6; color: #2a2a2a; max-width: 600px; margin: 0 auto; }
    .container { padding: 2rem; }
    .header { text-align: center; margin-bottom: 2rem; }
    .button { display: inline-block; padding: 1rem 2rem; background: #667eea; color: white; text-decoration: none; border-radius: 6px; margin: 1rem 0; }
    .footer { font-size: 0.9rem; color: #666; margin-top: 2rem; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1 style="font-weight: 200; letter-spacing: 2px;">MAYA CHEN</h1>
    </div>
    
    <h2>Welcome to my art journey!</h2>
    
    <p>Thank you for subscribing to my art updates. I'm thrilled to have you along for this creative journey.</p>
    
    <p>You'll receive occasional updates about:</p>
    <ul>
      <li>New artwork releases</li>
      <li>Exhibition announcements</li>
      <li>Behind-the-scenes studio insights</li>
      <li>Creative process reflections</li>
    </ul>
    
    <p style="text-align: center;">
      <a href="https://your-domain.com" class="button">Visit My Portfolio</a>
    </p>
    
    <div class="footer">
      <p>I respect your inbox and will only send meaningful updates. You can unsubscribe anytime by replying to any email.</p>
      <p>With creative gratitude,<br>Maya Chen</p>
    </div>
  </div>
</body>
</html>`;
}

function getSuccessPage() {
  return `
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>Subscription Confirmed - Maya Chen</title>
  <style>
    body { font-family: 'Inter', Arial, sans-serif; line-height: 1.6; color: #2a2a2a; max-width: 600px; margin: 0 auto; padding: 2rem; text-align: center; }
    h1 { font-weight: 200; letter-spacing: 2px; color: #667eea; }
    .button { display: inline-block; padding: 1rem 2rem; background: #667eea; color: white; text-decoration: none; border-radius: 6px; margin: 2rem 0; }
  </style>
</head>
<body>
  <h1>MAYA CHEN</h1>
  <h2>✓ Subscription Confirmed!</h2>
  <p>Thank you for confirming your email address. You're now subscribed to my art updates and will receive a welcome email shortly.</p>
  <p>I'm excited to share my creative journey with you!</p>
  <a href="https://your-domain.com" class="button">Return to Portfolio</a>
</body>
</html>`;
}

function getErrorPage(error) {
  return `
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>Verification Error - Maya Chen</title>
  <style>
    body { font-family: 'Inter', Arial, sans-serif; line-height: 1.6; color: #2a2a2a; max-width: 600px; margin: 0 auto; padding: 2rem; text-align: center; }
    h1 { font-weight: 200; letter-spacing: 2px; color: #667eea; }
    .error { color: #721c24; }
    .button { display: inline-block; padding: 1rem 2rem; background: #667eea; color: white; text-decoration: none; border-radius: 6px; margin: 2rem 0; }
  </style>
</head>
<body>
  <h1>MAYA CHEN</h1>
  <h2 class="error">Verification Failed</h2>
  <p>${error}</p>
  <p>Please try subscribing again.</p>
  <a href="https://your-domain.com" class="button">Return to Portfolio</a>
</body>
</html>`;
}
EOF

echo "⚙️ Updating wrangler configuration..."

# Update wrangler.jsonc to include worker configuration
cat > wrangler.toml << 'EOF'
name = "artist-portfolio-worker"
main = "worker.js"
compatibility_date = "2024-01-01"

[env.production.vars]
MAILGUN_DOMAIN = "yourdomain.com"

[env.production.secrets]
# Set these with: wrangler secret put MAILGUN_API_KEY
# MAILGUN_API_KEY = "your-mailgun-api-key"

[[env.production.d1_databases]]
binding = "DB"
database_name = "artist-portfolio-db"
database_id = "your-d1-database-id"
EOF

echo "📁 Creating sample artwork placeholder..."

# Create placeholder artwork files
touch static/artwork/sample-drawing.jpg
touch static/artwork/sample-video.mp4
touch static/artwork/sample-animation.gif

echo "📝 Creating setup instructions..."

# Create SETUP.md with instructions
cat > SETUP.md << 'EOF'
# Artist Portfolio Setup Instructions

## What This Script Created

This script has set up a complete artist portfolio website with:

### Frontend (SvelteKit):
- ✅ Updated layout with navigation
- ✅ Hero section with gradient background
- ✅ Gallery component with filtering
- ✅ Email signup form
- ✅ Responsive design
- ✅ Global styles

### Backend (Cloudflare Worker):
- ✅ Email subscription handling
- ✅ Email verification system
- ✅ Mailgun integration
- ✅ D1 database operations

## Next Steps

### 1. Install Dependencies
```bash
npm install
```

### 2. Set Up Cloudflare D1 Database
```bash
# Create the database
npx wrangler d1 create artist-portfolio-db

# Update wrangler.toml with the database ID that gets returned

# Create the database schema
npx wrangler d1 execute artist-portfolio-db --command "CREATE TABLE subscribers (id INTEGER PRIMARY KEY AUTOINCREMENT, email TEXT NOT NULL, type TEXT NOT NULL, confirmation_token TEXT, token_expires_at TEXT, confirmed BOOLEAN DEFAULT false, confirmed_at TEXT, created_at TEXT NOT NULL, UNIQUE(email, type));"
```

### 3. Set Up Mailgun
1. Sign up at https://mailgun.com
2. Add your domain and verify it
3. Create a mailing list called `art-updates@yourdomain.com`
4. Get your API key from the dashboard

### 4. Configure Environment Variables
```bash
# Set your Mailgun API key (replace with actual key)
npx wrangler secret put MAILGUN_API_KEY

# Update wrangler.toml with your domain
```

### 5. Update Configuration Files

#### In `wrangler.toml`:
- Replace `yourdomain.com` with your actual domain
- Replace `your-d1-database-id` with the ID from step 2

#### In `src/lib/components/Gallery.svelte`:
- Replace `your-r2-bucket.r2.cloudflarestorage.com` with your R2 bucket URL
- Replace `your-account-hash` with your Cloudflare Images account hash

#### In `src/routes/api/subscribe/+server.js`:
- Replace `your-worker.your-subdomain.workers.dev` with your worker URL

#### In `worker.js`:
- Replace `your-worker-domain.workers.dev` with your worker URL
- Replace `your-domain.com` with your actual domain

### 6. Upload Your Artwork
1. Upload your artwork files to Cloudflare R2
2. Upload thumbnails to Cloudflare Images
3. Update the artwork data in `src/lib/components/Gallery.svelte`

### 7. Deploy

#### Deploy the Worker:
```bash
npx wrangler publish
```

#### Deploy the SvelteKit App:
```bash
npm run build
# Then deploy the 'build' folder to your hosting provider
```

### 8. Test
1. Visit your deployed site
2. Try subscribing with your email
3. Check that you receive verification and welcome emails
4. Test the gallery filtering and artwork display

## File Structure Created
```
your-project/
├── src/
│   ├── app.css                           # Global styles
│   ├── routes/
│   │   ├── +layout.svelte               # Updated layout
│   │   ├── +page.svelte                 # Updated home page
│   │   └── api/subscribe/+server.js     # Email subscription API
│   └── lib/components/
│       ├── Gallery.svelte               # Artwork gallery
│       ├── ArtPiece.svelte             # Individual artwork component
│       └── EmailSignup.svelte          # Email signup form
├── static/artwork/                      # Your artwork files go here
├── worker.js                           # Cloudflare Worker
├── wrangler.toml                       # Worker configuration
└── SETUP.md                            # This file
```

## Customization

- Update colors in the CSS custom properties
- Replace "MAYA CHEN" with your actual name throughout the files
- Modify the about section text
- Update the hero section content
- Add your actual artwork data to the Gallery component

## Support

If you encounter issues:
1. Check the Cloudflare Workers logs: `npx wrangler tail`
2. Check the browser console for frontend errors
3. Verify all URLs and configurations are updated
4. Test email functionality with a valid email address

Good luck with your artist portfolio! 🎨
EOF

echo ""
echo "🎉 Artist Portfolio Setup Complete!"
echo ""
echo "📋 Summary of what was created:"
echo "   ✅ Global styles (src/app.css)"
echo "   ✅ Updated layout with navigation"
echo "   ✅ Hero section with gradient background" 
echo "   ✅ Gallery components with filtering"
echo "   ✅ Email signup with verification"
echo "   ✅ Cloudflare Worker for email handling"
echo "   ✅ API routes for subscriptions"
echo "   ✅ Configuration files"
echo ""
echo "📖 Next Steps:"
echo "   1. Read SETUP.md for detailed configuration instructions"
echo "   2. Run 'npm install' to install dependencies"
echo "   3. Set up your D1 database and Mailgun account"
echo "   4. Update configuration URLs and credentials"
echo "   5. Add your artwork files and data"
echo "   6. Deploy and test!"
echo ""
echo "🚀 Ready to showcase your art to the world!"