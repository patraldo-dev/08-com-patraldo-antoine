<script>
  // ... your existing imports and code ...
  
  let { data } = $props();
  let showAboutDetail = $state(false);
  
  // Get today's featured video (first from shuffled list)
  $: dailyVideo = data.videos.length > 0 ? data.videos[0] : null;
</script>

<!-- Your existing page content -->

{#if showAboutDetail}
  <AboutDetailModal 
    open={showAboutDetail} 
    onClose={() => showAboutDetail = false}
    dailyVideo={dailyVideo}
  />
{/if}
