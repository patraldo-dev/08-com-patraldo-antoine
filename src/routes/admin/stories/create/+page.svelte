<script>
  import { enhance } from '$app/forms';
  import { page } from '$app/stores';
  
  let { data } = $props();

  // 1. Initialize local state from URL params (Initial Load)
  const params = $page.url.searchParams;
  
  // Helper to generate slug
  const generateSlug = (text) => {
    if (!text) return '';
    return text.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/(^-|-$)/g, '');
  };

  // 2. Define reactive form state
  // We check 'data.form' first (if a previous submission failed with an error)
  // Otherwise, we check URL params (from your Bash script)
  let formState = $state({
    title: data.form?.title || params.get('title') || '',
    slug: data.form?.slug || generateSlug(params.get('title')),
    chapterTitle: data.form?.chapterTitle || 'Chapter 1',
    artId: data.form?.artworkId || params.get('artwork_id') || '',
    content: data.form?.content || ''
  });

  // Update slug automatically when title changes (only if user hasn't manually edited it yet)
  $effect(() => {
    if (!data.form?.slug && !params.get('title')) {
       formState.slug = generateSlug(formState.title);
    }
  });
</script>

<div class="admin-container">
  <h1>Write a New Story / Script</h1>
  
  <div class="writer-layout">
    <!-- Sidebar / Meta Data -->
    <div class="meta-panel">
      <form method="POST" use:enhance class="story-form">
        {#if data.form?.error}
          <p class="error">{data.form.error}</p>
        {/if}

        <div class="form-group">
          <label for="title">Story Title</label>
          <input type="text" name="title" id="title" bind:value={formState.title} required />
        </div>

        <div class="form-group">
          <label for="slug">URL Slug (e.g. my-first-story)</label>
          <input type="text" name="slug" id="slug" bind:value={formState.slug} required />
        </div>

        <div class="form-group">
          <label for="chapterTitle">Chapter / Script Title</label>
          <input type="text" name="chapterTitle" id="chapterTitle" bind:value={formState.chapterTitle} />
        </div>

        <div class="form-group">
          <label for="artworkId">Link to Artwork ID (Optional)</label>
          <input type="number" name="artworkId" id="artworkId" bind:value={formState.artId} placeholder="e.g. 21" />
          <small>If this is a script for a specific image, enter the ID here.</small>
        </div>

        <button type="submit" class="btn-primary">Publish Story</button>
      </form>
    </div>

    <!-- Main Writing Area -->
    <div class="writing-panel">
      <div class="form-group full-width">
        <label for="content">Story / Script Content (Markdown Supported)</label>
        <textarea 
          name="content" 
          id="content" 
          rows="20" 
          class="markdown-editor"
          bind:value={formState.content}
        ></textarea>
      </div>
    </div>
  </div>
</div>

<style>
  .admin-container { max-width: 1200px; margin: 0 auto; padding: 2rem; }
  .writer-layout { display: grid; grid-template-columns: 300px 1fr; gap: 2rem; }
  
  @media (max-width: 768px) {
    .writer-layout { grid-template-columns: 1fr; }
  }

  .meta-panel { background: #f4f4f4; padding: 1.5rem; border-radius: 8px; height: fit-content; }
  
  .form-group { margin-bottom: 1rem; }
  .form-group label { display: block; margin-bottom: 0.5rem; font-weight: bold; font-size: 0.9rem; }
  
  input, textarea { 
    width: 100%; 
    padding: 0.8rem; 
    border: 1px solid #ddd; 
    border-radius: 4px; 
    font-family: inherit;
  }

  .markdown-editor { 
    font-family: 'Courier New', Courier, monospace; 
    line-height: 1.6; 
    background: #fff;
    color: #333;
  }

  .btn-primary {
    width: 100%;
    padding: 1rem;
    background: #000;
    color: #fff;
    border: none;
    cursor: pointer;
    font-weight: bold;
  }
  
  .btn-primary:hover { background: #333; }

  .error { color: red; background: #fee; padding: 0.5rem; margin-bottom: 1rem; border: 1px solid red; }
</style>
