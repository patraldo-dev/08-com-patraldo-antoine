<script>
  import { onMount } from 'svelte';
  import { browser } from '$app/environment';
  
  let { 
    imageUrl, 
    artworkTitle = 'Artwork', 
    compact = false,
    preview = false  // New prop for preview mode
  } = $props();
  
  let colors = $state([]);
  let loading = $state(true);
  let error = $state(null);
  let copiedIndex = $state(-1);
  let ColorThief = $state(null);
  
  onMount(async () => {
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
    
  async function extractColors() {
    loading = true;
    
    const img = new Image();
    img.crossOrigin = 'Anonymous';
    
    img.onload = () => {
      try {
        const colorThief = new ColorThief();
        const palette = colorThief.getPalette(img, 6);
        
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
  <div class="color-palette {preview ? 'preview-mode' : ''}">
    {#if !preview}
      <div class="palette-title">Color Palette</div>
    {/if}
    
    <div class="color-bar {preview ? 'preview-bar' : ''}">
      {#each colors as color, i}
        {#if preview}
          <div
            class="color-swatch preview-swatch"
            style="background-color: {color.hex}"
            title="{color.hex}"
          ></div>
        {:else}
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
        {/if}
      {/each}
    </div>
    
    {#if !preview && !compact}
      <div class="palette-actions">
        <div class="download-group">
          <span class="action-label">Download:</span>
          <button class="action-btn" onclick={downloadCSS}>CSS</button>
          <button class="action-btn" onclick={downloadJSON}>JSON</button>
          <button class="action-btn" onclick={downloadGPL}>GIMP/Inkscape</button>
        </div>
        
        <div class="share-group">
          <span class="action-label">Share:</span>
          <button class="action-btn" onclick={shareToMastodon}>Mastodon</button>
          <button class="action-btn" onclick={shareToPinterest}>Pinterest</button>
        </div>
      </div>
    {/if}
  </div>
{/if}

<style>
  .color-palette {
    background: var(--color-surface);
    border-radius: 12px;
    padding: 1.5rem;
    border: 1px solid var(--color-border);
  }

  .color-palette.preview-mode {
    padding: 0;
    background: transparent;
    border: none;
  }

  .palette-title {
    font-size: 1.25rem;
    font-weight: 600;
    margin-bottom: 1rem;
    color: var(--color-text-primary);
  }

  .color-bar {
    display: flex;
    width: 100%;
    height: 60px;
    border-radius: 8px;
    overflow: hidden;
    box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
  }

  .preview-bar {
    height: 80px;
    border-radius: 8px;
  }

  .color-swatch {
    flex: 1;
    border: none;
    cursor: pointer;
    position: relative;
    display: flex;
    align-items: center;
    justify-content: center;
    transition: transform 0.2s ease;
    color: white;
    font-size: 0.75rem;
    font-weight: 500;
    text-shadow: 0 1px 2px rgba(0, 0, 0, 0.5);
  }

  .preview-swatch {
    cursor: default;
  }

  .preview-swatch:hover {
    transform: scale(1.05);
    z-index: 1;
  }

  .color-swatch:hover:not(.preview-swatch) {
    transform: scale(1.05);
    z-index: 1;
  }

  .hex-code {
    opacity: 0;
    transition: opacity 0.2s ease;
  }

  .color-swatch:hover .hex-code {
    opacity: 1;
  }

  .copied-indicator {
    position: absolute;
    font-size: 1rem;
    font-weight: bold;
  }

  .palette-actions {
    display: flex;
    flex-direction: column;
    gap: 1rem;
    margin-top: 1.5rem;
    padding-top: 1.5rem;
    border-top: 1px solid var(--color-border);
  }

  .download-group,
  .share-group {
    display: flex;
    align-items: center;
    gap: 0.5rem;
    flex-wrap: wrap;
  }

  .action-label {
    font-size: 0.875rem;
    font-weight: 500;
    color: var(--color-text-secondary);
    min-width: 60px;
  }

  .action-btn {
    padding: 0.375rem 0.75rem;
    background: var(--color-primary);
    color: #517782;
    border: none;
    border-radius: 6px;
    font-size: 0.875rem;
    cursor: pointer;
    transition: background-color 0.2s ease;
  }

  .action-btn:hover {
    background: var(--color-primary-dark);
  }

  .palette-loading {
    display: flex;
    align-items: center;
    justify-content: center;
    padding: 2rem;
    color: var(--color-text-secondary);
  }

  .palette-error {
    display: flex;
    align-items: center;
    justify-content: center;
    padding: 2rem;
    color: var(--color-error);
  }

  @media (max-width: 768px) {
    .download-group,
    .share-group {
      flex-direction: column;
      align-items: flex-start;
    }
    
    .action-label {
      min-width: auto;
    }
  }
</style>
