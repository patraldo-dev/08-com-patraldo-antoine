<script>
  // Props with defaults using $props rune
  let { open = false, onClose, dailyVideo } = $props();

  // Handle Escape key close
  function handleKeydown(e) {
    if (e.key === 'Escape') {
      onClose();
    }
  }

  // Handle content click to stop propagation
  function handleContentClick(e) {
    e.stopPropagation();
  }

  // Use let declarations for derived values with reactive assignments
  let videoSrc = $derived(dailyVideo 
    ? `https://customer-9kroafxwku5qm6fx.cloudflarestream.com/${dailyVideo.video_id}/iframe?autoplay=true&controls=true&muted=false`
    : `https://customer-9kroafxwku5qm6fx.cloudflarestream.com/fd7341d70b1a5517bb56a569d2a0cb38/iframe?autoplay=true&controls=true&muted=false`
  );

  let videoTitle = $derived(dailyVideo 
    ? `About Antoine - ${dailyVideo.title}` 
    : 'About Antoine - Creative Journey'
  );

  // $effect to manage body overflow and keyboard events reactively
  $effect(() => {
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
  <div class="modal-overlay" onclick={onClose}>
    <div class="modal-content" onclick={handleContentClick}>
      <button class="close-btn" onclick={onClose} aria-label="Close about modal">
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
              src={videoSrc}
              allow="accelerometer; gyroscope; autoplay; encrypted-media; picture-in-picture"
              allowfullscreen
              loading="lazy"
              title={videoTitle}
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
          <h2>About Antoine</h2>
          <p>
            Welcome! I'm Antoine, a passionate creative with a love for visual storytelling 
            and digital innovation. My journey spans across various creative disciplines...
          </p>
          
          <h3>Creative Philosophy</h3>
          <p>
            I believe in the power of visual storytelling to connect, inspire, and transform. 
            Every project is an opportunity to create something meaningful...
          </p>

          <h3>Skills & Expertise</h3>
          <ul>
            <li>Visual Design & Art Direction</li>
            <li>Digital Content Creation</li>
            <li>Creative Strategy</li>
            <li>Multimedia Production</li>
          </ul>
        </section>

        <!-- Contact/Social -->
        <section class="contact-section">
          <h3>Let's Connect</h3>
          <p>
            I'm always interested in new creative opportunities and collaborations. 
            Feel free to reach out if you'd like to work together or just say hello!
          </p>
          
          <div class="social-links">
            <a href="https://instagram.com/yourprofile" target="_blank" rel="noopener">Instagram</a>
            <a href="https://twitter.com/yourprofile" target="_blank" rel="noopener">Twitter</a>
            <a href="https://linkedin.com/in/yourprofile" target="_blank" rel="noopener">LinkedIn</a>
            <a href="mailto:hello@example.com">Email</a>
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
    width: 100%;
    height: 100%;
    background: rgba(0, 0, 0, 0.7);
    display: flex;
    align-items: center;
    justify-content: center;
    z-index: 1000;
  }

  .modal-content {
    background: white;
    border-radius: 12px;
    max-width: 90vw;
    max-height: 90vh;
    overflow-y: auto;
    position: relative;
    padding: 2rem;
  }

  .close-btn {
    position: absolute;
    top: 1rem;
    right: 1rem;
    background: none;
    border: none;
    font-size: 2rem;
    cursor: pointer;
    padding: 0.5rem;
    line-height: 1;
  }

  .content-wrapper {
    display: flex;
    flex-direction: column;
    gap: 2rem;
  }

  .daily-feature-badge {
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    color: white;
    padding: 0.5rem 1rem;
    border-radius: 8px;
    display: flex;
    align-items: center;
    gap: 0.5rem;
    margin-bottom: 1rem;
  }

  .modal-video-wrapper {
    position: relative;
    width: 100%;
    height: 0;
    padding-bottom: 56.25%; /* 16:9 aspect ratio */
  }

  .modal-video-wrapper iframe {
    position: absolute;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    border: none;
    border-radius: 8px;
  }

  .video-description {
    margin-top: 1rem;
    padding: 1rem;
    background: #f8f9fa;
    border-radius: 8px;
  }

  .bio-section h2,
  .bio-section h3,
  .contact-section h3 {
    margin-bottom: 1rem;
    color: #333;
  }

  .bio-section p,
  .contact-section p {
    line-height: 1.6;
    margin-bottom: 1rem;
  }

  .bio-section ul {
    list-style-type: none;
    padding-left: 1rem;
  }

  .bio-section li {
    margin-bottom: 0.5rem;
    position: relative;
  }

  .bio-section li:before {
    content: "•";
    color: #667eea;
    font-weight: bold;
    display: inline-block;
    width: 1em;
    margin-left: -1em;
  }

  .social-links {
    display: flex;
    gap: 1rem;
    flex-wrap: wrap;
  }

  .social-links a {
    color: #667eea;
    text-decoration: none;
    padding: 0.5rem 1rem;
    border: 2px solid #667eea;
    border-radius: 6px;
    transition: all 0.3s ease;
  }

  .social-links a:hover {
    background: #667eea;
    color: white;
  }

  @media (max-width: 768px) {
    .modal-content {
      padding: 1rem;
      max-width: 95vw;
    }
    
    .content-wrapper {
      gap: 1.5rem;
    }
    
    .social-links {
      flex-direction: column;
    }
  }
</style>
