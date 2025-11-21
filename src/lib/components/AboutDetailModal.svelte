
<script>
  import { browser, run, state, derived, effect } from 'svelte';  

  // Props with defaults using $props rune
  let { open = false, onClose, dailyVideo } = $props();

  // Handle Escape key close - use effect with cleanup function
  function handleKeydown(e) {
    if (e.key === 'Escape') {
      onClose();
    }
  }

  // Derived state using $derived rune
  const videoSrc = derived(
    dailyVideo,
    v => v 
      ? `https://customer-9kroafxwku5qm6fx.cloudflarestream.com/${v.video_id}/iframe?autoplay=true&controls=true&muted=false`
      : `https://customer-9kroafxwku5qm6fx.cloudflarestream.com/fd7341d70b1a5517bb56a569d2a0cb38/iframe?autoplay=true&controls=true&muted=false`
  );

  const videoTitle = derived(
    dailyVideo,
    v => v ? `About Antoine - ${v.title}` : 'About Antoine - Creative Journey'
  );

  // $effect to manage body overflow and keyboard events reactively
  effect(() => {
    if (!browser) return;

    if (open) {
      document.body.style.overflow = 'hidden';
      document.addEventListener('keydown', handleKeydown);
      return () => {
        document.body.style.overflow = '';
        document.removeEventListener('keydown', handleKeydown);
      };
    } else {
      document.body.style.overflow = '';
    }
  });
</script>

