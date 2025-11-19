<!-- Minimalist language switcher -->
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
    background: rgba(0,0,0,0.3);
    color: white;
    border: none;
    width: 2.2rem;
    height: 2.2rem;
    border-radius: 50%;
    font-weight: 600;
    font-size: 0.85rem;
    display: flex;
    align-items: center;
    justify-content: center;
    cursor: pointer;
    backdrop-filter: blur(4px);
    -webkit-backdrop-filter: blur(4px);
    transition: transform 0.2s;
  }

  .lang-code-switcher:hover {
    transform: scale(1.05);
  }
</style>
