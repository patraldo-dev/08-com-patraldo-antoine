<!-- src/lib/components/ui/InkReveal.svelte -->
<script>
  /**
   * InkReveal: Animated text that appears and disappears in sync with hero video
   * @param {string} text - The text to display (supports i18n keys via $t())
   * @param {number} fadeInAt - Time (in seconds) to start fade-in (e.g., 8)
   * @param {number} fadeOutAt - Time (in seconds) to start fade-out (e.g., 15)
   * @param {boolean} isScroll - Special handling for scroll indicator (float animation)
   */
  export let text = '';
  export let fadeInAt = 0;
  export let fadeOutAt = 15;
  export let isScroll = false;

  // Convert seconds to milliseconds for animation delays
  $: fadeInDelay = fadeInAt * 1000;
  $: fadeOutDelay = fadeOutAt * 1000;
</script>

{#if isScroll}
  <div
    class="ink-reveal scroll-indicator"
    style="
      animation:
        fadeInUp 1s ease-out {fadeInDelay}ms forwards,
        floatVisible 2s ease-in-out {fadeOutDelay - 1000}ms infinite;
    "
    role="button"
    tabindex="0"
    on:click
    on:keydown={(e) => e.key === 'Enter' && dispatch('click')}
  >
    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
      <path d="M12 5v14M19 12l-7 7-7-7"/>
    </svg>
  </div>
{:else}
  <span
    class="ink-reveal"
    style="
      animation:
        fadeInUp 1s ease-out {fadeInDelay}ms forwards,
        fadeOutDown 1s ease-out {fadeOutDelay}ms forwards;
    "
  >{text}</span>
{/if}

<style>
  /* Shared animation keyframes (imported from global CSS) */
  /* These must be in app.css or a shared stylesheet */
</style>
