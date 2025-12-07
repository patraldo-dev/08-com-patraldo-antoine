<!-- src/routes/admin/populate-durations/+page.svelte -->
<script>
  import { onMount } from 'svelte';
  
  let status = $state('idle');
  let results = $state(null);
  let error = $state(null);
  
  async function runPopulate() {
    status = 'running';
    error = null;
    results = null;
    
    try {
      const response = await fetch('/api/admin/populate-durations?token=your-secret-token-here');
      const data = await response.json();
      
      if (data.success) {
        results = data;
        status = 'complete';
      } else {
        error = data.error;
        status = 'error';
      }
    } catch (err) {
      error = err.message;
      status = 'error';
    }
  }
</script>

<div class="admin-page">
  <h1>Populate Video Durations</h1>
  
  <p>This will fetch durations from Cloudflare Stream API and update the database.</p>
  
  <button 
    onclick={runPopulate} 
    disabled={status === 'running'}
    class="run-btn"
  >
    {status === 'running' ? 'Running...' : 'Run Population Script'}
  </button>
  
  {#if status === 'running'}
    <div class="loading">
      <div class="spinner"></div>
      <p>Processing videos... This will take about 30 seconds.</p>
    </div>
  {/if}
  
  {#if results}
    <div class="results">
      <h2>✅ Complete!</h2>
      <p>Processed: {results.processed}</p>
      <p>Success: {results.successCount}</p>
      <p>Errors: {results.errorCount}</p>
      
      <details>
        <summary>View Details</summary>
        <ul>
          {#each results.results as result}
            <li class:error={result.status === 'error'}>
              {result.title}: 
              {#if result.status === 'success'}
                ✅ {result.duration}s
              {:else}
                ❌ {result.error}
              {/if}
            </li>
          {/each}
        </ul>
      </details>
    </div>
  {/if}
  
  {#if error}
    <div class="error">
      <h2>❌ Error</h2>
      <p>{error}</p>
    </div>
  {/if}
</div>

<style>
  .admin-page {
    max-width: 800px;
    margin: 4rem auto;
    padding: 2rem;
  }
  
  h1 {
    margin-bottom: 1rem;
  }
  
  .run-btn {
    padding: 1rem 2rem;
    font-size: 1.1rem;
    background: #667eea;
    color: white;
    border: none;
    border-radius: 8px;
    cursor: pointer;
    margin: 2rem 0;
  }
  
  .run-btn:disabled {
    opacity: 0.5;
    cursor: not-allowed;
  }
  
  .loading {
    text-align: center;
    padding: 2rem;
  }
  
  .spinner {
    width: 40px;
    height: 40px;
    border: 4px solid #f3f3f3;
    border-top: 4px solid #667eea;
    border-radius: 50%;
    animation: spin 1s linear infinite;
    margin: 0 auto 1rem;
  }
  
  @keyframes spin {
    to { transform: rotate(360deg); }
  }
  
  .results, .error {
    margin-top: 2rem;
    padding: 1.5rem;
    border-radius: 8px;
  }
  
  .results {
    background: #e8f5e9;
    border: 2px solid #4caf50;
  }
  
  .error {
    background: #ffebee;
    border: 2px solid #f44336;
  }
  
  details {
    margin-top: 1rem;
  }
  
  ul {
    list-style: none;
    padding: 0;
  }
  
  li {
    padding: 0.5rem;
    border-bottom: 1px solid #ddd;
  }
  
  li.error {
    color: #f44336;
  }
</style>
