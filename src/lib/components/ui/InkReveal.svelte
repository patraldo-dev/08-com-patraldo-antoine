<!-- src/lib/components/ui/InkReveal.svelte -->
<script>
  import { onMount } from 'svelte';
  
  /**
   * Simple scroll-based reveal animation
   * Use delay prop to stagger multiple elements
   */
  export let delay = 0;
  export let threshold = 0.1; // How much of element must be visible to trigger
  
  let element;
  let isVisible = false;
  
  onMount(() => {
    const observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting && !isVisible) {
            setTimeout(() => {
              isVisible = true;
            }, delay);
          }
        });
      },
      {
        threshold: threshold,
        rootMargin: '0px 0px -50px 0px' // Trigger slightly before element is fully visible
      }
    );
    
    if (element) {
      observer.observe(element);
    }
    
    return () => {
      if (element) {
        observer.unobserve(element);
      }
    };
  });
</script>

<div 
  class="ink-reveal" 
  class:visible={isVisible}
  bind:this={element}
>
  <slot />
</div>

<style>
  .ink-reveal {
    opacity: 0;
    transform: translateY(30px);
    transition: 
      opacity 0.8s cubic-bezier(0.4, 0, 0.2, 1),
      transform 0.8s cubic-bezier(0.4, 0, 0.2, 1);
  }
  
  .ink-reveal.visible {
    opacity: 1;
    transform: translateY(0);
  }
  
  /* Optional: Add a subtle "ink bleeding" effect */
  .ink-reveal.visible :global(h1),
  .ink-reveal.visible :global(h2),
  .ink-reveal.visible :global(h3) {
    animation: inkBleed 0.6s ease-out;
  }
  
  @keyframes inkBleed {
    0% {
      filter: blur(2px);
      letter-spacing: 0.05em;
    }
    100% {
      filter: blur(0);
      letter-spacing: normal;
    }
  }
  
  /* Respect prefers-reduced-motion */
  @media (prefers-reduced-motion: reduce) {
    .ink-reveal {
      transition: opacity 0.3s ease;
      transform: none;
    }
    
    .ink-reveal.visible :global(h1),
    .ink-reveal.visible :global(h2),
    .ink-reveal.visible :global(h3) {
      animation: none;
    }
  }
</style>
