<!-- src/routes/+layout.svelte -->
<script>
  import '../app.css';
  import { onMount } from 'svelte';
  import { locale, loadTranslations } from '$lib/translations';
  import Navigation from '$lib/components/Navigation.svelte';
  
  // Initialize i18n on client
  onMount(() => {
    // 1. Check localStorage first
    let lang = localStorage.getItem('preferredLanguage');
    
    // 2. If none, default to es-MX (NOT browser language)
    if (!lang) {
      lang = 'es-MX';
      localStorage.setItem('preferredLanguage', lang);
    }
    
    // 3. Only allow supported locales
    if (!['es-MX', 'en-US', 'fr-CA'].includes(lang)) {
      lang = 'es-MX';
      localStorage.setItem('preferredLanguage', lang);
    }
    
    // 4. Set locale and load translations
    locale.set(lang);
    loadTranslations(lang, location.pathname);
    
    // 5. Save locale changes when user switches language
    const unsubscribe = locale.subscribe((newLang) => {
      if (newLang && ['es-MX', 'en-US', 'fr-CA'].includes(newLang)) {
        localStorage.setItem('preferredLanguage', newLang);
      }
    });
    
    // 6. Cleanup subscription on component destroy
    return () => unsubscribe();
  });
</script>

<div class="app">
  <Navigation />
  
  <main>
    <slot />
  </main>
  
  <footer>
    <p>&copy; 2025 Antoine Patraldo. All rights reserved.</p>
  </footer>
</div>

<style>
  .app {
    min-height: 100vh;
    display: flex;
    flex-direction: column;
  }
  
  main {
    flex: 1;
    margin-top: 80px;
  }
  
  footer {
    padding: 2rem 4rem;
    text-align: center;
    font-size: 0.9rem;
    color: #666;
    border-top: 1px solid rgba(0, 0, 0, 0.05);
  }
  
  @media (max-width: 768px) {
    main {
      margin-top: 70px;
    }
    
    footer {
      padding: 1rem 2rem;
    }
  }
</style>
