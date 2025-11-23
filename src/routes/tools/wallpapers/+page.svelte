<!-- src/routes/tools/wallpapers/+page.svelte -->
<script>
  import { t } from '$lib/i18n';
  
  let { data } = $props();
  let selectedDevice = $state('desktop');
  let selectedArtwork = $state(null);
  let showSizeModal = $state(false);
  
  const deviceSizes = {
    desktop: [
      { name: 'Full HD', width: 1920, height: 1080 },
      { name: 'QHD', width: 2560, height: 1440 },
      { name: '4K UHD', width: 3840, height: 2160 }
    ],
    mobile: [
      { name: 'Full HD', width: 1080, height: 1920 },
      { name: 'QHD', width: 1440, height: 2560 }
    ],
    tablet: [
      { name: 'iPad Pro', width: 2048, height: 2732 },
      { name: 'Standard', width: 2560, height: 1600 }
    ],
    ultrawide: [
      { name: 'UWQHD', width: 3440, height: 1440 },
      { name: '5K2K', width: 5120, height: 1440 }
    ]
  };
  
  function openSizeModal(artwork) {
    selectedArtwork = artwork;
    showSizeModal = true;
  }
  
  function closeSizeModal() {
    showSizeModal = false;
    selectedArtwork = null;
  }
  
  function downloadWallpaper(size) {
    if (!selectedArtwork) return;
    
    // Track download
    trackDownload(selectedArtwork.id, size);
    
    // Use Cloudflare Images to resize on the fly
    const url = getResizedImageUrl(selectedArtwork.image_id, size.width, size.height);
    
    // Trigger download
    const link = document.createElement('a');
    link.href = url;
    link.download = `${sanitizeFilename(selectedArtwork.display_name || selectedArtwork.title)}-${size.width}x${size.height}.jpg`;
    link.click();
    
    closeSizeModal();
  }
  
  function getResizedImageUrl(imageId, width, height) {
    // Cloudflare Images URL with dynamic sizing
    return `https://imagedelivery.net/${data.cfImagesHash}/${imageId}/w=${width},h=${height},fit=cover`;
  }
  
  function sanitizeFilename(name) {
    return name.toLowerCase().replace(/[^a-z0-9]/g, '-');
  }
  
  async function trackDownload(artworkId, size) {
    try {
      await fetch('/api/analytics', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          eventType: 'wallpaper_download',
          artworkId,
          metadata: {
            width: size.width,
            height: size.height,
            device: selectedDevice
          }
        })
      });
    } catch (err) {
      console.error('Analytics tracking failed:', err);
    }
  }
</script>

<svelte:head>
  <title>{$t('pages.tools.wallpapersPageTitle')} - Antoine Patraldo</title>
</svelte:head>

