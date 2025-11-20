 <script>
  import { onMount } from 'svelte';
  import { browser } from '$app/environment';
  
  let { imageUrl, artworkTitle = 'Artwork', compact = false } = $props();
  
  let colors = $state([]);
  let loading = $state(true);
  let error = $state(null);
  let copiedIndex = $state(-1);
  let ColorThief = $state(null);
  
  onMount(async () => {
    // Import ColorThief only in browser
    if (browser) {
      const ColorThiefModule = await import('colorthief');
      ColorThief = ColorThiefModule.default;
      
      try {
        await extractColors();
      } catch (err) {
        console.error('Failed to extract colors:', err);
        error = 'Could not extract colors';
        loading = false;
      }
    }
  });
  
    loading = true;
    
  async function extractColors() {
    loading = true;
    
    // Create a temporary image element
    const img = new Image();
    img.crossOrigin = 'Anonymous';
    
    img.onload = () => {
      try {
        const colorThief = new ColorThief();
        const palette = colorThief.getPalette(img, 6);
        
        // Convert RGB arrays to hex
        colors = palette.map(rgb => ({
          rgb,
          hex: rgbToHex(rgb[0], rgb[1], rgb[2])
        }));
        
        loading = false;
      } catch (err) {
        console.error('Color extraction error:', err);
        error = 'Color extraction failed';
        loading = false;
      }
    };
    
    img.onerror = () => {
      error = 'Failed to load image';
      loading = false;
    };
    
    img.src = imageUrl;
  }
  
  function rgbToHex(r, g, b) {
    return '#' + [r, g, b].map(x => {
      const hex = x.toString(16);
      return hex.length === 1 ? '0' + hex : hex;
    }).join('');
  }
  
  async function copyToClipboard(hex, index) {
    try {
      await navigator.clipboard.writeText(hex);
      copiedIndex = index;
      setTimeout(() => copiedIndex = -1, 2000);
    } catch (err) {
      console.error('Failed to copy:', err);
    }
  }
  
  function downloadCSS() {
    const css = colors.map((color, i) => 
      `  --color-${i + 1}: ${color.hex};`
    ).join('\n');
    
    const content = `:root {\n${css}\n}`;
    downloadFile(content, `${sanitizeFilename(artworkTitle)}-palette.css`, 'text/css');
  }
  
  function downloadJSON() {
    const data = {
      artwork: artworkTitle,
      colors: colors.map(c => ({
        hex: c.hex,
        rgb: c.rgb
      }))
    };
    
    const content = JSON.stringify(data, null, 2);
    downloadFile(content, `${sanitizeFilename(artworkTitle)}-palette.json`, 'application/json');
  }
  
  function downloadGPL() {
    // GIMP/Inkscape palette format
    let gpl = `GIMP Palette\nName: ${artworkTitle}\nColumns: 6\n#\n`;
    colors.forEach((color, i) => {
      gpl += `${color.rgb[0].toString().padStart(3)} ${color.rgb[1].toString().padStart(3)} ${color.rgb[2].toString().padStart(3)} Color ${i + 1}\n`;
    });
    
    downloadFile(gpl, `${sanitizeFilename(artworkTitle)}-palette.gpl`, 'text/plain');
  }
  
  function downloadFile(content, filename, mimeType) {
    const blob = new Blob([content], { type: mimeType });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = filename;
    a.click();
    URL.revokeObjectURL(url);
  }
  
  function sanitizeFilename(name) {
    return name.toLowerCase().replace(/[^a-z0-9]/g, '-');
  }
  
  function shareToMastodon() {
    const text = `Color palette from "${artworkTitle}" by Antoine Patraldo\n${colors.map(c => c.hex).join(' ')}`;
    const url = `https://mastodon.social/share?text=${encodeURIComponent(text)}`;
    window.open(url, '_blank');
  }
  
  function shareToPinterest() {
    const url = `https://pinterest.com/pin/create/button/?url=${encodeURIComponent(window.location.href)}&description=${encodeURIComponent(`Color palette from "${artworkTitle}"`)}&media=${encodeURIComponent(imageUrl)}`;
    window.open(url, '_blank');
  }
</script>