{#if open}
  <div class="modal-overlay" on:click={onClose}>
    <div class="modal-content" on:click|stopPropagation>
      <button class="close-btn" on:click={onClose} aria-label="Close about modal">
        <span class="close-icon">×</span>
      </button>

      <div class="content-wrapper">
        <!-- Video Section -->
        <section class="video-section">
          {#if dailyVideo}
            <div class="daily-feature-badge">
              <span class="badge-icon">🎨</span>
              <span class="badge-text">Daily Feature: {dailyVideo.title}</span>
              {#if dailyVideo.year}
                <span class="badge-year">({dailyVideo.year})</span>
              {/if}
            </div>
          {/if}

          <div class="modal-video-wrapper">
            <iframe
              src={$videoSrc}
              allow="accelerometer; gyroscope; autoplay; encrypted-media; picture-in-picture"
              allowfullscreen
              loading="lazy"
              title={$videoTitle}
            ></iframe>
          </div>

          {#if dailyVideo && dailyVideo.description}
            <div class="video-description">
              <p>{dailyVideo.description}</p>
            </div>
          {/if}
        </section>
        
        <!-- Extended Bio -->
        <section class="bio-section">
          <h2>About Antoine Patraldo</h2>
          
          <div class="bio-content">
            <p>
              Antoine Patraldo is a contemporary artist exploring the intersection of 
              digital and traditional mediums. His work combines animated sketches, 
              interactive storytelling, and mixed media to create immersive experiences 
              that invite viewers to engage with art in new ways.
            </p>
            
            <div class="bio-highlights">
              <div class="highlight-item">
                <h3>🎨 Artistic Approach</h3>
                <p>Blending sketchbook intimacy with digital innovation, each piece tells a story that unfolds through interaction and discovery.</p>
              </div>
              
              <div class="highlight-item">
                <h3>💡 Creative Philosophy</h3>
                <p>Believing that art should be accessible and engaging, Antoine creates works that invite participation and personal interpretation.</p>
              </div>
              
              <div class="highlight-item">
                <h3>🌍 Digital Storytelling</h3>
                <p>Using technology as a canvas to explore narratives that bridge the physical and digital realms.</p>
              </div>
            </div>

            <h3>Education & Background</h3>
            <ul>
              <li>Self-taught artist with over a decade of digital experimentation</li>
              <li>Background in interactive design and creative technology</li>
              <li>Continuous exploration of new mediums and techniques</li>
            </ul>
            
            <h3>Featured Exhibitions & Projects</h3>
            <ul>
              <li>2024 - "Interactive Sketchbook" - Digital Exhibition</li>
              <li>2023 - "Animated Narratives" - Online Gallery</li>
              <li>2022 - "Digital Impressionism" - Virtual Showcase</li>
            </ul>
            
            <h3>Tools & Techniques</h3>
            <ul>
              <li>Digital illustration and animation</li>
              <li>Interactive web experiences</li>
              <li>Mixed media combining traditional and digital elements</li>
              <li>Real-time creative coding</li>
            </ul>
          </div>
        </section>
        
        <!-- Contact/Social -->
        <section class="contact-section">
          <h3>Get in Touch</h3>
          <p>Interested in collaborations, commissions, or just want to talk about art?</p>
          
          <div class="social-links">
            <a href="mailto:antoine@patraldo.com" class="social-link email">
              <span class="social-icon">✉️</span>
              <span class="social-text">Email</span>
            </a>
            <a href="https://instagram.com/antoine.patraldo" target="_blank" rel="noopener noreferrer" class="social-link instagram">
              <span class="social-icon">📷</span>
              <span class="social-text">Instagram</span>
            </a>
          </div>
          
          <div class="newsletter-cta">
            <h4>Stay Updated</h4>
            <p>Receive new stories, artwork releases, and exhibition announcements.</p>
            <a href="/#contact" class="newsletter-btn" onclick={onClose}>
              Subscribe to Updates
            </a>
          </div>
        </section>
      </div>
    </div>
  </div>
{/if}

<style>
  .modal-overlay {
    position: fixed;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    background: rgba(0, 0, 0, 0.9);
    z-index: 9999;
    display: flex;
    align-items: center;
    justify-content: center;
    padding: 2rem;
    overflow-y: auto;
    animation: fadeIn 0.3s ease;
  }
  
  .modal-content {
    background: white;
    border-radius: 16px;
    max-width: 1200px;
    width: 100%;
    max-height: 90vh;
    overflow-y: auto;
    position: relative;
    animation: slideUp 0.4s ease;
    box-shadow: 0 20px 60px rgba(0,0,0,0.3);
  }
  
  .close-btn {
    position: sticky;
    top: 1rem;
    right: 1rem;
    float: right;
    background: rgba(0, 0, 0, 0.8);
    color: white;
    border: none;
    width: 48px;
    height: 48px;
    border-radius: 50%;
    font-size: 1.5rem;
    cursor: pointer;
    display: flex;
    align-items: center;
    justify-content: center;
    z-index: 10;
    transition: all 0.2s ease;
    backdrop-filter: blur(10px);
  }
  
  .close-btn:hover {
    background: rgba(0, 0, 0, 0.9);
    transform: scale(1.1);
  }
  
  .content-wrapper {
    padding: 3rem;
  }
  
  /* Video Section */
  .video-section {
    margin-bottom: 3rem;
  }
  
  .daily-feature-badge {
    background: linear-gradient(135deg, #2c5e3d, #4a7c59);
    color: white;
    padding: 0.75rem 1.5rem;
    border-radius: 25px;
    font-size: 0.9rem;
    font-weight: 500;
    display: inline-flex;
    align-items: center;
    gap: 0.5rem;
    margin-bottom: 1.5rem;
    box-shadow: 0 4px 12px rgba(44, 94, 61, 0.3);
  }
  
  .badge-icon {
    font-size: 1.1rem;
  }
  
  .badge-text {
    font-weight: 600;
  }
  
  .badge-year {
    opacity: 0.9;
    font-size: 0.8rem;
  }
  
  .modal-video-wrapper {
    position: relative;
    width: 100%;
    padding-top: 56.25%; /* 16:9 aspect ratio */
    border-radius: 12px;
    overflow: hidden;
    box-shadow: 0 8px 24px rgba(0,0,0,0.15);
    background: #000;
  }
  
  .modal-video-wrapper iframe {
    position: absolute;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    border: none;
  }
  
  .video-description {
    margin-top: 1rem;
    padding: 1rem;
    background: #f8f8f8;
    border-radius: 8px;
    border-left: 4px solid #2c5e3d;
  }
  
  .video-description p {
    margin: 0;
    font-style: italic;
    color: #666;
    line-height: 1.5;
  }
  
  /* Bio Section */
  .bio-section {
    margin-bottom: 3rem;
  }
  
  .bio-section h2 {
    font-size: 2.5rem;
    font-weight: 300;
    color: #1a1a1a;
    margin-bottom: 2rem;
    font-family: 'Georgia', serif;
    border-bottom: 2px solid #f0f0f0;
    padding-bottom: 1rem;
  }
  
  .bio-section h3 {
    font-size: 1.4rem;
    font-weight: 600;
    color: #2c5e3d;
    margin: 2.5rem 0 1rem;
    border-left: 3px solid #d4c9a8;
    padding-left: 1rem;
  }
  
  .bio-content p {
    line-height: 1.8;
    color: #333;
    margin-bottom: 1.5rem;
    font-size: 1.05rem;
  }
  
  .bio-highlights {
    display: grid;
    gap: 1.5rem;
    margin: 2rem 0;
  }
  
  .highlight-item {
    background: linear-gradient(135deg, #f8f7f4, #f0ede8);
    padding: 1.5rem;
    border-radius: 8px;
    border-left: 4px solid #d4c9a8;
  }
  
  .highlight-item h3 {
    margin: 0 0 0.5rem 0 !important;
    border: none !important;
    padding: 0 !important;
    font-size: 1.2rem;
  }
  
  .highlight-item p {
    margin: 0;
    color: #666;
  }
  
  .bio-content ul {
    list-style: none;
    padding: 0;
  }
  
  .bio-content li {
    padding: 0.75rem 0;
    border-bottom: 1px solid #f0f0f0;
    position: relative;
    padding-left: 1.5rem;
  }
  
  .bio-content li:before {
    content: "•";
    color: #2c5e3d;
    position: absolute;
    left: 0;
    font-weight: bold;
  }
  
  /* Contact Section */
  .contact-section {
    background: linear-gradient(135deg, #f8f7f4, #f0ede8);
    padding: 2.5rem;
    border-radius: 12px;
    border: 1px solid #e8e4dc;
  }
  
  .contact-section h3 {
    font-size: 1.5rem;
    margin-bottom: 1rem;
    color: #2c5e3d;
  }
  
  .contact-section p {
    color: #666;
    margin-bottom: 1.5rem;
  }
  
  .social-links {
    display: flex;
    gap: 1rem;
    flex-wrap: wrap;
    margin-bottom: 2rem;
  }
  
  .social-link {
    padding: 1rem 1.5rem;
    background: white;
    color: #1a1a1a;
    text-decoration: none;
    border-radius: 8px;
    transition: all 0.3s ease;
    display: flex;
    align-items: center;
    gap: 0.5rem;
    border: 2px solid transparent;
    box-shadow: 0 2px 8px rgba(0,0,0,0.1);
  }
  
  .social-link:hover {
    transform: translateY(-2px);
    box-shadow: 0 4px 16px rgba(0,0,0,0.15);
    border-color: #2c5e3d;
  }
  
  .social-icon {
    font-size: 1.2rem;
  }
  
  .social-text {
    font-weight: 500;
  }
  
  .newsletter-cta {
    background: white;
    padding: 1.5rem;
    border-radius: 8px;
    text-align: center;
    border: 2px dashed #d4c9a8;
  }
  
  .newsletter-cta h4 {
    margin: 0 0 0.5rem 0;
    color: #2c5e3d;
  }
  
  .newsletter-cta p {
    margin: 0 0 1rem 0;
    font-size: 0.9rem;
  }
  
  .newsletter-btn {
    display: inline-block;
    padding: 0.75rem 1.5rem;
    background: #2c5e3d;
    color: white;
    text-decoration: none;
    border-radius: 6px;
    font-weight: 500;
    transition: all 0.3s ease;
  }
  
  .newsletter-btn:hover {
    background: #234a31;
    transform: translateY(-1px);
  }
  
  /* Animations */
  @keyframes fadeIn {
    from { opacity: 0; }
    to { opacity: 1; }
  }
  
  @keyframes slideUp {
    from { 
      opacity: 0;
      transform: translateY(20px);
    }
    to { 
      opacity: 1;
      transform: translateY(0);
    }
  }
  
  /* Responsive Design */
  @media (max-width: 768px) {
    .modal-overlay {
      padding: 0;
    }
    
    .modal-content {
      max-height: 100vh;
      border-radius: 0;
    }
    
    .content-wrapper {
      padding: 1.5rem;
    }
    
    .bio-section h2 {
      font-size: 2rem;
    }
    
    .bio-highlights {
      grid-template-columns: 1fr;
    }
    
    .social-links {
      flex-direction: column;
    }
    
    .daily-feature-badge {
      font-size: 0.8rem;
      padding: 0.5rem 1rem;
    }
  }
  
  @media (max-width: 480px) {
    .content-wrapper {
      padding: 1rem;
    }
    
    .bio-section h2 {
      font-size: 1.75rem;
    }
    
    .contact-section {
      padding: 1.5rem;
    }
  }
</style>
