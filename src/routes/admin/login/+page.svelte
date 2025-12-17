<script>
  import { goto } from '$app/navigation';
  
  let password = '';
  let error = '';
  
  function login() {
    // Replace with your actual password
    if (password === 'your-secure-password') {
      document.cookie = 'authenticated=true; path=/; max-age=3600';
      goto('/admin');
    } else {
      error = 'Invalid password';
    }
  }
</script>

<div class="login-container">
  <h1>Admin Login</h1>
  
  {#if error}
    <div class="error">{error}</div>
  {/if}
  
  <form on:submit|preventDefault={login}>
    <div class="form-group">
      <label for="password">Password</label>
      <input 
        type="password" 
        id="password" 
        bind:value={password} 
        required 
      />
    </div>
    
    <button type="submit">Login</button>
  </form>
</div>

<style>
  .login-container {
    max-width: 400px;
    margin: 4rem auto;
    padding: 2rem;
    border: 1px solid #ddd;
    border-radius: 8px;
  }
  
  h1 {
    margin-bottom: 1.5rem;
    text-align: center;
  }
  
  .form-group {
    margin-bottom: 1.5rem;
  }
  
  label {
    display: block;
    margin-bottom: 0.5rem;
  }
  
  input {
    width: 100%;
    padding: 0.75rem;
    border: 1px solid #ddd;
    border-radius: 4px;
    font-size: 1rem;
  }
  
  button {
    width: 100%;
    padding: 0.75rem;
    background: #667eea;
    color: white;
    border: none;
    border-radius: 4px;
    font-size: 1rem;
    cursor: pointer;
  }
  
  .error {
    color: #e53e3e;
    margin-bottom: 1rem;
    padding: 0.5rem;
    background: #ffebee;
    border-radius: 4px;
  }
</style>
