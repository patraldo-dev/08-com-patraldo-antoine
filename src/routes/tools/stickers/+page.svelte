<!-- src/routes/tools/stickers/+page.svelte -->
<script>
  import { generateStickerSheet } from '$lib/utils/generateStickerSheet.mjs';
  import { t } from '$lib/i18n';

  const { data } = $props();

  // Cloudflare Images config
  const CF_ACCOUNT_HASH = '4bRSwPonOXfEIBVZiDXg0w';
  const CF_VARIANT = 'gallery'; // or 'full' for higher res

  const artworks = (data?.artworks || []).map(art => ({
    id: String(art.id),
    displayName: art.display_name || art.title,
    imageUrl: `https://imagedelivery.net/${CF_ACCOUNT_HASH}/${art.image_id}/${CF_VARIANT}`
  }));

  let selected = $state(new Set());
  let isGenerating = $state(false);
  let format = $state($t('sticker.formatDefault') || 'png');  


  async function downloadSheet() {
    if (selected.size === 0) return;
    
    isGenerating = true;
    try {
      const list = Array.from(selected).map(id =>
        artworks.find(a => a.id === id)
      ).filter(Boolean);

      const blob = await generateStickerSheet(list, { 
        cols: 3, 
        rows: 3, 
        format 
      });
      
      const ext = format === 'pdf' ? 'pdf' : 'png';
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = `sticker-sheet-${selected.size}x.${ext}`;
      a.click();
      URL.revokeObjectURL(url);
    } catch (err) {
      console.error('Sheet generation failed:', err);
      alert(t('sticker.error'));
    } finally {
      isGenerating = false;
    }
  }

  function toggleSelection(id) {
    const newSet = new Set(selected);
    if (newSet.has(id)) {
      newSet.delete(id);
    } else {
      newSet.add(id);
    }
    selected = newSet;
  }

  function toggleFormat() {
    format = format === 'png' ? 'pdf' : 'png';
  }
</script>

<div class="stickers-page">
  <h1>{$t('sticker.title')}</h1>
  <p>{$t('sticker.description')}</p>

  {#if artworks.length === 0}
    <p>{$t('sticker.noArtworks')}</p>
  {:else}
    <div class="artwork-grid">
      {#each artworks as artwork}
        <div class="artwork-card">
          <img
            src={artwork.imageUrl}
            alt={artwork.displayName}
            loading="lazy"
            onclick={() => toggleSelection(artwork.id)}
            class:selected={selected.has(artwork.id)}
          />
          <p>{artwork.displayName}</p>
        </div>
      {/each}
    </div>

    <div class="actions">
      <div class="format-toggle">
<button class="format-btn {format === 'png' ? 'active' : ''}" onclick={toggleFormat}>
  {$t('sticker.formatPng')}
</button>
<button class="format-btn {format === 'pdf' ? 'active' : ''}" onclick={toggleFormat}>
  {$t('sticker.formatPdf')}
</button>
<span>{$t('sticker.formatLabel')}: <strong>{format.toUpperCase()}</strong></span>
      </div>

      <button
        disabled={selected.size === 0 || isGenerating}
        onclick={downloadSheet}
        class="primary"
      >
        {#if isGenerating}
          {$t('sticker.generating')}
        {:else}
          {$t('sticker.downloadSheet').replace('{count}', selected.size)}
        {/if}
      </button>
      
      {#if selected.size > 0}
        <p class="selection-hint">
          {$t('sticker.selected').replace('{count}', selected.size)}
        </p>
      {/if}
    </div>
  {/if}
</div>

<style>
  .stickers-page {
    max-width: 900px;
    margin: 0 auto;
    padding: 1rem;
  }
  .artwork-grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(120px, 1fr));
    gap: 1.25rem;
    margin: 1.5rem 0;
  }
  .artwork-card {
    text-align: center;
  }
  .artwork-card img {
    width: 100%;
    aspect-ratio: 1;
    object-fit: contain;
    border: 2px solid #eee;
    border-radius: 8px;
    cursor: pointer;
    transition: border-color 0.2s;
  }
  .artwork-card img.selected {
    border-color: #1a1a1a;
    box-shadow: 0 0 0 2px #1a1a1a;
  }
  .artwork-card p {
    margin-top: 0.5rem;
    font-size: 0.9rem;
    color: #333;
  }
  .actions {
    text-align: center;
    margin-top: 2rem;
  }
  .format-toggle {
    display: flex;
    gap: 1rem;
    align-items: center;
    margin-bottom: 1rem;
    flex-wrap: wrap;
    justify-content: center;
  }
  .format-btn {
    padding: 0.5rem 1rem;
    border: 2px solid #ddd;
    background: white;
    cursor: pointer;
    border-radius: 6px;
    font-size: 0.9rem;
    transition: all 0.2s;
  }
  .format-btn.active,
  .format-btn:hover {
    background: #1a1a1a;
    color: white;
    border-color: #1a1a1a;
  }
  .format-btn.active {
    font-weight: bold;
  }
  .primary {
    background: #1a1a1a;
    color: white;
    border: none;
    padding: 0.75rem 1.5rem;
    border-radius: 6px;
    font-size: 1rem;
    cursor: pointer;
  }
  .primary:disabled {
    opacity: 0.6;
    cursor: not-allowed;
  }
  .selection-hint {
    margin-top: 0.75rem;
    color: #666;
    font-style: italic;
  }
</style>

