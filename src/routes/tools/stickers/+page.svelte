<!-- src/routes/tools/stickers/+page.svelte -->
<script>
  import { generateStickerSheet } from '$lib/utils/generateStickerSheet.mjs';
  import { t } from '$lib/i18n';

  export let data;

  // Cloudflare Images config
  const CF_ACCOUNT_HASH = '4bRSwPonOXfEIBVZiDXg0w';
  const CF_VARIANT = 'full'; // or 'gallery' for smaller file size; 'full' for print

  const artworks = data.artworks.map(art => ({
    id: art.id,
    displayName: art.display_name || art.title,
    imageUrl: `https://imagedelivery.net/${CF_ACCOUNT_HASH}/${art.image_id}/${CF_VARIANT}`
  }));

  let selected = $state(new Set());
  let isGenerating = $state(false);

  async function downloadSheet() {
    if (selected.size === 0) return;
    
    isGenerating = true;
    try {
      const list = Array.from(selected).map(id =>
        artworks.find(a => a.id === id)
      ).filter(Boolean);

      const blob = await generateStickerSheet(list);
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = 'sticker-sheet.png';
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
    if (selected.has(id)) {
      selected.delete(id);
    } else {
      selected.add(id);
    }
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
      <button
        disabled={selected.size === 0 || isGenerating}
        onclick={downloadSheet}
        class="primary"
      >
        {#if isGenerating}
          {$t('sticker.generating')}
        {:else}
          {$t('sticker.downloadSheet', { count: selected.size })}
        {/if}
      </button>
      {#if selected.size > 0}
        <p class="selection-hint">
          {$t('sticker.selected', { count: selected.size })}
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
  .error {
    color: #c00;
  }
</style>
