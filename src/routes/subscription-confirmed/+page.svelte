<!-- src/routes/subscription-confirmed/+page.svelte -->
<script>
  import { page } from '$app/stores';
  import { t } from '$lib/i18n';
  
  // Get locale from URL
  import { locale } from '$lib/i18n';
  
  // Set locale from URL param
  import { onMount } from 'svelte';
  import { setLocale } from '$lib/i18n';
  
  onMount(() => {
    const urlParams = new URLSearchParams(window.location.search);
    const urlLocale = urlParams.get('locale');
    if (urlLocale && ['en', 'es', 'fr'].includes(urlLocale)) {
      setLocale(urlLocale);
    }
  });
</script>

<svelte:head>
  <title>{$t('subscription.confirmedTitle')} | Antoine Patraldo</title>
  <meta name="description" content="{$t('subscription.confirmedDescription')}" />
</svelte:head>

<section class="confirmation">
  <div class="container">
    <div class="confirmation-content">
      <h2>{$t('subscription.confirmedTitle')}</h2>
      <div class="icon">✓</div>
      <p>{$t('subscription.confirmedMessage1')}</p>
      <p>{$t('subscription.confirmedMessage2')}</p>
      <a href="/" class="button">{$t('subscription.backToGallery')}</a>
    </div>
  </div>
</section>

<style>
  /* Your existing CSS remains the same */
  .confirmation {
    min-height: 70vh;
    display: flex;
    align-items: center;
    justify-content: center;
    padding: 2rem 0;
  }
  .container {
    max-width: 600px;
    margin: 0 auto;
    padding: 0 2rem;
  }
  .confirmation-content {
    background: white;
    border-radius: 8px;
    padding: 3rem;
    text-align: center;
    box-shadow: 0 4px 20px rgba(0, 0, 0, 0.08);
  }
  h2 {
    font-size: 2.5rem;
    font-weight: 300;
    margin-bottom: 1.5rem;
    color: #2a2a2a;
  }
  .icon {
    width: 80px;
    height: 80px;
    background: #667eea;
    color: white;
    border-radius: 50%;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 3rem;
    margin: 0 auto 2rem;
  }
  p {
    font-size: 1.1rem;
    color: #555;
    margin-bottom: 1.5rem;
  }
  .button {
    display: inline-block;
    padding: 1rem 2rem;
    background: #667eea;
    color: white;
    text-decoration: none;
    border-radius: 6px;
    font-weight: 500;
    transition: background-color 0.3s;
  }
  .button:hover {
    background: #5a6fd8;
  }
  @media (max-width: 768px) {
    .container {
      padding: 0 1rem;
    }
    
    .confirmation-content {
      padding: 2rem;
    }
    
    h2 {
      font-size: 2rem;
    }
  }
</style>
