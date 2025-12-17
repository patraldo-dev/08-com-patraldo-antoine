<!-- src/lib/components/NLWebSearch.svelte -->
<script>
  import { onMount } from 'svelte';
  import { browser } from '$app/environment';
  import { t } from '$lib/i18n';
  
  let isOpen = $state(false);
  let searchLoaded = $state(false);
  let chatInstance = $state(null);
  
  onMount(() => {
    if (!browser) return;
    
    // Load CSS
    const cssCommon = document.createElement('link');
    cssCommon.rel = 'stylesheet';
    cssCommon.href = 'https://proud-wildflower-e16c-nlweb.chef-tech.workers.dev/common-chat-styles.css';
    document.head.appendChild(cssCommon);
    
    const cssDropdown = document.createElement('link');
    cssDropdown.rel = 'stylesheet';
    cssDropdown.href = 'https://proud-wildflower-e16c-nlweb.chef-tech.workers.dev/nlweb-dropdown-chat.css';
    document.head.appendChild(cssDropdown);
    
    return () => {
      cssCommon.remove();
      cssDropdown.remove();
    };
  });
  
  async function initializeSearch() {
    // Clean up existing instance first
    if (chatInstance) {
      chatInstance.destroy();
      chatInstance = null;
    }
    
    if (!browser) return;
    
    try {
      const { NLWebDropdownChat } = await import('https://proud-wildflower-e16c-nlweb.chef-tech.workers.dev/nlweb-dropdown-chat.js');
      
      // Wait a bit for the DOM to be ready
      await new Promise(resolve => setTimeout(resolve, 100));
      
      chatInstance = new NLWebDropdownChat({
        containerId: 'nlweb-search-container',
        site: 'https://proud-wildflower-e16c-nlweb.chef-tech.workers.dev',
        placeholder: $t('search.placeholder'),
        endpoint: 'https://proud-wildflower-e16c-nlweb.chef-tech.workers.dev',
        language: navigator.language.split('-')[0]  // 'es', 'fr', 'en'
      });
      
      searchLoaded = true;
    } catch (error) {
      console.error('Failed to load NLWeb search:', error);
    }
  }
  
  function toggleSearch() {
    if (!isOpen) {
      // Opening: recreate fresh instance
      if (chatInstance) {
        chatInstance.destroy();
        chatInstance = null;
        searchLoaded = false;
      }
      isOpen = true;
      initializeSearch();
    } else {
      // Closing: clean up
      if (chatInstance) {
        chatInstance.destroy();
        chatInstance = null;
      }
      isOpen = false;
      searchLoaded = false;
    }
  }
  
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

<svelte:window onkeydown={handleKeydown} />

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

<!-- Search Container -->
{#if isOpen}
  <div class="search-overlay" onclick={() => isOpen = false}>
    <div class="search-modal" onclick={(e) => e.stopPropagation()}>
      <div class="search-header">
        <h2>{$t('search.title')}</h2>
        <button class="close-btn" onclick={() => isOpen = false} aria-label={$t('search.closeLabel')}>
          <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <line x1="18" y1="6" x2="6" y2="18"></line>
            <line x1="6" y1="6" x2="18" y2="18"></line>
          </svg>
        </button>
      </div>
      
      <div class="search-content">
        <div id="nlweb-search-container"></div>
        {#if !searchLoaded}
          <div class="loading-state">
            <div class="spinner"></div>
            <p>{$t('search.loading')}</p>
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
    background: #1a1a1a;
    color: white;
    border: 2px solid #2a2a2a;
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
    background: #2a2a2a;
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
    background: white;
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
    border-bottom: 1px solid #e0e0e0;
  }
  
  .search-header h2 {
    margin: 0;
    font-size: 1.25rem;
    font-weight: 600;
    color: #1a1a1a;
  }
  
  .close-btn {
    background: none;
    border: none;
    cursor: pointer;
    padding: 0.5rem;
    color: #666;
    transition: color 0.2s;
  }
  
  .close-btn:hover {
    color: #1a1a1a;
  }
  
  .search-content {
    flex: 1;
    overflow-y: auto;
    padding: 1.5rem;
    position: relative;
    min-height: 300px;
  }
  
  .loading-state {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    padding: 3rem;
    color: #666;
  }
  
  .spinner {
    width: 40px;
    height: 40px;
    border: 3px solid #f0f0f0;
    border-top-color: #1a1a1a;
    border-radius: 50%;
    animation: spin 0.8s linear infinite;
    margin-bottom: 1rem;
  }
  
  @keyframes spin {
    to { transform: rotate(360deg); }
  }
  
  .search-footer {
    padding: 1rem 1.5rem;
    border-top: 1px solid #e0e0e0;
    background: #f8f9fa;
    border-radius: 0 0 16px 16px;
  }
  
  .hint {
    margin: 0;
    font-size: 0.875rem;
    color: #666;
    text-align: center;
  }
  
  kbd {
    display: inline-block;
    padding: 0.125rem 0.375rem;
    background: white;
    border: 1px solid #ddd;
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
