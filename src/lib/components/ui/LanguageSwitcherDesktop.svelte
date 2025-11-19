<!-- Minimalist language switcher for desktop -->
<script>
  import { locale } from '$lib/translations';
  import { browser } from '$app/environment';
  
  // Map locale to 2-letter code
  const localeToCode = {
    'es': 'ES',
    'en': 'EN',
    'fr': 'FR'
  };
  
  // Cycle order
  const cycle = ['es', 'en', 'fr'];
  
  function cycleLanguage() {
    if (!browser) return;
    
    const current = $locale;
    const currentIndex = cycle.indexOf(current);
    const nextIndex = (currentIndex + 1) % cycle.length;
    const nextLocale = cycle[nextIndex];
    
    locale.set(nextLocale);
    localStorage.setItem('preferredLanguage', nextLocale);
    
    // Also set cookie for server-side
    document.cookie = `preferredLanguage=${nextLocale}; path=/; max-age=31536000`;
  }
  
  $: displayCode = localeToCode[$locale] || 'ES';
</script>

<button
  class="lang-code-switcher"
  on:click|preventDefault={cycleLanguage}
  aria-label="Change language: {$locale}"
>
  {displayCode}
</button>

<style>
  .lang-code-switcher {
    background: rgba(0, 0, 0, 0.05);
    color: #2a2a2a;
    border: 1px solid rgba(0, 0, 0, 0.1);
    width: 2.5rem;
    height: 2.5rem;
    border-radius: 50%;
    font-weight: 600;
    font-size: 0.85rem;
    display: flex;
    align-items: center;
    justify-content: center;
    cursor: pointer;
    transition: all 0.2s;
  }
  
  .lang-code-switcher:hover {
    background: rgba(0, 0, 0, 0.08);
    transform: scale(1.05);
    border-color: rgba(0, 0, 0, 0.2);
  }
  
  .lang-code-switcher:active {
    transform: scale(0.95);
  }
</style>
