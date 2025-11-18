<script>
  import { onMount } from 'svelte';
  import { browser } from '$app/environment';
  
  let { imageUrl, artworkTitle = 'Artwork' } = $props();
  
  let colors = $state([]);
  let loading = $state(true);
  let error = $state(null);
  let copiedIndex = $state(-1);
  let ColorThief;
  
  onMount(async () => {
    // Import ColorThief only in browser
    if (browser) {
      const ColorThiefModule = await import('colorthief');
      ColorThief = ColorThiefModule.default;
      
      try {
        await extractColors();
      } catch (err) {
        console.error('Failed to extract colors:', err);
        error = 'Could not extract colors';
        loading = false;
      }
    }
  });
  
  async function extractColors() {
    if (!ColorThief) return;
    
    loading = true;
    
    // ... rest of your extractColors function stays the same