<div class="wallpapers-page">
  <header class="page-header">
    <a href="/tools" class="back-link">← {$t('pages.tools.backToTools')}</a>
    <h1>{$t('pages.tools.wallpapersPageTitle')}</h1>
    <p class="subtitle">{$t('pages.tools.wallpapersPageDescription')}</p>
  </header>

  <!-- Device Type Selector -->
  <div class="device-selector">
    <button 
      class="device-btn" 
      class:active={selectedDevice === 'desktop'}
      onclick={() => selectedDevice = 'desktop'}
    >
      🖥️ {$t('pages.tools.wallpapersDesktop')}
    </button>
    <button 
      class="device-btn" 
      class:active={selectedDevice === 'mobile'}
      onclick={() => selectedDevice = 'mobile'}
    >
      📱 {$t('pages.tools.wallpapersMobile')}
    </button>
    <button 
      class="device-btn" 
      class:active={selectedDevice === 'tablet'}
      onclick={() => selectedDevice = 'tablet'}
    >
      📲 {$t('pages.tools.wallpapersTablet')}
    </button>
    <button 
      class="device-btn" 
      class:active={selectedDevice === 'ultrawide'}
      onclick={() => selectedDevice = 'ultrawide'}
    >
      🖥️ {$t('pages.tools.wallpapersUltrawide')}
    </button>
  </div>

  <!-- Artworks Grid -->
  <div class="wallpapers-grid">
    {#each data.artworks as artwork}
      <div class="wallpaper-card" onclick={() => openSizeModal(artwork)}>
        <div class="card-image">
          <img 
            src={artwork.thumbnailUrl} 
            alt={artwork.display_name || artwork.title}
            loading="lazy"
          />
          <div class="card-overlay">
            <span class="download-icon">⬇️</span>
            <span class="download-text">{$t('pages.tools.wallpapersDownload')}</span>
          </div>
        </div>
        <div class="card-info">
          <h3>{artwork.display_name || artwork.title}</h3>
          {#if artwork.year}
            <span class="year">{artwork.year}</span>
          {/if}
        </div>
      </div>
    {/each}
  </div>
</div>

<!-- Size Selection Modal -->
{#if showSizeModal && selectedArtwork}
  <div class="modal-overlay" onclick={closeSizeModal}>
    <div class="modal-content" onclick={(e) => e.stopPropagation()}>
      <button class="close-btn" onclick={closeSizeModal}>×</button>
      
      <h2>{$t('pages.tools.wallpapersSelectSize')}</h2>
      <p class="modal-subtitle">
        {selectedArtwork.display_name || selectedArtwork.title}
      </p>
      
      <div class="sizes-grid">
        {#each deviceSizes[selectedDevice] as size}
          <button 
            class="size-option"
            onclick={() => downloadWallpaper(size)}
          >
            <div class="size-name">{size.name}</div>
            <div class="size-dimensions">{size.width} × {size.height}</div>
          </button>
        {/each}
      </div>
    </div>
  </div>
{/if}

<style>
  .wallpapers-page {
    min-height: 100vh;
    background: linear-gradient(180deg, #fafafa 0%, #ffffff 100%);
    padding: 6rem 2rem 4rem;
  }

  .page-header {
    max-width: 1200px;
    margin: 0 auto 3rem;
  }

  .back-link {
    display: inline-block;
    color: #666;
    text-decoration: none;
    margin-bottom: 2rem;
    transition: color 0.2s ease;
  }

  .back-link:hover {
    color: #1a1a1a;
  }

  .page-header h1 {
    font-size: 2.5rem;
    font-weight: 600;
    color: #1a1a1a;
    margin: 0 0 1rem 0;
  }

  .subtitle {
    font-size: 1.125rem;
    color: #666;
    line-height: 1.6;
  }

  .device-selector {
    max-width: 1200px;
    margin: 0 auto 3rem;
    display: flex;
    gap: 1rem;
    flex-wrap: wrap;
  }

  .device-btn {
    padding: 1rem 2rem;
    background: white;
    border: 2px solid #e0e0e0;
    border-radius: 8px;
    font-size: 1rem;
    cursor: pointer;
    transition: all 0.2s ease;
  }

  .device-btn:hover {
    border-color: #ccc;
    transform: translateY(-2px);
  }

  .device-btn.active {
    background: #1a1a1a;
    color: white;
    border-color: #1a1a1a;
  }

  .wallpapers-grid {
    max-width: 1200px;
    margin: 0 auto;
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
    gap: 2rem;
  }

  .wallpaper-card {
    background: white;
    border: 2px solid #e0e0e0;
    border-radius: 12px;
    overflow: hidden;
    cursor: pointer;
    transition: all 0.3s ease;
  }

  .wallpaper-card:hover {
    transform: translateY(-4px);
    box-shadow: 0 12px 24px rgba(0,0,0,0.1);
    border-color: #1a1a1a;
  }

  .card-image {
    position: relative;
    width: 100%;
    padding-top: 66.67%;
    background: #f5f5f5;
    overflow: hidden;
  }

  .card-image img {
    position: absolute;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    object-fit: cover;
    transition: transform 0.3s ease;
  }

  .wallpaper-card:hover .card-image img {
    transform: scale(1.05);
  }

  .card-overlay {
    position: absolute;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    background: rgba(0,0,0,0.7);
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    opacity: 0;
    transition: opacity 0.3s ease;
  }

  .wallpaper-card:hover .card-overlay {
    opacity: 1;
  }

  .download-icon {
    font-size: 3rem;
    margin-bottom: 0.5rem;
  }

  .download-text {
    color: white;
    font-size: 1rem;
    font-weight: 600;
    text-transform: uppercase;
    letter-spacing: 0.5px;
  }

  .card-info {
    padding: 1.25rem;
  }

  .card-info h3 {
    font-size: 1.125rem;
    font-weight: 600;
    color: #1a1a1a;
    margin: 0 0 0.5rem 0;
  }

  .year {
    font-size: 0.875rem;
    color: #999;
  }

  /* Modal Styles */
  .modal-overlay {
    position: fixed;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    background: rgba(0,0,0,0.8);
    z-index: 9999;
    display: flex;
    align-items: center;
    justify-content: center;
    padding: 2rem;
  }

  .modal-content {
    background: white;
    border-radius: 16px;
    max-width: 600px;
    width: 100%;
    padding: 2.5rem;
    position: relative;
  }

  .close-btn {
    position: absolute;
    top: 1rem;
    right: 1rem;
    background: none;
    border: none;
    font-size: 2rem;
    color: #666;
    cursor: pointer;
    width: 40px;
    height: 40px;
    display: flex;
    align-items: center;
    justify-content: center;
    border-radius: 50%;
    transition: all 0.2s ease;
  }

  .close-btn:hover {
    background: #f0f0f0;
  }

  .modal-content h2 {
    font-size: 1.75rem;
    font-weight: 600;
    color: #1a1a1a;
    margin: 0 0 0.5rem 0;
  }

  .modal-subtitle {
    font-size: 1rem;
    color: #666;
    margin: 0 0 2rem 0;
  }

  .sizes-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(140px, 1fr));
    gap: 1rem;
  }

  .size-option {
    padding: 1.5rem 1rem;
    background: #f8f8f8;
    border: 2px solid #e0e0e0;
    border-radius: 8px;
    cursor: pointer;
    transition: all 0.2s ease;
    text-align: center;
  }

  .size-option:hover {
    background: white;
    border-color: #1a1a1a;
    transform: translateY(-2px);
  }

  .size-name {
    font-weight: 600;
    color: #1a1a1a;
    margin-bottom: 0.5rem;
  }

  .size-dimensions {
    font-size: 0.875rem;
    color: #666;
  }

  @media (max-width: 768px) {
    .wallpapers-page {
      padding: 4rem 1.5rem 3rem;
    }

    .page-header h1 {
      font-size: 2rem;
    }

    .device-selector {
      flex-direction: column;
    }

    .device-btn {
      width: 100%;
    }

    .wallpapers-grid {
      grid-template-columns: 1fr;
      gap: 1.5rem;
    }

    .sizes-grid {
      grid-template-columns: 1fr;
    }
  }
</style>
