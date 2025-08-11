<script>
  import '../app.css';
</script>
<div class="app">
  <nav>
    <h1>Antoine Patraldo</h1>
    <div class="nav-links">
      <a href="#work">Work</a>
      <a href="#about">About</a>
      <a href="#contact">Stay Updated</a>
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
  nav {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 2rem 4rem;
    background: rgba(255, 255, 255, 0.95);
    backdrop-filter: blur(10px);
    position: fixed;
    top: 0;
    left: 0;
    right: 0;
    z-index: 100;
    border-bottom: 1px solid rgba(0, 0, 0, 0.05);
  }
  h1 {
    font-size: 1.5rem;
    font-weight: 300;
    letter-spacing: 2px;
    margin: 0;
  }
  .nav-links {
    display: flex;
    gap: 2rem;
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
    nav {
      padding: 1rem 2rem;
      flex-direction: column;
      gap: 1rem;
    }
    
    .nav-links {
      gap: 1.5rem;
    }
    
    footer {
      padding: 1rem 2rem;
    }
    main {
      margin-top: 120px;
    }
  }
</style>
