<!-- src/routes/stories/+page.svelte -->
<script>
  import { t } from '$lib/translations';
  import { CF_IMAGES_ACCOUNT_HASH } from '$lib/config.js';
  import { goto } from '$app/navigation';
  
  let { data } = $props();
  const { stories } = data;
  
  function openStory(story) {
    console.log('Opening story:', story);
    goto(`/story/${story.id}`);
  }
  
  function getImageUrl(story) {
    if (story.thumbnailId) {
      return `https://imagedelivery.net/${CF_IMAGES_ACCOUNT_HASH}/${story.thumbnailId}/gallery`;
    }
    return story.thumbnailUrl;
  }
</script>

<svelte:head>
  <title>{$t('site.title')} - {$t('common.nav.stories')}</title>
  <meta name="description" content="Explore the stories behind each artwork" />
</svelte:head>

<div class="stories-page">
  <div class="hero">
    <h1>{$t('pages.stories.title')}</h1>
    <p class="subtitle">{$t('pages.stories.subtitle')}</p>
  </div>
  
  <div class="stories-grid layout">
    {#if stories.length === 0}
      <div class="no-stories">
        <p>{$t('pages.stories.noStories')}</p>
      </div>
    {:else}
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
            <div class="story-overlay">
              <span class="read-story">{$t('pages.stories.readStory')}→</span>
            </div>
          </div>
          
          <div class="story-info">
            <h2>{story.display_name || story.title}</h2>
            {#if story.story_intro}
              <p class="intro">{story.story_intro}</p>
            {:else}
              <p class="description">{story.description}</p>
            {/if}
            {#if story.year}
              <span class="year">{story.year}</span>
            {/if}
          </div>
        </article>
      {/each}
    {/if}
  </div>
</div>

<style>
  .stories-page {
    min-height: 100vh;
    background: linear-gradient(180deg, #fafafa 0%, #f5f5f5 100%);
  }
  
  .hero {
    padding: 6rem 2rem 4rem;
    text-align: center;
    background: linear-gradient(135deg, #f8f7f4 0%, #edebe8 100%);
  }
  
  .hero h1 {
    font-family: 'Georgia', serif;
    font-size: 3.5rem;
    font-weight: 300;
    color: #2c5e3d;
    margin: 0 0 1rem;
    letter-spacing: 1px;
  }
  
  .subtitle {
    font-size: 1.2rem;
    color: #4a4a3c;
    font-style: italic;
    max-width: 600px;
    margin: 0 auto;
  }
  
  .stories-grid {
    padding: 4rem 2rem;
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(350px, 1fr));
    gap: 3rem;
    max-width: 1400px;
    margin: 0 auto;
  }
  
  .story-card {
    background: white;
    border-radius: 12px;
    overflow: hidden;
    box-shadow: 0 4px 12px rgba(0,0,0,0.08);
    transition: all 0.3s ease;
    cursor: pointer;
    border: 2px solid transparent;
  }
  
  .story-card:hover {
    transform: translateY(-8px);
    box-shadow: 0 12px 24px rgba(0,0,0,0.15);
    border-color: #d4c9a8;
  }
  
  .story-image {
    position: relative;
    width: 100%;
    aspect-ratio: 4/3;
    overflow: hidden;
    background: #f5f5f5;
    pointer-events: none;
  }
  
  .story-image img {
    width: 100%;
    height: 100%;
    object-fit: cover;
    transition: transform 0.3s ease;
    pointer-events: none;
  }
  
  .story-card:hover .story-image img {
    transform: scale(1.05);
  }
  
  .story-overlay {
    position: absolute;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    background: linear-gradient(to top, rgba(0,0,0,0.7), transparent);
    display: flex;
    align-items: flex-end;
    justify-content: center;
    padding: 2rem;
    opacity: 0;
    transition: opacity 0.3s ease;
    pointer-events: none; /* ADD THIS - allows clicks to pass through */
  }
  
  .story-card:hover .story-overlay {
    opacity: 1;
  }
  
  .read-story {
    color: white;
    font-size: 1.1rem;
    font-weight: 500;
    font-family: 'Georgia', serif;
    text-shadow: 0 2px 4px rgba(0,0,0,0.5);
  }
  
  .story-info {
    padding: 2rem;
  }
  
  .story-info h2 {
    font-family: 'Georgia', serif;
    font-size: 1.5rem;
    color: #2c5e3d;
    margin: 0 0 1rem;
    font-weight: 400;
  }
  
  .intro, .description {
    font-size: 0.95rem;
    line-height: 1.6;
    color: #666;
    margin: 0 0 1rem;
    display: -webkit-box;
    -webkit-line-clamp: 3;
    -webkit-box-orient: vertical;
    overflow: hidden;
  }
  
  .year {
    display: inline-block;
    font-size: 0.85rem;
    color: #999;
    font-style: italic;
  }
  
  .no-stories {
    grid-column: 1 / -1;
    text-align: center;
    padding: 4rem 2rem;
  }
  
  .no-stories p {
    font-size: 1.2rem;
    color: #666;
    font-style: italic;
  }
  
  @media (max-width: 768px) {
    .hero h1 {
      font-size: 2.5rem;
    }
    
    .subtitle {
      font-size: 1rem;
    }
    
    .stories-grid {
      grid-template-columns: 1fr;
      gap: 2rem;
      padding: 2rem 1rem;
    }
    
    .story-info {
      padding: 1.5rem;
    }
    
    .story-info h2 {
      font-size: 1.3rem;
    }
  }
  
  @media (max-width: 480px) {
    .hero {
      padding: 4rem 1rem 3rem;
    }
    
    .hero h1 {
      font-size: 2rem;
    }
  }
</style>
