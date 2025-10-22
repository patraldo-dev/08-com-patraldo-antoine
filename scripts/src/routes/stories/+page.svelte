<script>
  let { data } = $props();
  const { stories, lang } = data;
</script>

<svelte:head>
  <title>Historias</title>
</svelte:head>

<div class="layout">
  <h1>Historias</h1>
  <ul>
    {#each stories as story}
      <li><a href="/stories/{story.slug}">{story.title}</a></li>
    {/each}
  </ul>
</div>
