<script>
  import { locale, loadTranslations } from '$lib/translations';
  import { page } from '$app/stores';
  
  const languages = [
    { code: 'es', name: 'Español', short: 'ES' },
    { code: 'en', name: 'English', short: 'EN' },
    { code: 'fr', name: 'Français', short: 'FR' }
  ];
  
  async function switchLanguage(newLocale) {
    console.log('🔄 Switching to:', newLocale);
    
    // Save preference
    localStorage.setItem('preferredLanguage', newLocale);
    document.cookie = `preferredLanguage=${newLocale}; path=/; max-age=31536000`;
    
    // Load translations for new locale
    const currentPath = $page.url.pathname;
    await loadTranslations(newLocale, currentPath);
    
    // Set locale
    locale.set(newLocale);
    
    console.log('✅ Language switched to:', newLocale);
  }
</script>

<div class="language-switcher">
  <div class="desktop-view">
    {#each languages as language}
      <button
        class="lang-btn"
        class:active={language.code === $locale}
        onclick={() => switchLanguage(language.code)}
        aria-label={language.name}
        title={language.name}
      >
        {language.short}
      </button>
    {/each}
  </div>
  
  <div class="mobile-view">
    {#each languages as language}
      <button
        class="lang-btn"
        class:active={language.code === $locale}
        onclick={() => switchLanguage(language.code)}
        aria-label={language.name}
        title={language.name}
      >
        {language.short}
      </button>
    {/each}
  </div>
</div>

<!-- Keep your existing styles -->
