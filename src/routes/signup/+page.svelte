<!-- src/routes/signup/+page.svelte -->
<script>
    import { t } from '$lib/i18n';
    import { goto } from '$app/navigation';
    
    let username = '';
    let email = '';
    let password = '';
    let confirmPassword = '';
    let error = '';
    let success = '';
    let isLoading = false;
    
    async function handleSignup() {
        if (password !== confirmPassword) {
            error = t('auth.signup.passwordsMismatch');  // ✅ Add t() and quotes
            return;
        }
        
        isLoading = true;
        error = '';
        success = '';
        
        try {
            const response = await fetch('/api/auth/signup', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ username, email, password })
            });
            
            const result = await response.json();
            
            if (response.ok) {
                success = t('auth.signup.success');  // ✅ Add t() and quotes
                username = '';
                email = '';
                password = '';
                confirmPassword = '';
                
                setTimeout(() => {
                    goto('/login');
                }, 3000);
            } else {
                error = result.error || t('auth.signup.signupFailed');  // ✅ Add t() and quotes
            }
        } catch (err) {
            console.error('Signup error:', err);
            error = t('auth.signup.networkError');  // ✅ Add t() and quotes
        } finally {
            isLoading = false;
        }
    }
</script>

<svelte:head>
    <title>{$t('auth.signup.title')} | Antoine Patraldo</title>
</svelte:head>

<div class="signup-page">
    <div class="signup-card">
        <h1>{$t('auth.signup.title')}</h1>
        <p class="subtitle">{$t('auth.signup.subtitle')}</p>
        
        {#if success}
            <div class="success-message">{success}</div>
        {/if}
        
        {#if error}
            <div class="error-message">{error}</div>
        {/if}
        
        <form onsubmit={(e) => { e.preventDefault(); handleSignup(); }}>
            <div class="form-group">
                <label for="username">{$t('auth.signup.username')}</label>
                <input
                    id="username"
                    bind:value={username}
                    type="text"
                    required
                    placeholder={$t('auth.signup.usernamePlaceholder')}
                    minlength="3"
                    maxlength="32"
                    disabled={isLoading}
                    autocomplete="username"
                />
            </div>
            
            <div class="form-group">
                <label for="email">{$t('auth.signup.email')}</label>
                <input
                    id="email"
                    bind:value={email}
                    type="email"
                    required
                    placeholder={$t('auth.signup.emailPlaceholder')}
                    disabled={isLoading}
                    autocomplete="email"
                />
            </div>
            
            <div class="form-group">
                <label for="password">{$t('auth.signup.password')}</label>
                <input
                    id="password"
                    bind:value={password}
                    type="password"
                    placeholder={$t('auth.signup.passwordPlaceholder')}
                    required
                    minlength="8"
                    autocomplete="new-password"
                    disabled={isLoading}
                />
            </div>
            
            <div class="form-group">
                <label for="confirmPassword">{$t('auth.signup.confirmPassword')}</label>
                <input
                    id="confirmPassword"
                    bind:value={confirmPassword}
                    type="password"
                    placeholder={$t('auth.signup.confirmPasswordPlaceholder')}
                    required
                    autocomplete="new-password"
                    disabled={isLoading}
                />
            </div>
            
            <button type="submit" disabled={isLoading}>
                {isLoading ? $t('auth.signup.signingUp') : $t('auth.signup.signUpButton')}
            </button>
        </form>
        
        <div class="footer-links">
            <p>{$t('auth.signup.alreadyHaveAccount')} <a href="/login">{$t('auth.signup.loginLink')}</a></p>
            <a href="/">{$t('auth.signup.backToGallery')}</a>
        </div>
    </div>
</div>

<style>
    .signup-page {
        min-height: 100vh;
        display: flex;
        align-items: center;
        justify-content: center;
        background: linear-gradient(135deg, var(--color-surface) 0%, var(--color-surface) 100%);
        padding: 2rem;
    }
    
    .signup-card {
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
        font-size: 0.95rem;
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
    
    button {
        padding: 0.875rem;
        background: var(--color-green);
        color: white;
        border: none;
        border-radius: 6px;
        font-size: 1rem;
        font-weight: 500;
        cursor: pointer;
        transition: background 0.2s;
        margin-top: 0.5rem;
    }
    
    button:hover:not(:disabled) {
        background: var(--color-green-hover);
    }
    
    button:disabled {
        background: var(--color-border);
        cursor: not-allowed;
    }
    
    .footer-links {
        margin-top: 2rem;
        text-align: center;
        display: flex;
        flex-direction: column;
        gap: 1rem;
    }
    
    .footer-links p {
        margin: 0;
        color: var(--color-text-muted);
        font-size: 0.95rem;
    }
    
    .footer-links a {
        color: var(--color-green);
        text-decoration: none;
        font-weight: 500;
    }
    
    .footer-links a:hover {
        text-decoration: underline;
    }
</style>
