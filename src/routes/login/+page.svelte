<script>
  let { data } = $props();
  let email = $state(''); 
  let password = $state('');
  let error = $state('');
  
  async function handleLogin() {
    const response = await fetch('/api/auth/login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, password })
    });
    
    if (response.ok) window.location.href = '/';
    else error = 'Invalid credentials';
  }
</script>

<div class="login-form">
  <h1>Login</h1>
  {#if error}<div class="error">{error}</div>{/if}
  <form onsubmit|preventDefault={handleLogin}>
    <input bind:value={email} type="email" placeholder="Email" required />
    <input bind:value={password} type="password" placeholder="Password" required />
    <button>Login</button>
  </form>
</div>

