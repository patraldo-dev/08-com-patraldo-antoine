<!-- src/lib/components/ui/InkReveal.svelte -->
<script>
  import { createEventDispatcher } from 'svelte';
  
  const dispatch = createEventDispatcher();
  
  /**
   * InkReveal: Animated text that appears and disappears in sync with hero video
   */
  let { 
    text = '',
    fadeInAt = 0,
    fadeOutAt = 15,
    isScroll = false,
    ...restProps
  } = $props();
  
  // Convert seconds to CSS time values using $derived
  let fadeInDelay = $derived(`${fadeInAt}s`);
  let fadeOutDelay = $derived(`${fadeOutAt}s`);
</script>

{#if isScroll}
  <div
    class="ink-reveal scroll-indicator"
    style:animation-delay={fadeInDelay}
    role="button"
    tabindex="0"
    onclick={() => dispatch('click')}
    onkeydown={(e) => e.key === 'Enter' && dispatch('click')}
    {...restProps}
  >
    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
      <path d="M12 5v14M19 12l-7 7-7-7"/>
    </svg>
  </div>
{:else}
  <span
    class="ink-reveal"
    style="
      --fade-in-delay: {fadeInDelay};
      --fade-out-delay: {fadeOutDelay};
    "
  >{text}</span>
{/if}

<style>
  .ink-reveal {
    opacity: 0;
    display: inline-block;
  }
  
  .ink-reveal:not(.scroll-indicator) {
    animation: 
      fadeInUp 1s ease-out var(--fade-in-delay) forwards,
      fadeOutDown 1s ease-out var(--fade-out-delay) forwards;
  }
  
  .scroll-indicator {
    margin-top: 2rem;
    cursor: pointer;
    transition: transform 0.2s;
    animation: 
      fadeInUp 1s ease-out var(--fade-in-delay) forwards,
      floatVisible 2s ease-in-out calc(var(--fade-in-delay) + 1s) infinite;
  }
  
  .scroll-indicator:hover {
    transform: scale(1.1);
  }
  
  .scroll-indicator:active {
    transform: scale(0.95);
  }
  
  .scroll-indicator svg {
    filter: drop-shadow(0 2px 4px rgba(0,0,0,0.5));
  }
  
  /* Animations */
  @keyframes fadeInUp {
    from {
      opacity: 0;
      transform: translateY(20px);
    }
    to {
      opacity: 1;
      transform: translateY(0);
    }
  }
  
  @keyframes fadeOutDown {
    from {
      opacity: 1;
      transform: translateY(0);
    }
    to {
      opacity: 0;
      transform: translateY(20px);
    }
  }
  
  @keyframes floatVisible {
    0%, 100% { 
      opacity: 1;
      transform: translateY(0);
    }
    50% { 
      opacity: 1;
      transform: translateY(-8px);
    }
  }
  
  /* Tablet and up */
  @media (min-width: 768px) {
    @keyframes floatVisible {
      0%, 100% { 
        opacity: 1;
        transform: translateY(0);
      }
      50% { 
        opacity: 1;
        transform: translateY(-10px);
      }
    }
  }
</style>
