<script>
  let title = '';
  let type = 'still';
  let imageId = '';
  let videoId = '';
  let description = '';
  let year = new Date().getFullYear();
  let message = '';
  let error = '';
  
  async function handleSubmit() {
    error = '';
    message = '';
    
    // Basic validation
    if (!title || !imageId || !description) {
      error = 'Please fill in all required fields';
      return;
    }
    
    if (type === 'animation' && !videoId) {
      error = 'Video ID is required for animations';
      return;
    }
    
    const newArtwork = {
      id: Date.now(), // Simple ID generation
      title,
      type,
      imageId,
      videoId: type === 'animation' ? videoId : undefined,
      description,
      year: parseInt(year),
      featured: false
    };
    
    try {
      const response = await fetch('/api/artworks', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify(newArtwork)
      });
      
      if (!response.ok) {
        throw new Error('Failed to add artwork');
      }
      
      message = 'Artwork added successfully!';
      
      // Reset form
      title = '';
      type = 'still';
      imageId = '';
      videoId = '';
      description = '';
      year = new Date().getFullYear();
    } catch (err) {
      error = err.message;
      console.error('Error adding artwork:', err);
    }
  }
</script>

<div class="admin-container">
  <h1>Add New Artwork</h1>
  
  {#if message}
    <div class="message success">{message}</div>
  {/if}
  
  {#if error}
    <div class="message error">{error}</div>
  {/if}
  
  <form on:submit|preventDefault={handleSubmit}>
    <div class="form-group">
      <label for="title">Title *</label>
      <input 
        type="text" 
        id="title" 
        bind:value={title} 
        required 
      />
    </div>
    
    <div class="form-group">
      <label for="type">Type *</label>
      <select id="type" bind:value={type}>
        <option value="still">Still Image</option>
        <option value="animation">Video</option>
        <option value="gif">GIF</option>
      </select>
    </div>
    
    <div class="form-group">
      <label for="imageId">Cloudflare Image ID *</label>
      <input 
        type="text" 
        id="imageId" 
        bind:value={imageId} 
        required 
      />
    </div>
    
    {#if type === 'animation'}
      <div class="form-group">
        <label for="videoId">Cloudflare Stream Video ID *</label>
        <input 
          type="text" 
          id="videoId" 
          bind:value={videoId} 
          required 
        />
      </div>
    {/if}
    
    <div class="form-group">
      <label for="description">Description *</label>
      <textarea 
        id="description" 
        bind:value={description} 
        required 
      ></textarea>
    </div>
    
    <div class="form-group">
      <label for="year">Year</label>
      <input 
        type="number" 
        id="year" 
        bind:value={year} 
        min="1900" 
        max={new Date().getFullYear() + 1} 
      />
    </div>
    
    <button type="submit">Add Artwork</button>
  </form>
</div>

<style>
  .admin-container {
    max-width: 800px;
    margin: 0 auto;
    padding: 2rem;
  }
  
  h1 {
    margin-bottom: 2rem;
  }
  
  .form-group {
    margin-bottom: 1.5rem;
  }
  
  label {
    display: block;
    margin-bottom: 0.5rem;
    font-weight: 500;
  }
  
  input, textarea, select {
    width: 100%;
    padding: 0.75rem;
    border: 1px solid #ddd;
    border-radius: 4px;
    font-family: inherit;
    font-size: 1rem;
  }
  
  textarea {
    min-height: 100px;
    resize: vertical;
  }
  
  button {
    padding: 0.75rem 1.5rem;
    background: #667eea;
    color: white;
    border: none;
    border-radius: 4px;
    font-size: 1rem;
    cursor: pointer;
    transition: background 0.2s;
  }
  
  button:hover {
    background: #5a67d8;
  }
  
  .message {
    padding: 1rem;
    margin-bottom: 1rem;
    border-radius: 4px;
  }
  
  .success {
    background: #e8f5e9;
    color: #388e3c;
  }
  
  .error {
    background: #ffebee;
    color: #e53e3e;
  }
</style>
