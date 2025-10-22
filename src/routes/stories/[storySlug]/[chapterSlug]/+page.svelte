<script>
  let { data } = $props();
  const { chapter, lang } = data;
</script>

<svelte:head>
  <title>{chapter.title}</title>
</svelte:head>

<div class="layout">
  <h1>{chapter.title}</h1>
  <div>{@html chapter.content}</div>
  
  {#if chapter.animation_url}
    <div class="video-wrapper">
      <iframe
        src={chapter.animation_url}
        title={chapter.title}
        allow="autoplay; fullscreen"
        allowfullscreen
      ></iframe>
    </div>
  {/if}
</div>

<style>
  .video-wrapper {
    margin: 2rem 0;
    aspect-ratio: 16/9;
    width: 100%;
  }
  .video-wrapper iframe {
    width: 100%;
    height: 100%;
    border: none;
    border-radius: 8px;
  }
</style>
