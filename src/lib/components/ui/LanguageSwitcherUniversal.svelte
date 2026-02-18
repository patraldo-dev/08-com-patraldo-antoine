<!-- src/lib/components/ui/LanguageSwitcherUniversal.svelte -->
<script>
  import { locale } from '$lib/i18n';
  import { browser } from '$app/environment';
  import { page } from '$app/stores';
  import { goto } from '$app/navigation';

  const languages = [
    { code: 'es', name: 'Español', short: 'ES' },
    { code: 'en', name: 'English', short: 'EN' },
    { code: 'fr', name: 'Français', short: 'FR' }
  ];

  async function switchLanguage(newLocale) {

    if (!browser) return;

    // Clear any open modals/hashes before switching
    if (window.location.hash) {
      history.replaceState(null, '', window.location.pathname + window.location.search);
      document.body.style.overflow = '';
    }

    // Set the new locale
    locale.set(newLocale);
    localStorage.setItem('preferredLanguage', newLocale);
    document.cookie = `preferredLanguage=${newLocale}; path=/; max-age=31536000`;

    // Navigate to the same page in the new language
    const currentPath = $page.url.pathname;
    await goto(currentPath);
  }
</script>

<div class="language-switcher">
  <div class="desktop-view">
    {#each languages as language}
      <button
        class="lang-btn {language.code === $locale ? 'active' : ''}"
        on:click|preventDefault={() => switchLanguage(language.code)}
        aria-label="{language.name}"
        title="{language.name}"
      >
        {language.short}
      </button>
    {/each}
  </div>

  <div class="mobile-view">
    {#each languages as language}
      <button
        class="lang-btn {language.code === $locale ? 'active' : ''}"
        on:click|preventDefault={() => switchLanguage(language.code)}
        aria-label="{language.name}"
        title="{language.name}"
      >
        {language.short}
      </button>
    {/each}
  </div>
</div>

<style>
  .language-switcher {
    display: flex;
    gap: 0.5rem;
  }

  .desktop-view {
    display: flex;
    gap: 0.5rem;
  }

  .mobile-view {
    display: flex;
    gap: 0.5rem;
  }

  .lang-btn {
    width: 2.5rem;
    height: 2.5rem;
    border-radius: 50%;
    border: 1px solid rgba(0, 0, 0, 0.1);
    background: rgba(0, 0, 0, 0.05);
    color: #2a2a2a;
    font-weight: 600;
    font-size: 0.85rem;
    display: flex;
    align-items: center;
    justify-content: center;
    cursor: pointer;
    transition: all 0.2s ease;
  }

  .lang-btn:hover {
    background: rgba(0, 0, 0, 0.08);
    transform: scale(1.05);
    border-color: rgba(0, 0, 0, 0.2);
  }

  .lang-btn.active {
    background: #1a1a1a;
    color: white;
    border-color: #1a1a1a;
  }

  .lang-btn:active {
    transform: scale(0.95);
  }

  /* Mobile-specific styles */
  @media (max-width: 768px) {
    .desktop-view {
      display: none;
    }
    
    .mobile-view .lang-btn {
      width: 2.2rem;
      height: 2.2rem;
      background: rgba(0, 0, 0, 0.3);
      color: white;
      border: none;
      backdrop-filter: blur(4px);
      -webkit-backdrop-filter: blur(4px);
    }
    
    .mobile-view .lang-btn.active {
      background: white;
      color: #1a1a1a;
    }
  }

  /* Desktop-specific styles */
  @media (min-width: 769px) {
    .mobile-view {
      display: none;
    }
  }
</style>
