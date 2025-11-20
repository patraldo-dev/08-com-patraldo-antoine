<!-- src/routes/+layout.svelte -->
<script>
  import '../app.css';
  import { onMount } from 'svelte';
  import { page } from '$app/stores';
  import { locale, loadTranslations, loading } from '$lib/translations';
  import Navigation from '$lib/components/Navigation.svelte';
  import { browser } from '$app/environment';
 
  let isReady = false;
  
  // Check if current page needs full-height layout (no top margin)
  $: isFullHeightPage = $page.url.pathname === '/about';
  
  // Initialize i18n on client
  onMount(async () => {
    try {
      // 1. Check localStorage first
      let lang = localStorage.getItem('preferredLanguage');
      
      // 2. If none, default to es
      if (!lang) {
        lang = 'es';
        localStorage.setItem('preferredLanguage', lang);
      }
      
      // 3. Only allow supported locales
      if (!['es', 'en', 'fr'].includes(lang)) {
        lang = 'es';
        localStorage.setItem('preferredLanguage', lang);
      }
      
      // 4. Set locale first
      await locale.set(lang);
    
      // 5. Load translations in parallel
      await Promise.all([
        loadTranslations(lang, 'common'),
        loadTranslations(lang, location.pathname)
      ]);
      console.log('✅ All translations loaded');

      // 6. NOW set ready (don't wait for subscription)
      isReady = true;

      // 8. Handle locale changes with proper cleanup
      const unsubscribeLocale = locale.subscribe(async (newLang) => {
        if (newLang && ['es', 'en', 'fr'].includes(newLang) && newLang !== lang) {
          lang = newLang;
          localStorage.setItem('preferredLanguage', newLang);
          isReady = false;
          // ... rest of your locale change logic ...
        }
      });

      // 9. Cleanup - return unsubscribe function
      return () => {
        unsubscribeLocale();
      };

    } catch (error) {
      console.error('i18n error:', error);
      isReady = true;
    }
  });

</script>

{#if isReady}
  <div class="app">
    <Navigation />
    
    <main class:full-height={isFullHeightPage}>
      <slot />
    </main>
    
    <footer>
      <p>&copy; 2025 Antoine Patraldo. All rights reserved.</p>
    </footer>
  </div>
{:else}
  <div class="loading-screen">
    <div class="loader"></div>
  </div>
{/if}

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
  
  main.full-height {
    margin-top: 0;
  }
  
  footer {
    padding: 2rem 4rem;
    text-align: center;
    font-size: 0.9rem;
    color: #666;
    border-top: 1px solid rgba(0, 0, 0, 0.05);
  }
  
  .loading-screen {
    display: flex;
    align-items: center;
    justify-content: center;
    height: 100vh;
    background: linear-gradient(135deg, #f8f7f4 0%, #edebe8 100%);
  }
  
  .loader {
    width: 50px;
    height: 50px;
    border: 3px solid #f3f3f3;
    border-top: 3px solid #2c5e3d;
    border-radius: 50%;
    animation: spin 1s linear infinite;
  }
  
  @keyframes spin {
    0% { transform: rotate(0deg); }
    100% { transform: rotate(360deg); }
  }
  
  @media (max-width: 768px) {
    main {
      margin-top: 70px;
    }
    
    main.full-height {
      margin-top: 0;
    }
    
    footer {
      padding: 1rem 2rem;
    }
  }
</style>
