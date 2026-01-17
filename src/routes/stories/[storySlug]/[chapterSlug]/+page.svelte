<script>
  import { CF_IMAGES_ACCOUNT_HASH } from '$lib/config.js';
  
  let { data } = $props();
  const { chapter, content, artwork } = data;

  function createImageUrl(imageId, variant = '') {
    const baseUrl = `https://imagedelivery.net/${CF_IMAGES_ACCOUNT_HASH}/${imageId}`;
    return variant ? `${baseUrl}/${variant}` : baseUrl;
  }
</script>

<svelte:head>
  <title>{chapter.storyTitle} - {chapter.title}</title>
  <meta name="description" content="Read {chapter.storyTitle}" />
</svelte:head>

<div class="story-page">
  <!-- 1. Header / Nav -->
  <nav class="story-nav">
    <a href="/stories">← Back to Stories</a>
    <span>{chapter.storyTitle}</span>
  </nav>

  <!-- 2. Hero Section (If artwork exists) -->
  {#if artwork}
    <div class="hero-section">
      {#if artwork.video_id && artwork.type === 'animation'}
        <div class="video-container">
           <iframe 
            src={`https://customer-9kroafxwku5qm6fx.cloudflarestream.com/${artwork.video_id}/iframe`}
            allow="accelerometer; gyroscope; autoplay; encrypted-media; picture-in-picture"
            allowfullscreen
          ></iframe>
        </div>
      {:else}
        <img 
          src={createImageUrl(artwork.image_id, 'desktop')} 
          alt={artwork.title} 
        />
      {/if}
    </div>
  {/if}

  <!-- 3. Story Content -->
  <div class="story-container">
    <h1>{chapter.title}</h1>
    
    {#if content.length === 0}
      <p class="empty-state">No story content has been written for this chapter yet.</p>
    {:else}
      {#each content as item}
        <div class="content-block {item.content_type}">
          {#if item.content_type === 'heading'}
            <h2>{item.content_text}</h2>
          
          {:else if item.content_type === 'text' || item.content_type === 'text/markdown'}
            <div class="paragraph">
              <!-- We use white-space: pre-wrap for Markdown paragraphs -->
              {item.content_text}
            </div>
          
          {:else if item.content_type === 'image' && item.media_id}
            <img src={createImageUrl(item.media_id, 'desktop')} alt="Story image" />
          
          {:else if item.content_type === 'video' && item.video_id}
             <iframe 
              src={`https://customer-9kroafxwku5qm6fx.cloudflarestream.com/${item.video_id}/iframe`}
              allow="accelerometer; gyroscope; autoplay; encrypted-media; picture-in-picture"
              allowfullscreen
            ></iframe>
          {/if}
        </div>
      {/each}
    {/if}
  </div>
</div>

<style>
  .story-page { background: #fafafa; min-height: 100vh; }
  
  .story-nav {
    display: flex;
    justify-content: space-between;
    padding: 2rem;
    max-width: 1000px;
    margin: 0 auto;
    font-family: 'Georgia', serif;
  }
  
  .hero-section {
    width: 100%;
    height: 60vh;
    display: flex;
    align-items: center;
    justify-content: center;
    background: #000;
    overflow: hidden;
  }
  
  .hero-section img, .hero-section iframe {
    max-width: 100%;
    max-height: 100%;
    object-fit: contain;
  }
  
  .story-container {
    max-width: 700px;
    margin: -50px auto 4rem;
    background: white;
    padding: 3rem;
    box-shadow: 0 10px 30px rgba(0,0,0,0.1);
    border-radius: 8px;
    position: relative;
    z-index: 10;
  }
  
  .story-container h1 {
    font-family: 'Georgia', serif;
    color: #2c5e3d;
    font-size: 2.5rem;
    margin-bottom: 2rem;
    border-bottom: 2px solid #d4c9a8;
    padding-bottom: 1rem;
  }
  
  .content-block { margin-bottom: 2rem; }
  
  .content-block h2 {
    font-size: 1.8rem;
    color: #2c5e3d;
    margin: 1.5rem 0 1rem;
  }
  
  .paragraph {
    font-family: 'Georgia', serif;
    font-size: 1.15rem;
    line-height: 1.8;
    color: #333;
    white-space: pre-wrap; /* Preserves line breaks from your script */
  }
  
  .empty-state {
    font-style: italic;
    color: #999;
    text-align: center;
    padding: 2rem;
  }
</style>
