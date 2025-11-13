<!-- src/lib/components/Navigation.svelte -->
<script>
  import { onMount } from 'svelte';
  import { goto } from '$app/navigation';
  import { t } from '$lib/translations';
  import LanguageSwitcherDesktop from '$lib/components/ui/LanguageSwitcherDesktop.svelte';
  import LanguageSwitcherMobile from '$lib/components/ui/LanguageSwitcherMobile.svelte';
  
  let isMenuOpen = false;
  
  function toggleMenu(event) {
    // Prevent any default behavior
    if (event) {
      event.preventDefault();
      event.stopPropagation();
    }
    
    isMenuOpen = !isMenuOpen;
    
    // Prevent body scroll when menu is open
    if (typeof document !== 'undefined') {
      document.body.style.overflow = isMenuOpen ? 'hidden' : '';
    }
  }
  
  function closeMenu() {
    isMenuOpen = false;
    if (typeof document !== 'undefined') {
      document.body.style.overflow = '';
    }
  }
  
  function handleLinkClick(event, href) {
    // Always close menu first
    closeMenu();
    
    // Check if it's a hash link (anchor on same page)
    if (href.startsWith('#')) {
      event.preventDefault();
      
      // Small delay to let menu close animation start
      setTimeout(() => {
        const target = document.querySelector(href);
        if (target) {
          target.scrollIntoView({ behavior: 'smooth', block: 'start' });
          // Update URL without triggering navigation
          history.pushState(null, '', href);
        }
      }, 100);
    } else if (href.startsWith('/')) {
      // Internal route - use SvelteKit navigation
      event.preventDefault();
      goto(href);
    }
    // External links work normally (no preventDefault)
  }
  
  function handleOutsideClick(event) {
    if (!isMenuOpen) return;
    
    // Check if click is outside nav
    const nav = event.target.closest('nav');
    const menuButton = event.target.closest('.menu-button');
    
    if (!nav && !menuButton) {
      closeMenu();
    }
  }
  
  function handleKeydown(event) {
    if (event.key === 'Escape' && isMenuOpen) {
      closeMenu();
    }
  }
  
  onMount(() => {
    // Use passive listeners for better mobile performance
    document.addEventListener('click', handleOutsideClick, { passive: true });
    document.addEventListener('keydown', handleKeydown);
    
    return () => {
      document.removeEventListener('click', handleOutsideClick);
      document.removeEventListener('keydown', handleKeydown);
      if (typeof document !== 'undefined') {
        document.body.style.overflow = '';
      }
    };
  });
</script>

