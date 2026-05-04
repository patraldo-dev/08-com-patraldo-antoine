<!-- src/routes/+layout.svelte -->
<script>
  import '../app.css';
  import { onMount } from 'svelte';
  import { page } from '$app/stores';
  import { locale, setLocale } from '$lib/i18n';
  import Navigation from '$lib/components/Navigation.svelte';
  import NLWebSearch from '$lib/components/NLWebSearch.svelte';
  import AIArtAssistant from '$lib/components/AIArtAssistant.svelte';
  import { browser } from '$app/environment';
  
  // Only destructure 'data'. DO NOT destructure 'isAdmin' here.
  let { data } = $props();
  
  // Reactive state for admin status and username
  let isAdmin = $derived(data?.isAdmin ?? false);
  let username = $derived(data?.username ?? null);
  
  // DEBUG: Log the values
  $effect(() => {
    if (browser) {
      console.log('🔍 Layout Debug - isAdmin:', isAdmin, 'username:', username, 'data:', data);
    }
  });
  
  // Reactive state for page layout
  let isFullHeightPage = $derived($page.url.pathname === '/about');
  
  // Initialize locale on client
  onMount(() => {
    //1. Check localStorage for preferred language
    let lang = localStorage.getItem('preferredLanguage');

    //2. Default to Spanish if none set
    if (!lang || !['es', 'en', 'fr'].includes(lang)) {
      lang = 'es';
      localStorage.setItem('preferredLanguage', lang);
    }

    //3. Set the locale (instant, no loading needed!)
    setLocale(lang);

    //4. Suppress Cloudflare Stream beacon errors (browser only)
    if (browser) {
      const originalError = console.error;
      console.error = function(...args) {
        if (args[0] && typeof args[0] === 'string' &&
            args[0].includes('cloudflarestream.com/cdn-cgi/beacon/media')) {
          return;
        }
        originalError.apply(console, args);
      };

      window.addEventListener('error', (event) => {
        if (event.target && event.target.src &&
            event.target.src.includes('cloudflarestream.com/cdn-cgi/beacon/media')) {
          event.preventDefault();
          event.stopPropagation();
          return false;
        }
      }, true);
      
      // Force restore scroll on mount
      document.body.style.overflow = '';
    }

    //5. Save locale changes to localStorage
    const unsubscribeLocale = locale.subscribe((newLang) => {
      if (newLang && ['es', 'en', 'fr'].includes(newLang)) {
        localStorage.setItem('preferredLanguage', newLang);
        // Restore scroll when locale changes
        setTimeout(() => {
          document.body.style.overflow = '';
        }, 100);
      }
    });

    // Cleanup on unmount
    return () => {
      unsubscribeLocale();
      if (browser) {
        document.body.style.overflow = '';
      }
    };
  });
</script>

<div class="app">
  <Navigation {isAdmin} {username} />  
  <main class:full-height={isFullHeightPage}>
    <slot />
  </main>
  
  <footer>
    <p>&copy; 2026 Antoine Patraldo. All rights reserved.</p>
  </footer>
<NLWebSearch />
<AIArtAssistant />
</div>

<!-- Keep all your existing styles -->
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
