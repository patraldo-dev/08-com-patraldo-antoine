<!-- src/lib/components/Navigation.svelte -->
<script>
  import { onMount } from 'svelte';
  import { goto } from '$app/navigation';
  import { page } from '$app/stores';
  import { t } from '$lib/i18n';
  import LanguageSwitcherUniversal from '$lib/components/ui/LanguageSwitcherUniversal.svelte';

  // Svelte 5 Runes: Use $state for local state
  let isMenuOpen = $state(false);
  let isProfileOpen = $state(false);
  let currentPath = $derived($page.url.pathname);
  let isOnHomePage = $derived(currentPath === '/');
  
  // Accept Admin Props
  let { isAdmin, username } = $props();

  // NEW: Toggle Profile function
  function toggleProfile() {
    isProfileOpen = !isProfileOpen; // Toggle state
  }

  // Existing functions (toggleMenu, closeMenu, etc...)
  // ... (Keep your existing functions like toggleMenu, handleLinkClick, etc.) ...
  
  function closeMenu() {
    isMenuOpen = false;
    isProfileOpen = false;
    if (typeof document !== 'undefined') {
      document.body.style.overflow = '';
    }
  }
  
  function handleOutsideClick(event) {
    const nav = event.target.closest('nav');
    const menuButton = event.target.closest('.menu-button');
    const profileContainer = event.target.closest('.profile-container');
    
    // If click happens outside nav, menu, AND profile dropdown, close everything
    if (!nav && !menuButton && !profileContainer) {
      isMenuOpen = false;
      isProfileOpen = false;
    }
  }

  // ... (Keep your existing functions like handleKeydown, handleLinkClick, etc.) ...

</script>

