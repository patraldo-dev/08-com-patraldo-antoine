<script>
  let { data } = $props();
  let email = $state(''); 
  let password = $state('');
  let error = $state('');
  
  async function handleLogin(event) {
    event.preventDefault();  // ← Svelte 5 way
    
    try {
      const response = await fetch('/api/auth/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email, password })
      });
      
      if (response.ok) {
        window.location.href = '/';
      } else {
        error = 'Invalid credentials';
      }
    } catch (e) {
      error = 'Login failed';
    }
  }
</script>

<div class="login-page">
  <form on:submit={handleLogin} class="login-form">  <!-- ← Fixed syntax -->
    <h1>Login</h1>
    
    {#if error}
      <div class="error">{error}</div>
    {/if}
    
    <input bind:value={email} type="email" placeholder="Email" required />
    <input bind:value={password} type="password" placeholder="Password" required />
    <button type="submit">Login</button>
  </form>
</div>

<style>
  .login-page { max-width: 400px; margin: 100px auto; padding: 2rem; }
  .login-form input { width: 100%; padding: 1rem; margin: 0.5rem 0; border: 1px solid #ddd; border-radius: 4px; }
  button { width: 100%; padding: 1rem; background: #2c5e3d; color: white; border: none; border-radius: 4px; cursor: pointer; }
  .error { color: red; margin: 1rem 0; }
</style>

