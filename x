{#each stories as story}
  <article
    class="story-card"
    on:click={() => openStory(story)}
    on:keydown={(e) => e.key === 'Enter' && openStory(story)}
    role="button"
    tabindex="0"
  >
    <div class="story-image">
      <img
        src={getImageUrl(story)}
        alt={story.display_name || story.title}
        loading="lazy"
      />
    </div>
    <!-- Your other story card content -->
  </article>
{/each}

