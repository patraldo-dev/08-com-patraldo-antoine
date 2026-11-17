<script>
  // src/lib/components/NLWebSearch.svelte
  //
  // First-party site search (FAB + ⌘K modal). Formerly loaded the
  // wizard-deployed NLWeb dropdown from a *.workers.dev domain that no
  // longer exists; now queries this site's /api/search, which is backed
  // by the account's AI Search instance (hybrid retrieval over the
  // crawled site content).
  import { t } from '#lib/i18n/index.js';
  import { get } from 'svelte/store';

  let isOpen = $state(false);
  let query = $state('');
  let results = $state([]);
  let searching = $state(false);
  let searched = $state(false);
  let failed = $state(false);
  let debounceTimer;

  // Map indexed page URLs to existing i18n titles (keys verified present
  // in en/es/fr locale files). Fallback: the raw path.
  const PATH_TITLES = {
    '/': 'common.navhome',
    '/collection': 'common.navcollection',
    '/cine': 'common.navCine',
    '/cine/gallery': 'cine.gallery.title',
    '/stories': 'common.navstories',
    '/worlds': 'pages.worlds.title',
    '/tools': 'common.navtools',
    '/tools/3d-art': 'pages.tools.art3dTitle',
    '/tools/palettes': 'pages.tools.palettes.heading',
    '/tools/stickers': 'pages.tools.stickersTitle',
    '/tools/wallpapers': 'pages.tools.wallpaperspagetitle'
  };

  function titleFor(url) {
    try {
      const path = new URL(url).pathname.replace(/\/+$/, '') || '/';
      if (PATH_TITLES[path]) return get(t)(PATH_TITLES[path]);
      if (path.startsWith('/stories/')) return get(t)('common.navstories');
      if (path.startsWith('/cine/watch/')) return get(t)('common.navCine');
      if (path.startsWith('/cine/')) return get(t)('common.navCine');
      if (path.startsWith('/tools/')) return get(t)('common.navtools');
      return path;
    } catch {
      return url;
    }
  }

  function pathFor(url) {
    try {
      return new URL(url).pathname;
    } catch {
      return url;
    }
  }

  function toggleSearch() {
    isOpen = !isOpen;
    if (isOpen) {
      // Fresh open: reset state, focus input
      query = '';
      results = [];
      searched = false;
      failed = false;
      setTimeout(() => {
        const input = /** @type {HTMLInputElement | null} */ (document.querySelector('.search-input'));
        if (input) input.focus();
      }, 50);
    }
  }

  function onInput(e) {
    query = e.target.value;
    clearTimeout(debounceTimer);
    if (query.trim().length < 2) {
      results = [];
      searched = false;
      searching = false;
      return;
    }
    debounceTimer = setTimeout(() => runSearch(), 280);
  }

  function onKeydownInput(e) {
    if (e.key === 'Enter') {
      e.preventDefault();
      clearTimeout(debounceTimer);
      runSearch();
    }
  }

  async function runSearch() {
    const q = query.trim();
    if (q.length < 2) return;
    searching = true;
    failed = false;
    try {
      const res = await fetch(`/api/search?q=${encodeURIComponent(q)}`);
      const data = await res.json();
      if (!res.ok) throw new Error(data?.error || res.status);
      results = data.results || [];
      searched = true;
    } catch (err) {
      console.error('Search failed:', err);
      results = [];
      searched = true;
      failed = true;
    } finally {
      searching = false;
    }
  }

  $effect(() => {
    const handler = (event) => handleKeydown(event);
    window.addEventListener('keydown', handler);
    return () => window.removeEventListener('keydown', handler);
  });

  function handleKeydown(event) {
    // CMD+K or CTRL+K to open search
    if ((event.metaKey || event.ctrlKey) && event.key === 'k') {
      event.preventDefault();
      toggleSearch();
    }
    // ESC to close
    if (event.key === 'Escape' && isOpen) {
      isOpen = false;
    }
  }
</script>

<!-- Floating Search Button -->
<button
  class="search-fab"
  onclick={toggleSearch}
  aria-label={$t('search.openLabel')}
  title={$t('search.shortcut')}
>
  <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
    <circle cx="11" cy="11" r="8"></circle>
    <path d="m21 21-4.35-4.35"></path>
  </svg>
