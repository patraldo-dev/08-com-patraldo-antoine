<script>
  import { t } from '$lib/translations';
  // No need for const $t = t if it works without it
</script>

<svelte:head>
  <title>{$t('pages.stories.title')}</title>
  <meta name="description" content={$t('pages.stories.description')} />
</script>

<div class="layout">
  <h1>{$t('pages.stories.title')}</h1>
  <p>{$t('pages.stories.intro')}</p>
  
  <!-- Later: list of story chapters -->
  <ul>
    <li><a href="/stories/chapter1">{$t('pages.stories.chapter1')}</a></li>
  </ul>
</div>