<nav>
  <a href="/" class="logo-link" on:click={(e) => handleLinkClick(e, '/')}>
    <h1>ANTOINE PATRALDO</h1>
  </a>
  
  <!-- Desktop Menu -->
  <div class="nav-links desktop-menu">
    <a href="#work" on:click={(e) => handleLinkClick(e, '#work')}>{$t('common.nav.work')}</a>
    <a href="#about" on:click={(e) => handleLinkClick(e, '#about')}>{$t('common.nav.about')}</a>
    <a href="/stories" on:click={(e) => handleLinkClick(e, '/stories')}>{$t('common.nav.stories')}</a>
    <a href="#contact" on:click={(e) => handleLinkClick(e, '#contact')}>{$t('common.nav.contact')}</a>
    <LanguageSwitcherDesktop />
  </div>
  
  <!-- Mobile/Tablet Menu Button -->
  <button 
    class="menu-button" 
    class:open={isMenuOpen}
    aria-label={isMenuOpen ? 'Close menu' : 'Open menu'}
    aria-expanded={isMenuOpen}
    on:click={toggleMenu}
    on:touchend|preventDefault={toggleMenu}
    type="button"
  >
    <span class="menu-line"></span>
    <span class="menu-line"></span>
  </button>
  
  <!-- Mobile Menu Overlay -->
  {#if isMenuOpen}
    <div class="menu-overlay" on:click={closeMenu}></div>
  {/if}
  
  <!-- Mobile Menu -->
  <div class="mobile-menu" class:open={isMenuOpen}>
    <a href="#work" on:click={(e) => handleLinkClick(e, '#work')}>{$t('common.nav.work')}</a>
    <a href="#about" on:click={(e) => handleLinkClick(e, '#about')}>{$t('common.nav.about')}</a>
    <a href="/stories" on:click={(e) => handleLinkClick(e, '/stories')}>{$t('common.nav.stories')}</a>
    <a href="#contact" on:click={(e) => handleLinkClick(e, '#contact')}>{$t('common.nav.contact')}</a>
    <div class="mobile-lang-switcher">
      <LanguageSwitcherMobile />
    </div>
  </div>
</nav>

<style>
  nav {
    position: fixed;
    top: 0;
    left: 0;
    right: 0;
    height: 80px;
    z-index: var(--z-nav);
    background: rgba(255,255,255,0.95);
    backdrop-filter: blur(10px);
    padding: 1rem 2rem;
    display: flex;
    justify-content: space-between;
    align-items: center;
    box-shadow: 0 2px 10px rgba(0,0,0,0.05);
  }
  
  .logo-link {
    text-decoration: none;
    color: inherit;
    z-index: 2;
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
    cursor: pointer;
  }
  
  .nav-links a:hover {
    opacity: 0.6;
  }
  
  .menu-button {
    display: none;
    background: none;
    border: none;
    cursor: pointer;
    padding: 0.75rem;
    flex-direction: column;
    justify-content: center;
    gap: 4px;
    width: 48px;
    height: 48px;
    box-sizing: border-box;
    position: relative;
    z-index: calc(var(--z-nav) + 2);
    /* Improve touch target */
    -webkit-tap-highlight-color: transparent;
    touch-action: manipulation;
  }
  
  .menu-line {
    width: 24px;
    height: 2px;
    background-color: #2a2a2a;
    transition: all 0.3s ease;
    position: absolute;
    left: 12px;
  }
  
  .menu-line:first-child {
    top: 16px;
  }
  
  .menu-line:last-child {
    bottom: 16px;
  }
  
  .menu-button.open .menu-line:first-child {
    transform: rotate(45deg);
    top: 23px;
  }
  
  .menu-button.open .menu-line:last-child {
    transform: rotate(-45deg);
    bottom: 23px;
  }
  
  /* Overlay to darken background when menu is open */
  .menu-overlay {
    position: fixed;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    background: rgba(0, 0, 0, 0.5);
    z-index: calc(var(--z-nav) + 1);
    animation: fadeIn 0.3s ease;
  }
  
  @keyframes fadeIn {
    from { opacity: 0; }
    to { opacity: 1; }
  }
  
  .mobile-menu {
    position: fixed;
    top: 0;
    right: 0;
    width: 75%;
    max-width: 320px;
    height: 100vh;
    background: white;
    box-shadow: -4px 0 20px rgba(0, 0, 0, 0.15);
    padding: 6rem 2rem 2rem;
    display: flex;
    flex-direction: column;
    gap: 2rem;
    transform: translateX(100%);
    transition: transform 0.3s ease;
    overflow-y: auto;
    z-index: calc(var(--z-nav) + 2);
    /* Improve scrolling on iOS */
    -webkit-overflow-scrolling: touch;
  }
  
  .mobile-menu.open {
    transform: translateX(0);
  }
  
  .mobile-menu a {
    text-decoration: none;
    color: #2a2a2a;
    font-size: 1.2rem;
    font-weight: 300;
    padding: 0.75rem 0;
    border-bottom: 1px solid #eee;
    transition: color 0.3s;
    display: block;
    cursor: pointer;
    /* Improve touch targets */
    min-height: 48px;
    display: flex;
    align-items: center;
  }
  
  .mobile-menu a:hover,
  .mobile-menu a:active {
    color: #2c5e3d;
  }
  
  .mobile-lang-switcher {
    position: absolute;
    top: 1.5rem;
    right: 2rem;
  }
  
  /* Responsive Styles */
  @media (max-width: 768px) {
    nav {
      padding: 1rem 1.5rem;
      height: 70px;
    }
    
    h1 {
      font-size: 1.2rem;
    }
    
    .desktop-menu {
      display: none;
    }
    
    .menu-button {
      display: flex;
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
  
  /* Improve click/touch responsiveness */
  @media (hover: none) and (pointer: coarse) {
    /* Touch devices */
    .menu-button {
      padding: 1rem;
    }
    
    .mobile-menu a {
      padding: 1rem 0;
    }
  }
</style>
