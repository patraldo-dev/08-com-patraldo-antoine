<script>
  // ... your imports
  const { data } = $props();
  
  let dailyVideo = $state(null);

  // Your existing random selection logic
  $effect(() => {
    if (data.videos.length > 0 && !dailyVideo) {
      // Use your existing random/shuffle logic here
      const randomIndex = Math.floor(Math.random() * data.videos.length);
      dailyVideo = data.videos[randomIndex];
    }
  });
</script>

<!-- Main Page Content -->
<main>
  <!-- Your other content -->
  
  <section class="about">
    <h2>About</h2>
    {#if dailyVideo}
      <div class="featured-video">
        <video src={dailyVideo.url} controls />
        <p>Today's featured: {dailyVideo.title}</p>
      </div>
    {/if}
    <button onclick={openAboutDetail}>Learn More</button>
  </section>
</main>

<!-- Modal (uses same dailyVideo) -->
{#if showAboutDetail}
  <AboutDetailModal 
    open={showAboutDetail} 
    onClose={closeAboutDetail}
    dailyVideo={dailyVideo}  <!-- Same random video -->
  />
{/if}
