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
    <h1>Antoine Patraldo</h1>
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
    <p>&copy; 2025 Antoine Patraldo. All rights reserved.</p>
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
          return new Response('Invalid verification token', { status: 400 });
        }
        const subscriber = await env.DB.prepare(`
          SELECT email, token_expires_at FROM subscribers 
          WHERE token = ? AND type = 'art-updates'
        `).bind(token).first();

        if (!subscriber) {
          return new Response('Invalid verification token', { status: 400 });
        }

        if (new Date(subscriber.token_expires_at) < new Date()) {
          return new Response('Verification token expired', { status: 400 });
        }

        // Update subscriber as confirmed
        await env.DB.prepare(`
          UPDATE subscribers 
          SET confirmed = 1, token = NULL, token_expires_at = NULL 
          WHERE email = ? AND type = 'art-updates'
        `).bind(subscriber.email).run();

        // Redirect to success page
        return Response.redirect('https://your-domain.com/subscription-confirmed', 302);
      } catch (error) {
        console.error('Verification error:', error);
        return new Response('Verification failed', { status: 500 });
      }
    }

    // Handle sending announcements
    if (request.method === 'POST' && url.pathname === '/send-announcement') {
      try {
        // Basic auth check - replace with proper auth in production
        const authHeader = request.headers.get('Authorization');
        if (authHeader !== `Bearer ${env.AUTH_TOKEN}`) {
          return jsonResponse({ message: 'Unauthorized' }, 401);
        }

        const { subject, content } = await request.json();
        if (!subject || !content) {
          return jsonResponse({ message: 'Subject and content are required' }, 400);
        }

        // Get all confirmed subscribers
        const subscribers = await env.DB.prepare(`
          SELECT email FROM subscribers 
          WHERE confirmed = 1 AND type = 'art-updates'
        `).all();

        if (subscribers.results.length === 0) {
          return jsonResponse({ message: 'No subscribers found' }, 200);
        }

        // Send email to each subscriber
        for (const subscriber of subscribers.results) {
          await sendEmail(subscriber.email, subject, content, env);
        }

        return jsonResponse({ 
          message: `Announcement sent to ${subscribers.results.length} subscribers` 
        }, 200);
      } catch (error) {
        console.error('Announcement error:', error);
        return jsonResponse({ message: 'Failed to send announcement' }, 500);
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
  const token = generateToken();
  const expiresAt = new Date(Date.now() + 24 * 60 * 60 * 1000); // 24 hours
  
  // Store subscriber with token
  await env.DB.prepare(`
    INSERT OR REPLACE INTO subscribers (email, type, token, token_expires_at, confirmed)
    VALUES (?, 'art-updates', ?, ?, 0)
  `).bind(email, token, expiresAt.toISOString()).run();

  const verificationUrl = `https://your-worker.your-subdomain.workers.dev/verify?token=${token}`;
  
  const htmlContent = `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <title>Verify your subscription</title>
      <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px; }
        .container { border: 1px solid #ddd; border-radius: 5px; padding: 20px; }
        .button { display: inline-block; background: #667eea; color: white; padding: 10px 20px; text-decoration: none; border-radius: 4px; }
        .footer { margin-top: 30px; font-size: 12px; color: #888; }
      </style>
    </head>
    <body>
      <div class="container">
        <h2>Verify Your Subscription</h2>
        <p>Thank you for subscribing to Antoine Patraldo's art updates! Please click the button below to verify your email address:</p>
        <p style="text-align: center; margin: 30px 0;">
          <a href="${verificationUrl}" class="button">Verify Email</a>
        </p>
        <p>If the button doesn't work, you can copy and paste the following link into your browser:</p>
        <p>${verificationUrl}</p>
        <p>This link will expire in 24 hours.</p>
        <div class="footer">
          <p>© 2025 Antoine Patraldo. All rights reserved.</p>
          <p>If you didn't subscribe to these updates, you can ignore this email.</p>
        </div>
      </div>
    </body>
    </html>
  `;

  await sendEmail(email, 'Verify Your Subscription to Antoine Patraldo Art Updates', htmlContent, env);
}

async function sendEmail(to, subject, htmlContent, env) {
  // Using Resend for email delivery - update with your preferred service
  const response = await fetch('https://api.resend.com/emails', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${env.RESEND_API_KEY}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      from: 'art@mayachen.com',
      to: [to],
      subject: subject,
      html: htmlContent
    })
  });

  if (!response.ok) {
    const error = await response.text();
    throw new Error(`Email sending failed: ${error}`);
  }

  return await response.json();
}

function generateToken() {
  const array = new Uint8Array(32);
  crypto.getRandomValues(array);
  return Array.from(array, byte => byte.toString(16).padStart(2, '0')).join('');
}
EOF

echo "📝 Creating subscription confirmation page..."
# Create src/routes/subscription-confirmed/+page.svelte
cat > src/routes/subscription-confirmed/+page.svelte << 'EOF'
<svelte:head>
  <title>Subscription Confirmed | Antoine Patraldo</title>
  <meta name="description" content="Your subscription to Antoine Patraldo's art updates has been confirmed." />