<nav>
  <a href="/" class="logo-link" onclick={(e) => handleLinkClick(e, '/')}>
    <h1>ANTOINE PATRALDO</h1>
  </a>
  
  <!-- Desktop Menu -->
  <div class="nav-links desktop-menu">
    <a href="/#work" onclick={(e) => handleLinkClick(e, '#work')}>{$t('common.navWork')}</a>
    <a href="/#about" onclick={(e) => handleLinkClick(e, '#about')}>{$t('common.navAbout')}</a>
    <a href="/stories" onclick={(e) => handleLinkClick(e, '/stories')}>{$t('common.navStories')}</a>
    <a href="/cine" onclick={(e) => handleLinkClick(e, '/cine')}>{$t('common.navCine')}</a>
    <a href="/tools" onclick={(e) => handleLinkClick(e, '/tools')}>{$t('common.navTools')}</a>
    <a href="/collection" onclick={(e) => handleLinkClick(e, '/collection')}>{$t('common.navCollection')}</a>
    <a href="/#contact" onclick={(e) => handleLinkClick(e, '#contact')}>{$t('common.navContact')}</a>
    
    <!-- NEW: User Profile Dropdown (Desktop) -->
    {#if isAdmin}
      <div class="profile-container">
        <!-- We use click to toggle, on:mouseenter is not allowed in Svelte 5 -->
        <div class="profile-trigger" onclick={toggleProfile}>
            <span class="profile-icon">o</span>
        </div>
        
        {#if isProfileOpen}
          <!-- We use on:clickoutside to close when clicking links inside the dropdown -->
          <div class="profile-dropdown" on:clickoutside>
            <div class="profile-info">
              <span class="profile-name">{username || 'Admin'}</span>
            </div>
            <button class="logout-btn" on:click={(e) => { e.stopPropagation(); // Stop bubbling so we don't toggle profile when clicking logout
  await fetch('/api/auth/logout', { method: 'POST' });
              goto('/');
            }}>
              {$t('common.navLogout')}
            </button>
          </div>
        {/if}
      </div>
    {/if}
    
    <LanguageSwitcherUniversal/>
  </div>
  
  <!-- Mobile/Tablet Menu Button -->
  <button 
    class="menu-button" 
    class:open={isMenuOpen}
    aria-label={isMenuOpen ? 'Close menu' : 'Open menu'}
    aria-expanded={isMenuOpen}
    onclick={toggleMenu}
    ontouchend={(e) => { e.preventDefault(); toggleMenu(e); }}
    type="button"
  >
    <span class="menu-line"></span>
    <span class="menu-line"></span>
  </button>
  
  <!-- Mobile Menu Overlay -->
  {#if isMenuOpen}
    <div class="menu-overlay" onclick={closeMenu}></div>
  {/if}
  
  <!-- Mobile Menu -->
  <div class="mobile-menu" class:open={isMenuOpen}>
    <a href="/#work" onclick={(e) => handleLinkClick(e, '#work')}>{$t('common.navWork')}</a>
    <a href="/#about" onclick={(e) => handleLinkClick(e, '#about')}>{$t('common.navAbout')}</a>
    <a href="/stories" onclick={(e) => handleLinkClick(e, '/stories')}>{$t('common.navStories')}</a>
    <a href="/cine" onclick={(e) => handleLinkClick(e, '/cine')}>{$t('common.navCine')}</a>
    <a href="/tools" onclick={(e) => handleLinkClick(e, '/tools')}>{$t('common.navTools')}</a>
    <a href="/collection" onclick={(e => handleLinkClick(e, '/collection')}>{$t('common.navCollection')}</a>
    <a href="/#contact" onclick={(e) => handleLinkClick(e, '#contact')}>{$t('common.navContact')}</a>
    
    <!-- NEW: Admin & Profile (Mobile) -->
    {#if isAdmin}
      <div class="mobile-profile-section">
        <div class="mobile-profile-header">
          <div class="mobile-avatar">o</div>
          <span class="mobile-username">{username || 'Admin'}</span>
        </div>
        <a href="/admin/analytics" onclick={(e) => handleLinkClick(e, '/admin/analytics')} class="mobile-link">Dashboard</a>
        <button class="mobile-logout" on:click={(e) => { e.stopPropagation(); await fetch('/api/auth/logout', { method: 'POST' }); goto('/admin'); } class="mobile-logout">{$t('common.navLogout')}</button>
      </div>
      <div class="mobile-divider"></div>
    {/if}

    <div class="mobile-lang-switcher">
      <LanguageSwitcherUniversal/>
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

  /* ADMIN LINK */
  .admin-link {
    color: #2c5e3d !important;
    font-weight: 500;
  }
  
  /* PROFILE DROPDOWN (Desktop) */
  .profile-container {
    position: relative;
    display: flex;
    align-items: center;
  }

  .profile-trigger {
    width: 40px;
    height: 40px;
    border-radius: 50%;
    background: #f5f5f5;
    border: 1px solid #e0e0e0;
    display: flex;
    align-items: center;
    justify-content: center;
    cursor: pointer;
    transition: all 0.2s ease;
    position: relative;
    font-weight: 700;
    color: #2c5e3d;
  }

  .profile-trigger:hover {
    background: #ffffff;
    transform: scale(1.05);
    box-shadow: 0 2px 8px rgba(0,0,0,0.1);
  }

  .profile-icon {
    font-size: 1.2rem;
    line-height: 1;
  }

  .profile-dropdown {
    position: absolute;
    top: 110%;
    right: 0;
    width: 200px;
    background: white;
    border: 1px solid #eee;
    border-radius: 8px;
    box-shadow: 0 4px 12px rgba(0,0,0,0.15);
    padding: 1rem;
    display: flex;
    flex-direction: column;
    gap: 0.5rem;
    pointer-events: none; /* Prevents mouseleave from flickering */
  }

  /* Make the dropdown visible if active */
  .profile-dropdown {
    display: flex;
    opacity: 0; 
    transform: translateY(-10px);
    transition: opacity 0.2s ease 0.2s;
    visibility: hidden;
  }

  .profile-dropdown.open {
    opacity: 1;
    transform: translateY(0);
    visibility: visible;
  }

  .profile-info {
    border-bottom: 1px solid #eee;
    padding-bottom: 0.5rem;
    margin-bottom: 0.5rem;
    text-align: center;
  }

  .profile-name {
    font-weight: 500;
    color: #333;
    font-size: 0.9rem;
  }

  .logout-btn {
    width: 100%;
    padding: 0.5rem 1rem;
    background: #ff6b6b;
    color: white;
    border: none;
    border-radius: 4px;
    cursor: pointer;
    font-size: 0.9rem;
    transition: background 0.2s;
  }

  .logout-btn:hover {
    background: #e53e3e;
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
    display: flex;
    align-items: center;
    min-height: 48px;
    cursor: pointer;
  }
  
  .mobile-menu a:hover,
  .mobile-menu a:active {
    color: #2c5e3d;
  }

  /* Mobile Profile Styles */
  .mobile-profile-section {
    display: flex;
    flex-direction: column;
    gap: 1rem;
    padding: 1rem 1rem 0;
    background: #f9f9f9;
    border-radius: 8px;
  }

  .mobile-profile-header {
    display: flex;
    align-items: center;
    gap: 1rem;
  }

  .mobile-avatar {
    width: 40px;
    height: 40px;
    border-radius: 50%;
    background: #2c5e3d;
    color: white;
    display: flex;
    align-items: center;
    justify-content: center;
    font-weight: bold;
    font-size: 1.2rem;
  }

  .mobile-username {
    font-weight: 500;
    color: #333;
  }

  .mobile-link {
    color: #2c5e3d;
    text-decoration: none;
    font-weight: 500;
    padding: 1rem 0;
    background: white;
    border-radius: 4px;
  }

  .mobile-link:hover {
    background: #f5f5f5;
  }

  .mobile-divider {
    height: 1px;
    background: #eee;
    margin: 0.5rem 0;
  }

  .mobile-logout {
    background: #ff6b6b;
    color: white;
    border: none;
    padding: 1rem;
    border-radius: 4px;
    font-weight: 500;
    text-align: center;
    margin-top: 0.5rem;
    font-size: 0.9rem;
  }

  .mobile-lang-switcher {
    position: absolute;
    top: 1.5rem;
    right: 2rem;
  }

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
  
  @media (min-width: 769px) and (max-width: 1024px) {
    .desktop-menu {
      display: none;
    }
    
    .menu-button {
      display: flex;
    }
  }

  @media (hover: none) and (pointer: coarse) {
    .menu-button {
      padding: 1rem;
    }
    
    .mobile-menu a {
      padding: 1rem 0;
    }
  }
</style>
