onMount(async () => {
  try {
    // 1-4. Your existing code...
    
    // 5. Load translations in parallel
    await Promise.all([
      loadTranslations(lang, 'common'),
      loadTranslations(lang, location.pathname)
    ]);
    console.log('✅ All translations loaded');
    
    // 6. NOW set ready (don't wait for subscription)
    isReady = true;
    
    // 7. Handle locale changes
    const unsubscribeLocale = locale.subscribe(async (newLang) => {
      if (newLang && ['es-MX', 'en-US', 'fr-CA'].includes(newLang) && newLang !== lang) {
        lang = newLang;
        localStorage.setItem('preferredLanguage', newLang);
        isReady = false;
        
        // Reload both translations
        await Promise.all([
          loadTranslations(newLang, 'common'),
          loadTranslations(newLang, location.pathname)
        ]);
        
        isReady = true;
      }
    });
    
    // 8. Cleanup
    return () => {
      unsubscribeLocale();
    };
    
  } catch (error) {
    console.error('i18n error:', error);
    isReady = true;
  }
});
