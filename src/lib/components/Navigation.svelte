<!-- src/lib/components/Navigation.svelte -->
<script>
  import { goto } from '$app/navigation';
  import { page } from '$app/stores';
  import { t } from '$lib/i18n';
  import LanguageSwitcherUniversal from '$lib/components/ui/LanguageSwitcherUniversal.svelte';
  
  // Svelte 5 Runes
  let isMenuOpen = $state(false);
  let isProfileOpen = $state(false);
  let currentPath = $derived($page.url.pathname);
  let isOnHomePage = $derived(currentPath === '/');
  
  // Accept Admin Props - SVELTE 5 SYNTAX
  let { isAdmin = false, username = null } = $props();
  
  // Derive if user is authenticated
  let isAuthenticated = $derived(!!username);
  
  // Toggle Profile function
  function toggleProfile() {
    isProfileOpen = !isProfileOpen;
  }
  
  // Toggle Menu function
  function toggleMenu() {
    isMenuOpen = !isMenuOpen;
    isProfileOpen = false;
    if (typeof document !== 'undefined') {
      document.body.style.overflow = isMenuOpen ? 'hidden' : '';
    }
  }
  
  // Close Menu function
  function closeMenu() {
    isMenuOpen = false;
    isProfileOpen = false;
    if (typeof document !== 'undefined') {
      document.body.style.overflow = '';
    }
  }
  
  // Handle link click with Svelte 5 syntax
  function handleLinkClick(e, target) {
    e.preventDefault();
    e.stopPropagation();
    closeMenu();
    
    if (target.startsWith('#') && isOnHomePage) {
      // For hash links on home page
      const element = document.querySelector(target);
      if (element) {
        element.scrollIntoView({ behavior: 'smooth' });
      }
    } else {
      goto(target);
    }
  }
  
  // Handle outside click
  function handleOutsideClick(event) {
    const nav = event.target.closest('nav');
    const menuButton = event.target.closest('.menu-button');
    const profileContainer = event.target.closest('.profile-container');
    
    if (!nav && !menuButton && !profileContainer) {
      isMenuOpen = false;
      isProfileOpen = false;
    }
  }
  
  // Async logout function
  async function handleLogout(e) {
    e.stopPropagation();
    try {
      await fetch('/api/auth/logout', { method: 'POST' });
      closeMenu();
      goto('/');
      // Force reload to update auth state
      setTimeout(() => window.location.reload(), 100);
    } catch (error) {
      console.error('Logout failed:', error);
    }
  }
  
  // Handle keydown for accessibility
  function handleKeydown(e) {
    if (e.key === 'Escape') {
      closeMenu();
    }
  }
  
  // Add event listeners
  if (typeof document !== 'undefined') {
    $effect(() => {
      const handleClick = (e) => handleOutsideClick(e);
      const handleKey = (e) => handleKeydown(e);
      
      document.addEventListener('click', handleClick);
      document.addEventListener('keydown', handleKey);
      
      return () => {
        document.removeEventListener('click', handleClick);
        document.removeEventListener('keydown', handleKey);
      };
    });
  }
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
    
    <LanguageSwitcherUniversal/>
    
    <!-- Show Login button if NOT authenticated -->
    {#if !isAuthenticated}
      <a href="/login" class="login-btn" onclick={(e) => handleLinkClick(e, '/login')}>
        Login
      </a>
    {/if}

<div class="profile-container">
  {#if !isAuthenticated}
    <!-- Not logged in - show login icon -->
    <a href="/login" class="profile-trigger" onclick={(e) => handleLinkClick(e, '/login')}>
      <svg width="36" height="36" viewBox="0 0 36 36" fill="none" xmlns="http://www.w3.org/2000/svg">
        <circle cx="18" cy="18" r="18" fill="#f5f5f5"/>
        <path fill="#2c5e3d" d="M16.94 21.398a1.78 1.78 0 0 1 1.868 0l5.659 3.503a.593.593 0 0 1 .192.816l-.311.503a.59.59 0 0 1-.816.191l-5.658-3.503-5.66 3.503a.59.59 0 0 1-.814-.191l-.311-.503a.59.59 0 0 1 .191-.816zM17.87 10.5a4.677 4.677 0 1 1 0 9.353 4.677 4.677 0 0 1 0-9.353m0 1.775a2.901 2.901 0 1 0 .001 5.802 2.901 2.901 0 0 0-.001-5.802"></path>
      </svg>
    </a>
  {:else}
    <!-- Logged in - show profile icon with dropdown -->
    <div class="profile-trigger" onclick={toggleProfile}>
      <svg width="36" height="36" viewBox="0 0 36 36" fill="none" xmlns="http://www.w3.org/2000/svg">
        <circle cx="18" cy="18" r="18" fill="#2c5e3d"/>
        <path fill="white" d="M16.94 21.398a1.78 1.78 0 0 1 1.868 0l5.659 3.503a.593.593 0 0 1 .192.816l-.311.503a.59.59 0 0 1-.816.191l-5.658-3.503-5.66 3.503a.59.59 0 0 1-.814-.191l-.311-.503a.59.59 0 0 1 .191-.816zM17.87 10.5a4.677 4.677 0 1 1 0 9.353 4.677 4.677 0 0 1 0-9.353m0 1.775a2.901 2.901 0 1 0 .001 5.802 2.901 2.901 0 0 0-.001-5.802"></path>
      </svg>
    </div>
    
    {#if isProfileOpen}
      <div class="profile-dropdown">
        <div class="profile-info">
          <span class="profile-name">{username}</span>
        </div>
        {#if isAdmin}
          <a href="/admin/analytics" onclick={(e) => handleLinkClick(e, '/admin/analytics')}>
            Dashboard
          </a>
        {/if}
        <button class="logout-btn" onclick={handleLogout}>
          Logout
        </button>
      </div>
    {/if}
  {/if}
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
    <a href="/collection" onclick={(e) => handleLinkClick(e, '/collection')}>{$t('common.navCollection')}</a>
    <a href="/#contact" onclick={(e) => handleLinkClick(e, '#contact')}>{$t('common.navContact')}</a>
    
{#if !isAuthenticated}
  <a href="/login" class="mobile-login-link" onclick={(e) => handleLinkClick(e, '/login')}>
    <svg width="24" height="24" viewBox="0 0 36 36" fill="none" xmlns="http://www.w3.org/2000/svg" style="margin-right: 0.5rem;">
      <circle cx="18" cy="18" r="18" fill="#f5f5f5"/>
      <path fill="#2c5e3d" d="M16.94 21.398a1.78 1.78 0 0 1 1.868 0l5.659 3.503a.593.593 0 0 1 .192.816l-.311.503a.59.59 0 0 1-.816.191l-5.658-3.503-5.66 3.503a.59.59 0 0 1-.814-.191l-.311-.503a.59.59 0 0 1 .191-.816zM17.87 10.5a4.677 4.677 0 1 1 0 9.353 4.677 4.677 0 0 1 0-9.353m0 1.775a2.901 2.901 0 1 0 .001 5.802 2.901 2.901 0 0 0-.001-5.802"></path>
    </svg>
    Login
  </a>
{/if}
    
    <!-- Show Profile in mobile menu if authenticated -->
    {#if isAuthenticated}
      <div class="mobile-profile-section">
        <div class="mobile-profile-header">
          <div class="mobile-avatar">^<br>o</div>
          <span class="mobile-username">{username}</span>
        </div>
        {#if isAdmin}
          <a href="/admin/analytics" onclick={(e) => handleLinkClick(e, '/admin/analytics')} class="mobile-link">Dashboard</a>
        {/if}
        <button class="mobile-logout" onclick={handleLogout}>Logout</button>
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
  
  /* Login Button Styles */
  .login-btn {
    padding: 0.5rem 1.5rem;
    background: #2c5e3d;
    color: white !important;
    border-radius: 6px;
    text-decoration: none;
    font-weight: 500;
    transition: all 0.3s ease;
  }
  
  .login-btn:hover {
    background: #1e4029;
    transform: translateY(-1px);
    box-shadow: 0 4px 12px rgba(44, 94, 61, 0.3);
    opacity: 1 !important;
  }
  
  /* Profile Container & Trigger */
  .profile-container {
    position: relative;
  }

.profile-trigger {
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  transition: all 0.3s ease;
  border-radius: 50%;
}

.profile-trigger:hover {
  transform: scale(1.1);
  box-shadow: 0 4px 12px rgba(44, 94, 61, 0.2);
}

.profile-trigger svg {
  display: block;
}
  
  
  /* Profile Dropdown */
  .profile-dropdown {
    position: absolute;
    top: 110%;
    right: 0;
    width: 220px;
    background: white;
    border: 1px solid #e0e0e0;
    border-radius: 12px;
    box-shadow: 0 8px 24px rgba(0,0,0,0.12);
    padding: 1rem;
    display: flex;
    flex-direction: column;
    gap: 0.75rem;
    z-index: 1000;
  }
  
  .profile-info {
    border-bottom: 1px solid #eee;
    padding-bottom: 0.75rem;
    text-align: center;
  }
  
  .profile-name {
    font-weight: 600;
    color: #2c5e3d;
    font-size: 1rem;
  }
  
  .profile-dropdown a {
    padding: 0.5rem;
    text-align: center;
    color: #2c5e3d;
    text-decoration: none;
    border-radius: 6px;
    transition: background 0.2s;
  }
  
  .profile-dropdown a:hover {
    background: #f0f0f0;
    opacity: 1;
  }
  
  .logout-btn {
    width: 100%;
    padding: 0.75rem;
    background: #ff6b6b;
    color: white;
    border: none;
    border-radius: 6px;
    cursor: pointer;
    font-size: 0.95rem;
    font-weight: 500;
    transition: all 0.2s;
  }
  
  .logout-btn:hover {
    background: #e53e3e;
    transform: translateY(-1px);
    box-shadow: 0 2px 8px rgba(255, 107, 107, 0.3);
  }
  
  /* Mobile Styles */
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

.mobile-login-link {
  display: flex !important;
  align-items: center !important;
  padding: 0.75rem 1rem !important;
  color: #2c5e3d !important;
  font-weight: 500 !important;
  background: #f5f5f5;
  border-radius: 6px;
}
  
  .mobile-login-btn {
    padding: 1rem !important;
    background: #2c5e3d !important;
    color: white !important;
    border-radius: 6px;
    text-align: center;
    font-weight: 500 !important;
    border: none !important;
  }
  
  .mobile-login-btn:hover {
    background: #1e4029 !important;
    color: white !important;
  }
  
  /* Mobile Profile */
  .mobile-profile-section {
    display: flex;
    flex-direction: column;
    gap: 1rem;
    padding: 1rem;
    background: #f9f9f9;
    border-radius: 8px;
  }
  
  .mobile-profile-header {
    display: flex;
    align-items: center;
    gap: 1rem;
  }
  
  .mobile-avatar {
    width: 42px;
    height: 42px;
    border-radius: 50%;
    background: #2c5e3d;
    color: white;
    display: flex;
    align-items: center;
    justify-content: center;
    font-weight: bold;
    font-size: 0.85rem;
    line-height: 0.6;
    text-align: center;
  }
  
  .mobile-username {
    font-weight: 600;
    color: #2c5e3d;
  }
  
  .mobile-link {
    padding: 0.75rem 1rem !important;
    color: #2c5e3d !important;
    text-decoration: none;
    font-weight: 500 !important;
    background: white;
    border-radius: 6px;
    border: 1px solid #e0e0e0 !important;
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
    border-radius: 6px;
    font-weight: 500;
    cursor: pointer;
    transition: all 0.2s;
  }
  
  .mobile-logout:hover {
    background: #e53e3e;
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
</style>
