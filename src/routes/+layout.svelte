<!-- src/routes/+layout.svelte -->
<script>
  import '../app.css';
  import { onMount } from 'svelte';
  import { t, locale, loadTranslations } from '$lib/translations';
  import LanguageSwitcherDesktop from '$lib/components/ui/LanguageSwitcherDesktop.svelte';
  import LanguageSwitcherMobile from '$lib/components/ui/LanguageSwitcherMobile.svelte';

  let isMenuOpen = false;

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

  // === Your existing nav logic (unchanged) ===
  function toggleMenu() {
    isMenuOpen = !isMenuOpen;
    document.body.style.overflow = isMenuOpen ? 'hidden' : '';
  }

  function closeMenu() {
    isMenuOpen = false;
    document.body.style.overflow = '';
  }

  function handleLinkClick() {
    closeMenu();
  }

  function handleOutsideClick(event) {
    if (isMenuOpen && !event.target.closest('nav')) {
      closeMenu();
    }
  }

  function handleKeydown(event) {
    if (event.key === 'Escape' && isMenuOpen) {
      closeMenu();
    }
  }

  onMount(() => {
    document.addEventListener('click', handleOutsideClick);
    document.addEventListener('keydown', handleKeydown);
    
    return () => {
      document.removeEventListener('click', handleOutsideClick);
      document.removeEventListener('keydown', handleKeydown);
      document.body.style.overflow = '';
    };
  });
</script>

<div class="app">
  <nav>
    <a href="/" class="logo-link">
      <h1>ANTOINE PATRALDO</h1>
    </a>
    
<!-- Desktop Menu -->
<div class="nav-links desktop-menu">
  <a href="#work" on:click={handleLinkClick}>{$t('common.nav.work')}</a>
  <a href="#about" on:click={handleLinkClick}>{$t('common.nav.about')}</a>
  <a href="/stories">{$t('common.nav.stories')}</a>
  <a href="#contact" on:click={handleLinkClick}>{$t('common.nav.contact')}</a>
  <LanguageSwitcherDesktop />
</div>

    
    <!-- Mobile/Tablet Menu Button -->
    <button 
      class="menu-button" 
      class:open={isMenuOpen}
      aria-label="Toggle menu"
      aria-expanded={isMenuOpen}
      on:click|stopPropagation={toggleMenu}
    >
      <span class="menu-line"></span>
      <span class="menu-line"></span>
    </button>

   <!-- Mobile Menu -->
<div class="mobile-menu" class:open={isMenuOpen}>
  <a href="#work" on:click={handleLinkClick}>{$t('common.nav.work')}</a>
  <a href="#about" on:click={handleLinkClick}>{$t('common.nav.about')}</a>
  <a href="/stories">{$t('common.nav.stories')}</a>
  <a href="#contact" on:click={handleLinkClick}>{$t('common.nav.contact')}</a>
  <div class="mobile-lang-switcher">
    <LanguageSwitcherMobile />
  </div>
</div> 
  </nav>
  
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

body {
  padding-top: 80px; /* push content down */
}
  
nav {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  height: 80px; /* explicitly set */
  z-index: var(--z-nav);
  background: rgba(255,255,255,0.95);
  padding: 1rem 2rem; /* adjust accordingly */
}
  
  .logo-link {
    text-decoration: none;
    color: inherit;
  }
  
  .logo-link:hover h1 {
    opacity: 0.8;
  }
  
  h1 {
    font-size: 1.5rem;
    font-weight: 300;
    letter-spacing: 2px;
    margin: 0;
    transition: opacity 0.3s;
  }
  
  .nav-links {
    display: flex;
    gap: 2rem;
    align-items: center;
  }
  
  .nav-links a {
    text-decoration: none;
    color: inherit;
    font-weight: 300;
    transition: opacity 0.3s;
  }
  
  .nav-links a:hover {
    opacity: 0.6;
  }
  
  .menu-button {
    display: none;
    background: none;
    border: none;
    cursor: pointer;
    padding: 0.5rem;
    flex-direction: column;
    justify-content: center;
    gap: 4px;
    width: 40px;
    height: 40px;
    box-sizing: border-box;
    position: relative;
  }
  
  .menu-line {
    width: 24px;
    height: 2px;
    background-color: #2a2a2a;
    transition: all 0.3s ease;
    position: absolute;
    left: 8px;
  }
  
  .menu-line:first-child {
    top: 12px;
  }
  
  .menu-line:last-child {
    bottom: 12px;
  }
  
  .menu-button.open .menu-line:first-child {
    transform: rotate(45deg);
    top: 19px;
  }
  
  .menu-button.open .menu-line:last-child {
    transform: rotate(-45deg);
    bottom: 19px;
  }
  
  .mobile-menu {
    position: fixed;
    top: 0;
    right: 0;
    width: 70%;
    max-width: 300px;
    height: 100vh;
    background: white;
    box-shadow: -2px 0 10px rgba(0, 0, 0, 0.1);
    padding: 6rem 2rem 2rem;
    display: flex;
    flex-direction: column;
    gap: 2rem;
    transform: translateX(100%);
    transition: transform 0.3s ease;
    overflow-y: auto;
    position: relative;
    z-index: calc(var(--z-nav) + 1); /* 101 */


  }
  
  .mobile-menu.open {
    transform: translateX(0);
  }
  
  .mobile-menu a {
    text-decoration: none;
    color: #2a2a2a;
    font-size: 1.2rem;
    font-weight: 300;
    padding: 0.5rem 0;
    border-bottom: 1px solid #eee;
    transition: color 0.3s;
    display: block;
  }
  
  .mobile-menu a:hover {
    color: #667eea;
  }

  .mobile-lang-switcher {
    position: absolute;
    top: 1.5rem;
    right: 2rem;
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
  
  /* Responsive Styles */
  @media (max-width: 768px) {
    nav {
      padding: 1rem 2rem;
    }
    
    .desktop-menu {
      display: none;
    }
    
    .menu-button {
      display: flex;
    }
    
    main {
      margin-top: 70px;
    }
    
    footer {
      padding: 1rem 2rem;
    }
  }
  
  /* Tablet Styles */
  @media (min-width: 769px) and (max-width: 1024px) {
    .desktop-menu {
      display: none;
    }
    
    .menu-button {
      display: flex;
    } 
  }
</style>
