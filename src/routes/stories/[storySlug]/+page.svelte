<script>
  let { data } = $props();
  const { story, chapters, lang } = data;
</script>

<svelte:head>
  <title>{story.title}</title>
</svelte:head>

<div class="layout">
  <h1>{story.title}</h1>
  <p>{story.description}</p>
  
  <h2>Capítulos</h2>
  <ul>
    {#each chapters as chapter}
      <li><a href="/stories/{story.slug}/{chapter.slug}">{chapter.title}</a></li>
    {/each}
  </ul>
</div>
