<script>
  import { onMount, onDestroy } from 'svelte';
  import { browser } from '$app/environment';
  
  let { open = false, onClose } = $props();
  
  function handleKeydown(e) {
    if (e.key === 'Escape') {
      onClose();
    }
  }
  
  onMount(() => {
    if (browser) {
      document.addEventListener('keydown', handleKeydown);
      document.body.style.overflow = 'hidden';
    }
  });
  
  onDestroy(() => {
    if (browser) {
      document.removeEventListener('keydown', handleKeydown);
      document.body.style.overflow = '';
    }
  });
</script>

{#if open}
  <div class="modal-overlay" onclick={onClose}>
    <div class="modal-content" onclick={(e) => e.stopPropagation()}>
      <button class="close-btn" onclick={onClose}>×</button>
      
      <div class="content-wrapper">
        <!-- Video Section -->
        <section class="video-section">
          <video controls autoplay>
            <source src="YOUR_VIDEO_URL" type="video/mp4">
            <track kind="captions" />
          </video>
        </section>
        
        <!-- Extended Bio -->
        <section class="bio-section">
          <h2>About Antoine Patraldo</h2>
          
          <div class="bio-content">
            <p>
              Extended biography goes here. Talk about your artistic journey,
              influences, philosophy, techniques, etc.
            </p>
            
            <h3>Education</h3>
            <ul>
              <li>Your education details</li>
            </ul>
            
            <h3>Exhibitions</h3>
            <ul>
              <li>2024 - Exhibition Name, Gallery</li>
              <li>2023 - Exhibition Name, Gallery</li>
            </ul>
            
            <h3>Awards & Recognition</h3>
            <ul>
              <li>Award details</li>
            </ul>
            
            <h3>Collections</h3>
            <p>Works in private and public collections...</p>
          </div>
        </section>
        
        <!-- Contact/Social -->
        <section class="contact-section">
          <h3>Get in Touch</h3>
          <div class="social-links">
            <a href="mailto:your@email.com">Email</a>
            <a href="https://instagram.com/yourhandle" target="_blank">Instagram</a>
            <!-- Add more social links -->
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
  }
  
  .modal-content {
    background: white;
    border-radius: 12px;
    max-width: 1200px;
    width: 100%;
    max-height: 90vh;
    overflow-y: auto;
    position: relative;
  }
  
  .close-btn {
    position: sticky;
    top: 1rem;
    right: 1rem;
    float: right;
    background: rgba(0, 0, 0, 0.7);
    color: white;
    border: none;
    width: 40px;
    height: 40px;
    border-radius: 50%;
    font-size: 2rem;
    cursor: pointer;
    display: flex;
    align-items: center;
    justify-content: center;
    z-index: 10;
    transition: all 0.2s ease;
  }
  
  .close-btn:hover {
    background: rgba(0, 0, 0, 0.9);
    transform: scale(1.1);
  }
  
  .content-wrapper {
    padding: 2rem;
  }
  
  .video-section {
    margin-bottom: 3rem;
  }
  
  .video-section video {
    width: 100%;
    border-radius: 8px;
    box-shadow: 0 4px 12px rgba(0,0,0,0.1);
  }
  
  .bio-section {
    margin-bottom: 3rem;
  }
  
  .bio-section h2 {
    font-size: 2rem;
    font-weight: 600;
    color: #1a1a1a;
    margin-bottom: 2rem;
  }
  
  .bio-section h3 {
    font-size: 1.3rem;
    font-weight: 600;
    color: #1a1a1a;
    margin: 2rem 0 1rem;
  }
  
  .bio-content p {
    line-height: 1.8;
    color: #333;
    margin-bottom: 1.5rem;
  }
  
  .bio-content ul {
    list-style: none;
    padding: 0;
  }
  
  .bio-content li {
    padding: 0.5rem 0;
    border-bottom: 1px solid #f0f0f0;
  }
  
  .contact-section {
    background: #f8f8f8;
    padding: 2rem;
    border-radius: 8px;
  }
  
  .contact-section h3 {
    font-size: 1.3rem;
    margin-bottom: 1rem;
  }
  
  .social-links {
    display: flex;
    gap: 1rem;
    flex-wrap: wrap;
  }
  
  .social-links a {
    padding: 0.75rem 1.5rem;
    background: #1a1a1a;
    color: white;
    text-decoration: none;
    border-radius: 6px;
    transition: all 0.2s ease;
  }
  
  .social-links a:hover {
    background: #333;
    transform: translateY(-2px);
  }
  
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
      font-size: 1.5rem;
    }
  }
</style>
