<script>
  import { t } from '$lib/i18n';
  
  let { open = false, onClose, dailyVideo } = $props();
  
  function handleKeydown(e) {
    if (e.key === 'Escape') {
      onClose();
    }
  }
  
  function handleContentClick(e) {
    e.stopPropagation();
  }
  
  let videoSrc = $derived(dailyVideo 
    ? `https://customer-9kroafxwku5qm6fx.cloudflarestream.com/${dailyVideo.video_id}/iframe?autoplay=true&controls=true&muted=false`
    : `https://customer-9kroafxwku5qm6fx.cloudflarestream.com/fd7341d70b1a5517bb56a569d2a0cb38/iframe?autoplay=true&controls=true&muted=false`
  );
  
  let videoTitle = $derived(dailyVideo 
    ? `${$t('about.modal.videoPrefix')} - ${dailyVideo.title}` 
    : $t('about.modal.defaultVideoTitle')
  );
  
  $effect(() => {
    if (open) {
      const originalOverflow = document.body.style.overflow;
      document.body.style.overflow = 'hidden';
      document.addEventListener('keydown', handleKeydown);

      return () => {
        document.body.style.overflow = originalOverflow || '';
        document.body.style.removeProperty('overflow');
        document.removeEventListener('keydown', handleKeydown);
      };
    }
  });
</script>

