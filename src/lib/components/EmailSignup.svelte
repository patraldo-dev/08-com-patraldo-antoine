<script>
  let email = '';
  let isSubmitting = false;
  let message = '';
  let messageType = '';
  async function handleSubmit() {
    if (!email) return;
    
    isSubmitting = true;
    message = '';
    
    try {
      const response = await fetch('/api/subscribe', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({ email })
      });
      
      const result = await response.json();
      
      if (response.ok) {
        message = 'Please check your email to confirm your subscription!';
        messageType = 'success';
        email = '';
      } else {
        message = result.message || 'Something went wrong. Please try again.';
        messageType = 'error';
      }
    } catch (error) {
      message = 'Network error. Please try again.';
      messageType = 'error';
    }
    
    isSubmitting = false;
  }
</script>
<form on:submit|preventDefault={handleSubmit} class="signup-form">
  <div class="input-group">
    <input
      type="email"
      bind:value={email}
      placeholder="your@email.com"
      required
      disabled={isSubmitting}
      aria-label="Email address"
    />
    <button type="submit" disabled={isSubmitting || !email}>
      {isSubmitting ? 'Joining...' : 'Join'}
    </button>
  </div>
  
  {#if message}
    <div class="message {messageType}" role="alert">
      {message}
    </div>
  {/if}
</form>
<style>
  .signup-form {
    max-width: 400px;
    margin: 0 auto;
  }
  .input-group {
    display: flex;
    gap: 0;
    border-radius: 6px;
    overflow: hidden;
    box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
  }
  input {
    flex: 1;
    padding: 1rem 1.5rem;
    border: none;
    font-size: 1rem;
    outline: none;
    background: white;
    font-family: inherit;
  }
  button {
    padding: 1rem 2rem;
    border: none;
    background: #667eea;
    color: white;
    font-size: 1rem;
    font-weight: 500;
    cursor: pointer;
    transition: background-color 0.3s;
    font-family: inherit;
  }
  button:hover:not(:disabled) {
    background: #5a6fd8;
  }
  button:disabled {
    background: #ccc;
    cursor: not-allowed;
  }
  .message {
    margin-top: 1rem;
    padding: 0.75rem;
    border-radius: 4px;
    text-align: center;
    font-size: 0.9rem;
  }
  .message.success {
    background: #d4edda;
    color: #155724;
    border: 1px solid #c3e6cb;
  }
  .message.error {
    background: #f8d7da;
    color: #721c24;
    border: 1px solid #f1aeb5;
  }
  @media (max-width: 480px) {
    .input-group {
      flex-direction: column;
    }
    
    button {
      padding: 1rem;
    }
  }
</style>