</button>

<!-- Search Modal -->
{#if isOpen}
  <div class="search-overlay" onclick={() => (isOpen = false)}>
    <div class="search-modal" onclick={(e) => e.stopPropagation()} role="dialog" aria-modal="true" aria-label={$t('search.title')}>
      <div class="search-header">
        <h2>{$t('search.title')}</h2>
        <button class="close-btn" onclick={() => (isOpen = false)} aria-label={$t('search.closeLabel')}>
          <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <line x1="18" y1="6" x2="6" y2="18"></line>
            <line x1="6" y1="6" x2="18" y2="18"></line>
          </svg>
        </button>
      </div>

      <div class="search-content">
        <div class="input-row">
          <svg class="input-icon" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <circle cx="11" cy="11" r="8"></circle>
            <path d="m21 21-4.35-4.35"></path>
          </svg>
          <input
            class="search-input"
            type="text"
            placeholder={$t('search.placeholder')}
            value={query}
            oninput={onInput}
            onkeydown={onKeydownInput}
            autocomplete="off"
            spellcheck="false"
          />
          {#if searching}
            <span class="mini-spinner" aria-label={$t('search.searching')}></span>
          {/if}
        </div>

        {#if failed}
          <div class="state-msg">
            <p>{$t('search.error')}</p>
          </div>
        {:else if searching && !results.length}
          <div class="state-msg">
            <p>{$t('search.searching')}</p>
          </div>
        {:else if searched && !results.length}
          <div class="state-msg">
            <p>{$t('search.noResults')}</p>
          </div>
        {:else if results.length}
          <ul class="results" role="listbox">
            {#each results as r (r.url)}
              <li>
                <a class="result-card" href={pathFor(r.url)}>
                  <span class="result-title">{titleFor(r.url)}</span>
                  <span class="result-path">{pathFor(r.url)}</span>
                  {#if r.snippet}
                    <span class="result-snippet">{r.snippet}</span>
                  {/if}
                  <span class="result-score" aria-hidden="true"><span style="width: {Math.min(100, Math.round(r.score * 100))}%"></span></span>
                </a>
              </li>
            {/each}
          </ul>
        {:else if !searched}
          <div class="state-msg subtle">
            <p>{$t('search.placeholder')}</p>
          </div>
        {/if}
      </div>

      <div class="search-footer">
        <p class="hint">
          <kbd>⌘K</kbd> {$t('search.toOpen')} · <kbd>ESC</kbd> {$t('search.toClose')}
        </p>
      </div>
    </div>
  </div>
{/if}

<style>
  .search-fab {
    position: fixed;
    bottom: 2rem;
    right: 2rem;
    width: 56px;
    height: 56px;
    border-radius: 50%;
    background: var(--color-text);
    color: var(--color-surface-raised);
    border: 2px solid var(--color-text-dim);
    box-shadow: 0 4px 20px rgba(0, 0, 0, 0.2);
    cursor: pointer;
    display: flex;
    align-items: center;
    justify-content: center;
    transition: all 0.3s ease;
    z-index: 999;
  }

  .search-fab:hover {
    transform: scale(1.1);
    background: var(--color-text-dim);
    box-shadow: 0 6px 30px rgba(0, 0, 0, 0.3);
  }

  .search-fab:active {
    transform: scale(0.95);
  }

  .search-overlay {
    position: fixed;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    background: rgba(0, 0, 0, 0.7);
    backdrop-filter: blur(4px);
    z-index: 1000;
    display: flex;
    align-items: center;
    justify-content: center;
    padding: 2rem;
    animation: fadeIn 0.2s ease;
  }

  @keyframes fadeIn {
    from { opacity: 0; }
    to { opacity: 1; }
  }

  .search-modal {
    background: var(--color-surface-raised);
    border-radius: 16px;
    width: 100%;
    max-width: 700px;
    max-height: 80vh;
    display: flex;
    flex-direction: column;
    box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
    animation: slideUp 0.3s ease;
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

  .search-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 1.5rem;
    padding-bottom: 0.75rem;
    border-bottom: 1px solid var(--color-border);
  }

  .search-header h2 {
    margin: 0;
    font-size: 1.25rem;
    font-weight: 600;
    color: var(--color-text);
  }

  .close-btn {
    background: none;
    border: none;
    cursor: pointer;
    padding: 0.5rem;
    color: var(--color-text-muted);
    transition: color 0.2s;
  }

  .close-btn:hover {
    color: var(--color-text);
  }

  .search-content {
    flex: 1;
    overflow-y: auto;
    padding: 1rem 1.5rem 1.5rem;
    position: relative;
  }

  .input-row {
    display: flex;
    align-items: center;
    gap: 0.75rem;
    padding: 0.75rem 1rem;
    border: 2px solid var(--color-border);
    border-radius: 12px;
    background: var(--color-surface);
    margin-bottom: 1rem;
  }

  .input-row:focus-within {
    border-color: var(--color-text-dim);
  }

  .input-icon {
    color: var(--color-text-muted);
    flex-shrink: 0;
  }

  .search-input {
    flex: 1;
    border: none;
    outline: none;
    background: transparent;
    color: var(--color-text);
    font-size: 1.05rem;
    min-width: 0;
  }

  .search-input::placeholder {
    color: var(--color-text-muted);
  }

  .mini-spinner {
    width: 18px;
    height: 18px;
    border: 2px solid var(--color-border);
    border-top-color: var(--color-text);
    border-radius: 50%;
    animation: spin 0.8s linear infinite;
    flex-shrink: 0;
  }

  @keyframes spin {
    to { transform: rotate(360deg); }
  }

  .state-msg {
    display: flex;
    align-items: center;
    justify-content: center;
    padding: 2.5rem 1rem;
    color: var(--color-text-muted);
    text-align: center;
  }

  .state-msg.subtle {
    padding: 1.5rem 1rem;
    font-size: 0.9rem;
  }

  .state-msg p {
    margin: 0;
  }

  .results {
    list-style: none;
    margin: 0;
    padding: 0;
    display: flex;
    flex-direction: column;
    gap: 0.75rem;
  }

  .result-card {
    display: flex;
    flex-direction: column;
    gap: 0.25rem;
    padding: 0.9rem 1rem;
    border: 1px solid var(--color-border);
    border-radius: 12px;
    background: var(--color-surface);
    text-decoration: none;
    transition: border-color 0.2s ease, transform 0.2s ease;
  }

  .result-card:hover,
  .result-card:focus-visible {
    border-color: var(--color-text-dim);
    transform: translateY(-1px);
  }

  .result-title {
    font-weight: 600;
    color: var(--color-text);
    font-size: 1rem;
  }

  .result-path {
    font-family: monospace;
    font-size: 0.75rem;
    color: var(--color-text-muted);
  }

  .result-snippet {
    font-size: 0.875rem;
    color: var(--color-text-muted);
    line-height: 1.45;
    display: -webkit-box;
    -webkit-line-clamp: 2;
    -webkit-box-orient: vertical;
    overflow: hidden;
  }

  .result-score {
    display: block;
    height: 3px;
    margin-top: 0.35rem;
    border-radius: 2px;
    background: var(--color-border);
    overflow: hidden;
  }

  .result-score span {
    display: block;
    height: 100%;
    border-radius: 2px;
    background: var(--color-text-dim);
  }

  .search-footer {
    padding: 1rem 1.5rem;
    border-top: 1px solid var(--color-border);
    background: var(--color-surface);
    border-radius: 0 0 16px 16px;
  }

  .hint {
    margin: 0;
    font-size: 0.875rem;
    color: var(--color-text-muted);
    text-align: center;
  }

  kbd {
    display: inline-block;
    padding: 0.125rem 0.375rem;
    background: var(--color-surface-raised);
    border: 1px solid var(--color-border);
    border-radius: 4px;
    font-size: 0.75rem;
    font-family: monospace;
    box-shadow: 0 1px 2px rgba(0, 0, 0, 0.1);
  }

  @media (max-width: 768px) {
    .search-fab {
      bottom: 1rem;
      right: 1rem;
      width: 48px;
      height: 48px;
    }

    .search-overlay {
      padding: 0;
    }

    .search-modal {
      max-height: 100vh;
      border-radius: 0;
    }
  }
</style>