{#if loading}
  <div class="palette-loading">
    <span>Extracting colors...</span>
  </div>
{:else if error}
  <div class="palette-error">
    <span>{error}</span>
  </div>
{:else if colors.length > 0}
  <div class="color-palette">
    <div class="palette-title">Color Palette</div>
    
    <!-- pywal-style horizontal bar -->
    <div class="color-bar">
      {#each colors as color, i}
        <button
          class="color-swatch"
          style="background-color: {color.hex}"
          onclick={() => copyToClipboard(color.hex, i)}
          title="Click to copy {color.hex}"
        >
          <span class="hex-code">{color.hex}</span>
          {#if copiedIndex === i}
            <span class="copied-indicator">✓</span>
          {/if}
        </button>
      {/each}
    </div>
    
{#if !compact}
    <!-- Download & Share buttons -->
    <div class="palette-actions">
      <div class="download-group">
        <span class="action-label">Download:</span>
        <button class="action-btn" onclick={downloadCSS}>CSS</button>
        <button class="action-btn" onclick={downloadJSON}>JSON</button>
        <button class="action-btn" onclick={downloadGPL}>GIMP/Inkscape</button>
      </div>
{/if}

      
      <div class="share-group">
        <span class="action-label">Share:</span>
        <button class="action-btn" onclick={shareToMastodon}>Mastodon</button>
        <button class="action-btn" onclick={shareToPinterest}>Pinterest</button>
      </div>
    </div>
  </div>
{/if}

<style>
  .palette-loading,
  .palette-error {
    padding: 1rem;
    text-align: center;
    color: #666;
    font-size: 0.9rem;
  }
  
  .palette-error {
    color: #dc3545;
  }
  
  .color-palette {
    margin-top: 2rem;
  }
  
  .palette-title {
    font-size: 0.9rem;
    font-weight: 600;
    color: #666;
    text-transform: uppercase;
    letter-spacing: 0.5px;
    margin-bottom: 1rem;
  }
  
  /* pywal-style horizontal color bar */
  .color-bar {
    display: flex;
    width: 100%;
    height: 80px;
    border-radius: 8px;
    overflow: hidden;
    box-shadow: 0 2px 8px rgba(0,0,0,0.15);
    margin-bottom: 1.5rem;
  }
  
  .color-swatch {
    flex: 1;
    border: none;
    cursor: pointer;
    position: relative;
    transition: all 0.2s ease;
    display: flex;
    align-items: flex-end;
    justify-content: center;
    padding: 0.5rem;
  }
  
  .color-swatch:hover {
    transform: translateY(-4px);
    z-index: 1;
    box-shadow: 0 4px 12px rgba(0,0,0,0.3);
  }
  
  .hex-code {
    font-size: 0.75rem;
    font-weight: 600;
    font-family: monospace;
    color: white;
    text-shadow: 0 1px 2px rgba(0,0,0,0.5);
    opacity: 0;
    transition: opacity 0.2s ease;
  }
  
  .color-swatch:hover .hex-code {
    opacity: 1;
  }
  
  .copied-indicator {
    position: absolute;
    top: 50%;
    left: 50%;
    transform: translate(-50%, -50%);
    font-size: 2rem;
    color: white;
    text-shadow: 0 2px 4px rgba(0,0,0,0.5);
    animation: fadeInOut 2s ease;
  }
  
  @keyframes fadeInOut {
    0%, 100% { opacity: 0; }
    10%, 90% { opacity: 1; }
  }
  
  .palette-actions {
    display: flex;
    gap: 2rem;
    flex-wrap: wrap;
  }
  
  .download-group,
  .share-group {
    display: flex;
    gap: 0.5rem;
    align-items: center;
    flex-wrap: wrap;
  }
  
  .action-label {
    font-size: 0.85rem;
    font-weight: 600;
    color: #666;
  }
  
  .action-btn {
    padding: 0.5rem 1rem;
    background: white;
    border: 2px solid #e0e0e0;
    border-radius: 6px;
    font-size: 0.85rem;
    font-weight: 500;
    cursor: pointer;
    transition: all 0.2s ease;
  }
  
  .action-btn:hover {
    background: #f5f5f5;
    border-color: #ccc;
    transform: translateY(-1px);
  }
  
  @media (max-width: 768px) {
    .color-bar {
      height: 60px;
    }
    
    .hex-code {
      font-size: 0.65rem;
    }
    
    .palette-actions {
      flex-direction: column;
      gap: 1rem;
    }
    
    .download-group,
    .share-group {
      width: 100%;
    }
  }
</style>
