<script>
  import { goto } from '$app/navigation';
  import '../app.css';
  import { onMount } from 'svelte';
  
  let isMenuOpen = false;
  
  function toggleMenu() {
    isMenuOpen = !isMenuOpen;
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
  
  // Navigate to a route and close the menu
  function navigateTo(path) {
    goto(path);
    closeMenu();
  }
</script>

<div class="app">
  <nav>
    <a href="/" class="logo-link">
      <h1>ANTOINE PATRALDO</h1>
    </a>
    
    <!-- Desktop Menu -->
    <div class="nav-links desktop-menu">
      <a href="/work" on:click={() => navigateTo('/work')}>Work</a>
      <a href="/about" on:click={() => navigateTo('/about')}>About</a>
      <a href="/contact" on:click={() => navigateTo('/contact')}>Stay Updated</a>
      <a href="/admin" on:click={() => navigateTo('/admin')}>Admin</a>
    </div>
    
    <!-- Mobile/Tablet Menu Button -->
    <button 
      class="menu-button" 
      class:open={isMenuOpen}
      aria-label="Toggle menu"
      aria-expanded={isMenuOpen}
      on:click={toggleMenu}
    >
      <span class="menu-line"></span>
      <span class="menu-line"></span>
    </button>
    
    <!-- Mobile/Tablet Menu -->
    {#if isMenuOpen}
      <div class="mobile-menu">
        <a href="/work" on:click={() => navigateTo('/work')}>Work</a>
        <a href="/about" on:click={() => navigateTo('/about')}>About</a>
        <a href="/contact" on:click={() => navigateTo('/contact')}>Stay Updated</a>
        <a href="/admin" on:click={() => navigateTo('/admin')}>Admin</a>
      </div>
    {/if}
  </nav>
  
  <main>
    <slot />
  </main>
  
  <footer>
    <p>&copy; 2025 Antoine Patraldo. All rights reserved.</p>
  </footer>
</div>
