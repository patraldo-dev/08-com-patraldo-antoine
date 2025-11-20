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
  
  // Only include download/share functions if not in preview mode
  {#if !preview}
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
  {/if}
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
    
    <!-- Color bar - simplified in preview mode -->
    <div class="color-bar {preview ? 'preview-bar' : ''}">
      {#each colors as color, i}
        {#if preview}
          <!-- Preview mode: simple color swatches -->
          <div
            class="color-swatch preview-swatch"
            style="background-color: {color.hex}"
            title="{color.hex}"
          ></div>
        {:else}
          <!-- Full mode: interactive buttons -->
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
    
    <!-- Only show actions if not in preview mode and not compact -->
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
  .color-palette.preview-mode {
    padding: 0;
  }

  .preview-bar {
    height: 80px;
    border-radius: 8px;
  }

  .preview-swatch {
    cursor: default;
    border: none;
  }

  .preview-swatch:hover {
    transform: scale(1.05);
    z-index: 1;
  }

  /* Rest of your existing styles... */
  .palette-loading {
    /* your existing loading styles */
  }
  
  .color-bar {
    /* your existing color-bar styles */
  }
  
  /* etc. */
</style>