{#if open}
  <div class="modal-overlay" onclick={onClose}>
    <div class="modal-content" onclick={handleContentClick}>
      <button class="close-btn" onclick={onClose} aria-label={$t('about.modal.closeLabel')}>
        <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <line x1="18" y1="6" x2="6" y2="18"></line>
          <line x1="6" y1="6" x2="18" y2="18"></line>
        </svg>
      </button>
      
      <div class="content-wrapper">
        <!-- Video Section -->
        <section class="video-section">
          {#if dailyVideo}
            <div class="daily-feature-badge">
              <span class="badge-icon">✨</span>
              <div class="badge-content">
                <span class="badge-label">{$t('about.modal.todaysFeatured')}</span>
                <span class="badge-title">{dailyVideo.title}</span>
              </div>
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

        <!-- The Project -->
        <section class="bio-section">
          <h2>{$t('about.modal.projectTitle')}</h2>
          <p class="intro">{$t('about.modal.projectIntro')}</p>
          
          <div class="collaboration-grid">
            <div class="collab-card">
              <div class="card-icon">🎨</div>
              <h3>{$t('about.modal.artistTitle')}</h3>
              <p>{$t('about.modal.artistDescription')}</p>
            </div>
            
            <div class="collab-card">
              <div class="card-icon">⚙️</div>
              <h3>{$t('about.modal.studioTitle')}</h3>
              <p>{$t('about.modal.studioDescription')}</p>
            </div>
          </div>

          <h3>{$t('about.modal.processTitle')}</h3>
          <p>{$t('about.modal.processDescription')}</p>
          
          <div class="tech-stack">
            <h4>{$t('about.modal.toolsTitle')}</h4>
            <div class="tech-tags">
              <span class="tech-tag">Meta animated-drawings</span>
              <span class="tech-tag">Wan Video</span>
              <span class="tech-tag">FFMPEG</span>
              <span class="tech-tag">Linux CLI</span>
              <span class="tech-tag">{$t('about.modal.coloredPencils')}</span>
            </div>
          </div>
        </section>

        <!-- Connect -->
        <section class="contact-section">
          <h3>{$t('about.modal.connectTitle')}</h3>
          <p>{$t('about.modal.connectDescription')}</p>
          
          <a 
            href="https://pinchepoutine.digital" 
            target="_blank" 
            rel="noopener noreferrer"
            class="studio-link"
          >
            <span class="link-icon">🌐</span>
            <span class="link-text">¡Pinche Poutine! Digital</span>
            <span class="link-arrow">→</span>
          </a>
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
    background: rgba(0, 0, 0, 0.8);
    backdrop-filter: blur(4px);
    display: flex;
    align-items: center;
    justify-content: center;
    z-index: 1000;
    padding: 1rem;
  }
  
  .modal-content {
    background: white;
    border-radius: 16px;
    max-width: 900px;
    width: 100%;
    max-height: 90vh;
    overflow-y: auto;
    position: relative;
    padding: 2.5rem;
    box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
  }
  
  .close-btn {
    position: absolute;
    top: 1.5rem;
    right: 1.5rem;
    background: #f5f5f5;
    border: none;
    width: 40px;
    height: 40px;
    border-radius: 50%;
    cursor: pointer;
    display: flex;
    align-items: center;
    justify-content: center;
    transition: all 0.2s ease;
    z-index: 10;
  }
  
  .close-btn:hover {
    background: #e0e0e0;
    transform: scale(1.1);
  }
  
  .content-wrapper {
    display: flex;
    flex-direction: column;
    gap: 2.5rem;
  }
  
  /* Video Section */
  .daily-feature-badge {
    background: linear-gradient(135deg, #1a1a1a 0%, #2a2a2a 100%);
    color: white;
    padding: 1rem 1.25rem;
    border-radius: 12px;
    display: flex;
    align-items: center;
    gap: 1rem;
    margin-bottom: 1.5rem;
    border: 1px solid #333;
  }
  
  .badge-icon {
    font-size: 1.5rem;
    flex-shrink: 0;
  }
  
  .badge-content {
    display: flex;
    flex-direction: column;
    gap: 0.25rem;
  }
  
  .badge-label {
    font-size: 0.75rem;
    text-transform: uppercase;
    letter-spacing: 0.05em;
    opacity: 0.8;
  }
  
  .badge-title {
    font-size: 1rem;
    font-weight: 600;
  }
  
  .modal-video-wrapper {
    position: relative;
    width: 100%;
    height: 0;
    padding-bottom: 56.25%;
    border-radius: 12px;
    overflow: hidden;
    box-shadow: 0 4px 20px rgba(0, 0, 0, 0.15);
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
    padding: 1rem 1.25rem;
    background: #f8f9fa;
    border-radius: 8px;
    border-left: 3px solid #1a1a1a;
  }
  
  .video-description p {
    margin: 0;
    line-height: 1.6;
    color: #333;
  }
  
  /* Bio Section */
  .bio-section h2 {
    font-size: 2rem;
    font-weight: 600;
    color: #1a1a1a;
    margin-bottom: 1rem;
  }
  
  .bio-section h3 {
    font-size: 1.5rem;
    font-weight: 600;
    color: #1a1a1a;
    margin: 2rem 0 1rem;
  }
  
  .bio-section h4 {
    font-size: 1rem;
    font-weight: 600;
    color: #666;
    margin-bottom: 0.75rem;
    text-transform: uppercase;
    letter-spacing: 0.05em;
  }
  
  .intro {
    font-size: 1.125rem;
    line-height: 1.7;
    color: #333;
    margin-bottom: 2rem;
  }
  
  .bio-section p {
    line-height: 1.7;
    color: #555;
    margin-bottom: 1rem;
  }
  
  /* Collaboration Grid */
  .collaboration-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
    gap: 1.5rem;
    margin: 2rem 0;
  }
  
  .collab-card {
    background: #f8f9fa;
    padding: 1.5rem;
    border-radius: 12px;
    border: 2px solid #e0e0e0;
    transition: all 0.3s ease;
  }
  
  .collab-card:hover {
    border-color: #1a1a1a;
    transform: translateY(-4px);
    box-shadow: 0 8px 24px rgba(0, 0, 0, 0.1);
  }
  
  .card-icon {
    font-size: 2.5rem;
    margin-bottom: 1rem;
  }
  
  .collab-card h3 {
    font-size: 1.25rem;
    font-weight: 600;
    color: #1a1a1a;
    margin: 0 0 0.75rem 0;
  }
  
  .collab-card p {
    margin: 0;
    font-size: 0.95rem;
    line-height: 1.6;
    color: #555;
  }
  
  /* Tech Stack */
  .tech-stack {
    background: #f8f9fa;
    padding: 1.5rem;
    border-radius: 12px;
    margin-top: 2rem;
  }
  
  .tech-tags {
    display: flex;
    flex-wrap: wrap;
    gap: 0.75rem;
  }
  
  .tech-tag {
    display: inline-block;
    padding: 0.5rem 1rem;
    background: white;
    border: 1px solid #e0e0e0;
    border-radius: 20px;
    font-size: 0.875rem;
    color: #333;
    font-weight: 500;
  }
  
  /* Contact Section */
  .contact-section h3 {
    font-size: 1.5rem;
    font-weight: 600;
    color: #1a1a1a;
    margin-bottom: 1rem;
  }
  
  .contact-section p {
    line-height: 1.7;
    color: #555;
    margin-bottom: 1.5rem;
  }
  
  .studio-link {
    display: inline-flex;
    align-items: center;
    gap: 1rem;
    padding: 1rem 1.5rem;
    background: #1a1a1a;
    color: white;
    text-decoration: none;
    border-radius: 8px;
    font-weight: 600;
    transition: all 0.3s ease;
  }
  
  .studio-link:hover {
    background: #2a2a2a;
    transform: translateY(-2px);
    box-shadow: 0 8px 24px rgba(0, 0, 0, 0.2);
  }
  
  .link-icon {
    font-size: 1.25rem;
  }
  
  .link-text {
    flex: 1;
  }
  
  .link-arrow {
    font-size: 1.25rem;
    transition: transform 0.3s ease;
  }
  
  .studio-link:hover .link-arrow {
    transform: translateX(4px);
  }
  
  /* Responsive */
  @media (max-width: 768px) {
    .modal-content {
      padding: 1.5rem;
      max-height: 95vh;
    }
    
    .close-btn {
      top: 1rem;
      right: 1rem;
      width: 36px;
      height: 36px;
    }
    
    .content-wrapper {
      gap: 2rem;
    }
    
    .bio-section h2 {
      font-size: 1.5rem;
    }
    
    .bio-section h3 {
      font-size: 1.25rem;
    }
    
    .collaboration-grid {
      grid-template-columns: 1fr;
      gap: 1rem;
    }
    
    .daily-feature-badge {
      padding: 0.75rem 1rem;
    }
    
    .badge-content {
      font-size: 0.9rem;
    }
  }
</style>
