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
  
  // Accept props
  let { isAdmin = false, username = null } = $props();
  
  // Derive authenticated state
  let isAuthenticated = $derived(!!username);
  
  // Toggle functions
  function toggleProfile() {
    isProfileOpen = !isProfileOpen;
  }

 // Handler for hash links only
  function handleHashLink(e, hash) {
    e.preventDefault();
    e.stopPropagation();
    closeMenu();
    
    if (isOnHomePage) {
      const element = document.querySelector(hash);
      if (element) {
        element.scrollIntoView({ behavior: 'smooth' });
      }
    } else {
      goto('/' + hash);
    }
  }
  
  // Handler for regular links - just close menu
  function handleRegularLink() {
    closeMenu();
  } 
  function toggleMenu() {
    isMenuOpen = !isMenuOpen;
    isProfileOpen = false;
    if (typeof document !== 'undefined') {
      document.body.style.overflow = isMenuOpen ? 'hidden' : '';
    }
  }
  
  function closeMenu() {
    isMenuOpen = false;
    isProfileOpen = false;
    if (typeof document !== 'undefined') {
      document.body.style.overflow = '';
    }
  }
  
  function handleLinkClick(e, target) {
    e.preventDefault();
    e.stopPropagation();
    closeMenu();
    
    if (target.startsWith('#') && isOnHomePage) {
      const element = document.querySelector(target);
      if (element) {
        element.scrollIntoView({ behavior: 'smooth' });
      }
    } else {
      goto(target);
    }
  }
  
  function handleOutsideClick(event) {
    const nav = event.target.closest('nav');
    const menuButton = event.target.closest('.menu-button');
    const profileContainer = event.target.closest('.profile-container');
    
    if (!nav && !menuButton && !profileContainer) {
      isMenuOpen = false;
      isProfileOpen = false;
    }
  }
  
  async function handleLogout(e) {
    e.stopPropagation();
    try {
      await fetch('/api/auth/logout', { method: 'POST' });
      closeMenu();
      goto('/');
      setTimeout(() => window.location.reload(), 100);
    } catch (error) {
      console.error('Logout failed:', error);
    }
  }
  
  function handleKeydown(e) {
    if (e.key === 'Escape') {
      closeMenu();
    }
  }
  
  // Event listeners
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
  <a href="/" class="logo-link">
    <h1>ANTOINE PATRALDO</h1>
  </a>
  
  <!-- Desktop Menu -->
  <div class="nav-links desktop-menu">
    <!-- Hash links use handleHashLink -->
    <a href="/#work" onclick={(e) => handleHashLink(e, '#work')}>{$t('common.navWork')}</a>
    <a href="/#about" onclick={(e) => handleHashLink(e, '#about')}>{$t('common.navAbout')}</a>
    
    <!-- Regular links just close menu on click -->
    <a href="/stories" onclick={handleRegularLink}>{$t('common.navStories')}</a>
    <a href="/cine" onclick={handleRegularLink}>{$t('common.navCine')}</a>
    <a href="/tools" onclick={handleRegularLink}>{$t('common.navTools')}</a>
    <a href="/collection" onclick={handleRegularLink}>{$t('common.navCollection')}</a>
    
    <!-- Hash link -->
    <a href="/#contact" onclick={(e) => handleHashLink(e, '#contact')}>{$t('common.navContact')}</a>
    
    <LanguageSwitcherUniversal/>
    
    <!-- Profile/Login container stays the same -->
    <div class="profile-container">
      {#if !isAuthenticated}
        <a href="/login" class="profile-trigger login-svg" onclick={handleRegularLink} title={$t('common.login')}>
          <svg width="36" height="36" viewBox="0 0 36 36" fill="none">
            <circle cx="18" cy="18" r="18" fill="#f5f5f5"/>
            <path fill="#2c5e3d" d="M16.94 21.398a1.78 1.78 0 0 1 1.868 0l5.659 3.503a.593.593 0 0 1 .192.816l-.311.503a.59.59 0 0 1-.816.191l-5.658-3.503-5.66 3.503a.59.59 0 0 1-.814-.191l-.311-.503a.59.59 0 0 1 .191-.816zM17.87 10.5a4.677 4.677 0 1 1 0 9.353 4.677 4.677 0 0 1 0-9.353m0 1.775a2.901 2.901 0 1 0 .001 5.802 2.901 2.901 0 0 0-.001-5.802"/>
          </svg>
        </a>
      {:else}
        <div class="profile-trigger" onclick={toggleProfile} title={username}>
          <svg width="36" height="36" viewBox="0 0 36 36" fill="none">
            <circle cx="18" cy="18" r="18" fill="#2c5e3d"/>
            <path fill="white" d="M16.94 21.398a1.78 1.78 0 0 1 1.868 0l5.659 3.503a.593.593 0 0 1 .192.816l-.311.503a.59.59 0 0 1-.816.191l-5.658-3.503-5.66 3.503a.59.59 0 0 1-.814-.191l-.311-.503a.59.59 0 0 1 .191-.816zM17.87 10.5a4.677 4.677 0 1 1 0 9.353 4.677 4.677 0 0 1 0-9.353m0 1.775a2.901 2.901 0 1 0 .001 5.802 2.901 2.901 0 0 0-.001-5.802"/>
          </svg>
        </div>
        
        {#if isProfileOpen}
          <div class="profile-dropdown">
            <div class="profile-info">
              <span class="profile-name">{username}</span>
            </div>
            {#if isAdmin}
              <a href="/admin/analytics" onclick={handleRegularLink}>
                {$t('common.dashboard')}
              </a>
            {/if}
            <button class="logout-btn" onclick={handleLogout}>
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" style="margin-right: 0.5rem;">
                <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4m0 0L9 7m0-3l3 3m6.447 2.472A6.5 6.5 0 0 1 19 12a6.5 6.5 0 0 1-7.553 6.472M13 13a3 3 0 1 1-6 0 3 3 0 0 1 6 0z" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
              </svg>
              {$t('common.logout')}
            </button>
          </div>
        {/if}
      {/if}
    </div>
  </div>
  
  <!-- Mobile menu - same pattern -->
  <button class="menu-button" class:open={isMenuOpen} onclick={toggleMenu} type="button">
    <span class="menu-line"></span>
    <span class="menu-line"></span>
  </button>
  
  {#if isMenuOpen}
    <div class="menu-overlay" onclick={closeMenu}></div>
  {/if}
  
  <div class="mobile-menu" class:open={isMenuOpen}>
    <!-- Hash links -->
    <a href="/#work" onclick={(e) => handleHashLink(e, '#work')}>{$t('common.navWork')}</a>
    <a href="/#about" onclick={(e) => handleHashLink(e, '#about')}>{$t('common.navAbout')}</a>
    
    <!-- Regular links -->
    <a href="/stories" onclick={handleRegularLink}>{$t('common.navStories')}</a>
    <a href="/cine" onclick={handleRegularLink}>{$t('common.navCine')}</a>
    <a href="/tools" onclick={handleRegularLink}>{$t('common.navTools')}</a>
    <a href="/collection" onclick={handleRegularLink}>{$t('common.navCollection')}</a>
    
    <!-- Hash link -->
    <a href="/#contact" onclick={(e) => handleHashLink(e, '#contact')}>{$t('common.navContact')}</a>
    
    {#if isAuthenticated}
      <div class="mobile-profile-section">
        <div class="mobile-profile-header">
          <div class="mobile-avatar">^<br>o</div>
          <span class="mobile-username">{username}</span>
        </div>
        {#if isAdmin}
          <a href="/admin/analytics" onclick={handleRegularLink} class="mobile-link">
            {$t('common.dashboard')}
          </a>
        {/if}
        <button class="mobile-logout" onclick={handleLogout}>{$t('common.logout')}</button>
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
  
  .logo-link { text-decoration: none; color: inherit; z-index: 2; }
  .logo-link:hover h1 { opacity: 0.8; }
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
  
  .nav-links a:hover { opacity: 0.6; }
  
  /* Profile Container */
  .profile-container { position: relative; }
  
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
  
  .profile-trigger svg { display: block; }
  
  /* Login SVG specific */
  .login-svg:hover {
    box-shadow: 0 4px 12px rgba(44, 94, 61, 0.3);
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
  
  .profile-dropdown a:hover { background: #f0f0f0; }
  
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
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 0.5rem;
  }
  
  .logout-btn:hover {
    background: #e53e3e;
    transform: translateY(-1px);
    box-shadow: 0 2px 8px rgba(255, 107, 107, 0.3);
  }
  
  /* Mobile Styles - ALL SAME AS BEFORE */
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
  }
  
  .menu-line {
    width: 24px;
    height: 2px;
    background-color: #2a2a2a;
    transition: all 0.3s ease;
    position: absolute;
    left: 12px;
  }
  
  .menu-line:first-child { top: 16px; }
  .menu-line:last-child { bottom: 16px; }
  
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
  }
  
  .mobile-menu.open { transform: translateX(0); }
  
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
  .mobile-menu a:active { color: #2c5e3d; }
  
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
  
  .mobile-username { font-weight: 600; color: #2c5e3d; }
  
  .mobile-link {
    padding: 0.75rem 1rem;
    color: #2c5e3d;
    text-decoration: none;
    font-weight: 500;
    background: white;
    border-radius: 6px;
    border: 1px solid #e0e0e0;
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
  
  .mobile-logout:hover { background: #e53e3e; }
  
  .mobile-lang-switcher {
    position: absolute;
    top: 1.5rem;
    right: 2rem;
  }
  
  /* Responsive */
  @media (max-width: 768px) {
    nav { padding: 1rem 1.5rem; height: 70px; }
    h1 { font-size: 1.2rem; }
    .desktop-menu { display: none; }
    .menu-button { display: flex; }
  }
  
  @media (min-width: 769px) and (max-width: 1024px) {
    .desktop-menu { display: none; }
    .menu-button { display: flex; }
  }

.admin-dropdown { position: relative; }
.admin-link { 
  cursor: pointer; 
  padding: 0.5rem 1rem; 
  border-radius: 6px; 
  transition: background 0.2s;
}
.admin-link:hover { background: #f0f0f0; }
.dropdown-menu {
  position: absolute; top: calc(100% + 0.5rem); right: 0;
  background: white; border-radius: 8px; box-shadow: 0 4px 20px rgba(0,0,0,0.15);
  padding: 0.5rem 0; min-width: 200px; display: none;
}
.admin-dropdown:hover .dropdown-menu { display: block; }
.dropdown-menu a {
  display: block; padding: 0.75rem 1.25rem; color: #4a4a3c;
  text-decoration: none; font-size: 0.95rem;
}
.dropdown-menu a:hover { background: #f8f7f4; color: #2c5e3d; }

</style>