</svelte:head>
<section class="confirmation">
  <div class="container">
    <div class="confirmation-content">
      <h2>Subscription Confirmed!</h2>
      <div class="icon">✓</div>
      <p>Thank you for subscribing to updates about my work.</p>
      <p>You'll receive occasional emails about new artwork, exhibitions, and studio insights.</p>
      <a href="/" class="button">Return to Gallery</a>
    </div>
  </div>
</section>
<style>
  .confirmation {
    min-height: 70vh;
    display: flex;
    align-items: center;
    justify-content: center;
    padding: 2rem 0;
  }
  .container {
    max-width: 600px;
    margin: 0 auto;
    padding: 0 2rem;
  }
  .confirmation-content {
    background: white;
    border-radius: 8px;
    padding: 3rem;
    text-align: center;
    box-shadow: 0 4px 20px rgba(0, 0, 0, 0.08);
  }
  h2 {
    font-size: 2.5rem;
    font-weight: 300;
    margin-bottom: 1.5rem;
    color: #2a2a2a;
  }
  .icon {
    width: 80px;
    height: 80px;
    background: #667eea;
    color: white;
    border-radius: 50%;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 3rem;
    margin: 0 auto 2rem;
  }
  p {
    font-size: 1.1rem;
    color: #555;
    margin-bottom: 1.5rem;
  }
  .button {
    display: inline-block;
    padding: 1rem 2rem;
    background: #667eea;
    color: white;
    text-decoration: none;
    border-radius: 6px;
    font-weight: 500;
    transition: background-color 0.3s;
  }
  .button:hover {
    background: #5a6fd8;
  }
  @media (max-width: 768px) {
    .container {
      padding: 0 1rem;
    }
    
    .confirmation-content {
      padding: 2rem;
    }
    
    h2 {
      font-size: 2rem;
    }
  }
</style>
EOF

echo "🗄️ Creating database schema..."
# Create db/schema.sql
mkdir -p db
cat > db/schema.sql << 'EOF'
-- Database schema for artist portfolio
-- Create subscribers table
CREATE TABLE IF NOT EXISTS subscribers (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  email TEXT NOT NULL UNIQUE,
  type TEXT NOT NULL DEFAULT 'art-updates',
  token TEXT,
  token_expires_at TEXT,
  confirmed INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_subscribers_email ON subscribers(email);
CREATE INDEX IF NOT EXISTS idx_subscribers_token ON subscribers(token);
CREATE INDEX IF NOT EXISTS idx_subscribers_confirmed ON subscribers(confirmed);
EOF

echo "📄 Creating README with setup instructions..."
# Create README.md
cat > README.md << 'EOF'
# Antoine Patraldo - Artist Portfolio

This is a portfolio website for visual artist Antoine Patraldo, built with SvelteKit and deployed on Cloudflare Pages.

## Features

- Gallery with support for still images, videos, and animated GIFs
- Email subscription system with verification
- Responsive design for all devices
- Optimized for performance with Cloudflare's global CDN

## Setup Instructions

### Prerequisites

- Node.js (v16 or higher)
- Cloudflare account
- Resend account (for email delivery)

### Installation

1. Clone this repository and navigate to the project directory
2. Install dependencies:
   \`\`\`bash
   npm install
   \`\`\`

### Database Setup

1. Create a D1 database in your Cloudflare dashboard
2. Execute the schema from \`db/schema.sql\`:
   \`\`\`bash
   npx wrangler d1 execute DB_NAME --file=./db/schema.sql
   \`\`\`
3. Update \`wrangler.jsonc\` with your database binding

### Email Setup

1. Sign up for Resend (or another email service)
2. Add your API key as a secret to your Worker:
   \`\`\`bash
   npx wrangler secret put RESEND_API_KEY
   \`\`\`
3. Set an auth token for sending announcements:
   \`\`\`bash
   npx wrangler secret put AUTH_TOKEN
   \`\`\`

### Image Storage

1. Create an R2 bucket for storing artwork
2. Set up Cloudflare Images for optimized delivery
3. Update the \`CF_IMAGES_BASE\` variable in \`src/lib/components/Gallery.svelte\`
4. Update the artwork URLs in the same file

### Deployment

1. Deploy your Worker:
   \`\`\`bash
   npx wrangler deploy
   \`\`\`
2. Deploy your SvelteKit site to Cloudflare Pages:
   \`\`\`bash
   npm run build
   # Upload the contents of the .svelte-kit/output directory to Cloudflare Pages
   \`\`\`

## Customization

### Adding Artwork

To add new artwork, update the \`artworks\` array in \`src/lib/components/Gallery.svelte\` with:
- Title
- Type (still, animation, gif)
- R2 URL for the full media
- Thumbnail ID for Cloudflare Images
- Description
- Year

### Styling

Global styles are in \`src/app.css\`. Component-specific styles are included in each Svelte component.

## License

© 2025 Antoine Patraldo. All rights reserved.
EOF

echo "✅ Artist portfolio setup complete!"
echo ""
echo "Next steps:"
echo "1. Update artwork URLs and Cloudflare Images base in src/lib/components/Gallery.svelte"
echo "2. Set up D1 database and execute db/schema.sql"
echo "3. Configure email service secrets"
echo "4. Deploy your Worker and SvelteKit site"
echo ""
echo "Enjoy your new artist portfolio! 🎨"
