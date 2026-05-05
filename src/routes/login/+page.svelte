<!-- src/routes/login/+page.svelte -->
<script>
  import { t } from '$lib/i18n';
  import { page } from '$app/stores';
  
  let identifier = '';
  let password = '';
  let error = '';
  let success = '';
  let isLoading = false;
  
  const verified = $page.url.searchParams.get('verified');
    if (verified === 'success') {
      success = t('auth.login.emailVerified'); // No $ prefix
    } else if (verified === 'already') {
      success = t('auth.login.alreadyVerified');
    }

  async function handleLogin() {
    if (!identifier || !password) {
      error = t('auth.login.enterCredentials');
      return;
    }
    
    isLoading = true;
    error = '';
    success = '';
    
    try {
      const response = await fetch('/api/auth/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ identifier, password })
      });
      
      const result = await response.json();
      
      if (response.ok) {
        const destination = result.user?.role === 'admin' ? '/admin' : '/';
        window.location.href = destination;
      } else {
        error = result.error || t('auth.login.invalidCredentials');
      }
    } catch (err) {
      console.error('Login error:', err);
      error = t('auth.login.networkError');
    } finally {
      isLoading = false;
    }
  }
</script>

<svelte:head>
  <title>{$t('auth.login.title')} | Antoine Patraldo</title>
</svelte:head>

<div class="login-page">
  <div class="login-card">
    <h1>{$t('auth.login.title')}</h1>
    <p class="subtitle">{$t('auth.login.subtitle')}</p>
    
    {#if success}
      <div class="success-message">{success}</div>
    {/if}
    
    {#if error}
      <div class="error-message">{error}</div>
    {/if}
    
    <form onsubmit={(e) => { e.preventDefault(); handleLogin(); }}>
      <div class="form-group">
        <label for="identifier">{$t('auth.login.emailOrUsername')}</label>
        <input
          id="identifier"
          type="text"
          bind:value={identifier}
          placeholder={$t('auth.login.emailPlaceholder')}
          required
          autocomplete="username"
          disabled={isLoading}
        />
      </div>
      
      <div class="form-group">
        <label for="password">{$t('auth.login.password')}</label>
        <input
          id="password"
          type="password"
          bind:value={password}
          placeholder={$t('auth.login.passwordPlaceholder')}
          required
          autocomplete="current-password"
          disabled={isLoading}
        />
      </div>
      
      <button type="submit" class="btn-login" disabled={isLoading}>
        {isLoading ? $t('auth.login.signingIn') : $t('auth.login.signInButton')}
      </button>
    </form>
    
    <div class="login-footer">
      <p>{$t('auth.login.noAccount')} <a href="/signup">{$t('auth.login.signUpLink')}</a></p>
      <a href="/">{$t('auth.login.backToGallery')}</a>
    </div>
  </div>
</div>

<style>
  .login-page {
    min-height: 100vh;
    display: flex;
    align-items: center;
    justify-content: center;
    background: linear-gradient(135deg, var(--color-surface) 0%, var(--color-surface) 100%);
    padding: 2rem;
  }
  
  .login-card {
    background: var(--color-surface-raised);
    padding: 3rem;
    border-radius: 12px;
    box-shadow: 0 4px 20px rgba(0, 0, 0, 0.1);
    max-width: 400px;
    width: 100%;
  }
  
  h1 {
    font-family: 'Georgia', serif;
    font-size: 2rem;
    color: var(--color-green);
    margin: 0 0 0.5rem;
    text-align: center;
  }
  
  .subtitle {
    text-align: center;
    color: var(--color-text-muted);
    margin: 0 0 2rem;
  }
  
  .success-message {
    background: var(--color-surface);
    color: var(--color-green);
    padding: 1rem;
    border-radius: 6px;
    margin-bottom: 1.5rem;
    border: 1px solid var(--color-border);
    text-align: center;
  }
  
  .error-message {
    background: #fee;
    color: #c33;
    padding: 0.75rem;
    border-radius: 6px;
    margin-bottom: 1.5rem;
    border: 1px solid #fcc;
  }
  
  form {
    display: flex;
    flex-direction: column;
    gap: 1.25rem;
  }
  
  .form-group {
    display: flex;
    flex-direction: column;
    gap: 0.5rem;
  }
  
  label {
    font-weight: 500;
    color: var(--color-green);
  }
  
  input {
    padding: 0.75rem;
    border: 1px solid var(--color-border);
    border-radius: 6px;
    font-size: 1rem;
    transition: border-color 0.2s;
  }
  
  input:focus {
    outline: none;
    border-color: var(--color-green);
  }
  
  input:disabled {
    background: var(--color-surface);
    cursor: not-allowed;
  }
  
  .btn-login {
    width: 100%;
    padding: 0.875rem;
    background: var(--color-green);
    color: white;
    border: none;
    border-radius: 6px;
    font-size: 1rem;
    font-weight: 500;
    cursor: pointer;
    transition: background 0.2s;
  }
  
  .btn-login:hover:not(:disabled) {
    background: var(--color-green-hover);
  }
  
  .btn-login:disabled {
    background: var(--color-border);
    cursor: not-allowed;
  }
  
  .login-footer {
    margin-top: 2rem;
    text-align: center;
    display: flex;
    flex-direction: column;
    gap: 1rem;
  }
  
  .login-footer p {
    margin: 0;
    color: var(--color-text-muted);
    font-size: 0.95rem;
  }
  
  .login-footer a {
    color: var(--color-green);
    text-decoration: none;
    font-weight: 500;
  }
  
  .login-footer a:hover {
    text-decoration: underline;
  }
</style>
