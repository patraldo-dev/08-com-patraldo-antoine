<!-- src/routes/admin/artworks/upload/+page.svelte -->
<script>
  import { goto } from '$app/navigation';
  
  let step = $state(1);
  let isUploading = $state(false);
  let isFetching = $state(false);
  let isSaving = $state(false);
  let error = $state('');
  let success = $state('');
  
  let selectedFile = $state(null);
  let imagePreview = $state('');
  let uploadedImageId = $state('');
  
  let fetchedTitle = $state('');
  let fetchedFilename = $state('');
  let fetchedWidth = $state('');
  let fetchedHeight = $state('');
  
  let imageId = $state('');
  let title = $state('');
  let displayName = $state('');
  let videoId = $state('');
  let description = $state('');
  let year = $state(new Date().getFullYear());
  let artworkType = $state('still');
  let featured = $state(true);
  let published = $state(true);
  let orderIndex = $state(999);
  let storyEnabled = $state(true);
  let storyIntro = $state('');
  
  let createStory = $state(false);
  let storyTitle = $state('');
  let storySlug = $state('');
  
  $effect(() => {
    if (storyTitle && createStory) {
      storySlug = storyTitle
        .toLowerCase()
        .replace(/[^a-z0-9]+/g, '-')
        .replace(/(^-|-$)/g, '');
    }
  });
  
  function handleFileSelect(event) {
    const file = event.target.files?.[0];
    if (!file) return;
    
    if (!file.type.startsWith('image/')) {
      error = 'Please select an image file';
      return;
    }
    
    selectedFile = file;
    
    const reader = new FileReader();
    reader.onload = (e) => {
      imagePreview = e.target?.result;
    };
    reader.readAsDataURL(file);
    
    error = '';
  }
  
  async function uploadToCloudflare() {
    if (!selectedFile) {
      error = 'Please select an image first';
      return;
    }
    
    isUploading = true;
    error = '';
    
    try {
      const formData = new FormData();
      formData.append('file', selectedFile);
      
      const response = await fetch('/api/admin/upload-image', {
        method: 'POST',
        body: formData
      });
      
      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.error || 'Upload failed');
      }
      
      const data = await response.json();
      uploadedImageId = data.imageId;
      imageId = data.imageId;
      
      await fetchMetadata(data.imageId);
      
      step = 3;
      
    } catch (err) {
      error = err.message;
    } finally {
      isUploading = false;
    }
  }
  
  async function fetchMetadata(imgId) {
    isFetching = true;
    
    try {
      const response = await fetch(`/api/admin/image-metadata/${imgId}`);
      
      if (!response.ok) {
        console.warn('Could not fetch metadata');
        return;
      }
      
      const data = await response.json();
      
      if (data.title) {
        fetchedTitle = data.title;
        title = data.title;
        displayName = data.title;
      }
      
      if (data.filename) {
        fetchedFilename = data.filename;
      }
      
      if (data.width && data.height) {
        fetchedWidth = data.width;
        fetchedHeight = data.height;
      }
      
      const today = new Date().toISOString().split('T')[0];
      description = `Uploaded on ${today}. Filename: ${data.filename || title + '.jpg'}`;
      
    } catch (err) {
      console.error('Error fetching metadata:', err);
    } finally {
      isFetching = false;
    }
  }
  
  async function manualFetch() {
    if (!imageId) {
      error = 'Please enter an Image ID';
      return;
    }
    
    await fetchMetadata(imageId);
    step = 3;
  }
  
  async function saveArtwork() {
    if (!imageId || !title) {
      error = 'Image ID and Title are required';
      return;
    }
    
    if (createStory && (!storyTitle || !storySlug)) {
      error = 'Story Title and Slug are required when creating a story';
      return;
    }
    
    isSaving = true;
    error = '';
    
    try {
      const artwork = {
        title,
        display_name: displayName || title,
        type: artworkType,
        image_id: imageId,
        video_id: videoId || null,
        description,
        year: parseInt(year),
        featured: featured ? 1 : 0,
        published: published ? 1 : 0,
        order_index: parseInt(orderIndex),
        story_enabled: storyEnabled ? 1 : 0,
        story_intro: storyIntro || null
      };
      
      if (createStory) {
        artwork.create_story = true;
        artwork.story_title = storyTitle;
        artwork.story_slug = storySlug;
      }
      
      const response = await fetch('/api/admin/artworks', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(artwork)
      });
      
      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.error || 'Failed to save artwork');
      }
      
      const data = await response.json();
      
      if (createStory) {
        success = `✅ Artwork and story saved successfully! Artwork ID: ${data.id}, Story ID: ${data.storyId}`;
      } else {
        success = `✅ Artwork saved successfully! ID: ${data.id}`;
      }
      
      setTimeout(() => {
        resetForm();
        step = 1;
      }, 2000);
      
    } catch (err) {
      error = err.message;
    } finally {
      isSaving = false;
    }
  }
  
  function resetForm() {
    selectedFile = null;
    imagePreview = '';
    uploadedImageId = '';
    imageId = '';
    title = '';
    displayName = '';
    videoId = '';
    description = '';
    year = new Date().getFullYear();
    artworkType = 'still';
    featured = true;
    published = true;
    orderIndex = 999;
    storyEnabled = true;
    storyIntro = '';
    createStory = false;
    storyTitle = '';
    storySlug = '';
    error = '';
    success = '';
  }
</script>

<div class="upload-page">
  <div class="header">
    <h1>Upload New Artwork</h1>
    <button class="btn-back" onclick={() => goto('/admin/analytics')}>← Back to Admin</button>
  </div>
  
  {#if error}
    <div class="alert alert-error">{error}</div>
  {/if}
  
  {#if success}
    <div class="alert alert-success">{success}</div>
  {/if}
  
  <!-- Step Indicator -->
  <div class="steps">
    <div class="step" class:active={step === 1} class:complete={step > 1}>
      <div class="step-number">1</div>
      <div class="step-label">Upload / Enter ID</div>
    </div>
    <div class="step" class:active={step === 2} class:complete={step > 2}>
      <div class="step-number">2</div>
      <div class="step-label">Fetch Metadata</div>
    </div>
    <div class="step" class:active={step === 3}>
      <div class="step-number">3</div>
      <div class="step-label">Fill Details</div>
    </div>
  </div>
  
  <!-- Step 1: Upload or Manual Entry -->
  {#if step === 1}
    <div class="step-content">
      <div class="upload-options">
        <div class="option-card">
          <h3>Option 1: Upload New Image</h3>
          <p>Upload an image to Cloudflare Images</p>
          
          <div class="file-input-wrapper">
            <input 
              type="file" 
              accept="image/*" 
              onchange={handleFileSelect}
              id="file-input"
            />
            <label for="file-input" class="file-label">
              {selectedFile ? selectedFile.name : 'Choose Image'}
            </label>
          </div>
          
          {#if imagePreview}
            <div class="image-preview">
              <img src={imagePreview} alt="Preview" />
            </div>
          {/if}
          
          <button 
            class="btn-primary" 
            onclick={uploadToCloudflare}
            disabled={!selectedFile || isUploading}
          >
            {isUploading ? 'Uploading...' : 'Upload to Cloudflare'}
          </button>
        </div>
        
        <div class="divider">OR</div>
        
        <div class="option-card">
          <h3>Option 2: Use Existing Image ID</h3>
          <p>Enter an Image ID from Cloudflare Images</p>
          
          <input 
            type="text" 
            bind:value={imageId}
            placeholder="e.g., 62355ddb-0f6c-4251-5d8e-37a455e44000"
            class="input-text"
          />
          
          <button 
            class="btn-primary" 
            onclick={manualFetch}
            disabled={!imageId || isFetching}
          >
            {isFetching ? 'Fetching...' : 'Fetch Metadata & Continue'}
          </button>
        </div>
      </div>
    </div>
  {/if}
  
  <!-- Step 3: Form Details -->
  {#if step === 3}
    <div class="step-content">
      <form class="artwork-form" onsubmit={(e) => { e.preventDefault(); saveArtwork(); }}>
        
        <!-- Image ID (read-only) -->
        <div class="form-group">
          <label>Image ID</label>
          <input type="text" value={imageId} readonly class="input-readonly" />
        </div>
        
        {#if fetchedFilename || fetchedWidth}
          <div class="metadata-info">
            {#if fetchedFilename}
              <p><strong>Filename:</strong> {fetchedFilename}</p>
            {/if}
            {#if fetchedWidth && fetchedHeight}
              <p><strong>Dimensions:</strong> {fetchedWidth} × {fetchedHeight}</p>
            {/if}
          </div>
        {/if}
        
        <!-- Title -->
        <div class="form-group">
          <label>Title *</label>
          <input type="text" bind:value={title} required class="input-text" />
        </div>
        
        <!-- Display Name -->
        <div class="form-group">
          <label>Display Name</label>
          <input type="text" bind:value={displayName} class="input-text" 
                 placeholder="User-friendly name shown in UI" />
        </div>
        
        <!-- Description -->
        <div class="form-group">
          <label>Description</label>
          <textarea bind:value={description} rows="3" class="input-textarea"></textarea>
        </div>
        
        <!-- Year -->
        <div class="form-group">
          <label>Year</label>
          <input type="number" bind:value={year} class="input-text" />
        </div>
        
        <!-- Type -->
        <div class="form-group">
          <label>Type</label>
          <select bind:value={artworkType} class="input-select">
            <option value="still">Still</option>
            <option value="animation">Animation</option>
            <option value="gif">GIF</option>
          </select>
        </div>
        
        <!-- Video ID (optional) -->
        <div class="form-group">
          <label>Video ID (optional)</label>
          <input type="text" bind:value={videoId} class="input-text" 
                 placeholder="From Cloudflare Stream" />
        </div>
        
        <!-- Checkboxes -->
        <div class="form-group-row">
          <label class="checkbox-label">
            <input type="checkbox" bind:checked={featured} />
            Featured
          </label>
          
          <label class="checkbox-label">
            <input type="checkbox" bind:checked={published} />
            Published
          </label>
          
          <label class="checkbox-label">
            <input type="checkbox" bind:checked={storyEnabled} />
            Story Enabled
          </label>
        </div>
        
        <!-- Order Index -->
        <div class="form-group">
          <label>Order Index</label>
          <input type="number" bind:value={orderIndex} class="input-text" />
          <small>Lower numbers appear first</small>
        </div>
        
        <!-- Story Intro (if story enabled) -->
        {#if storyEnabled}
          <div class="form-group">
            <label>Story Intro</label>
            <textarea bind:value={storyIntro} rows="4" class="input-textarea"
                      placeholder="Brief introduction to the story..."></textarea>
          </div>
        {/if}
        
        <!-- Create Full Story (Optional) -->
        <div class="story-section">
          <div class="form-group">
            <label class="checkbox-label checkbox-main">
              <input type="checkbox" bind:checked={createStory} />
              <span class="checkbox-main-text">Create full story for this artwork</span>
            </label>
            <small>This will create an entry in the stories database with a dedicated story page</small>
          </div>
          
          {#if createStory}
            <div class="story-fields">
              <div class="form-group">
                <label>Story Title *</label>
                <input type="text" bind:value={storyTitle} required class="input-text" 
                       placeholder="e.g., The Journey Through Light" />
              </div>
              
              <div class="form-group">
                <label>Story Slug *</label>
                <input type="text" bind:value={storySlug} required class="input-text" 
                       placeholder="e.g., journey-through-light" />
                <small>Auto-generated from title, but you can customize it</small>
              </div>
              
              <div class="info-box">
                <strong>ℹ️ What gets created:</strong>
                <ul>
                  <li>A story entry in the stories database</li>
                  <li>A dedicated story page at <code>/stories/{storySlug}/chapter-1</code></li>
                  <li>First chapter linked to this artwork</li>
                  <li>You can add more chapters later in the Story Editor</li>
                </ul>
              </div>
            </div>
          {/if}
        </div>
        
        <!-- Actions -->
        <div class="form-actions">
          <button type="button" class="btn-secondary" onclick={() => step = 1}>
            ← Back
          </button>
          <button type="submit" class="btn-primary" disabled={isSaving}>
            {isSaving ? 'Saving...' : 'Save Artwork'}
          </button>
        </div>
      </form>
    </div>
  {/if}
</div>

<style>
  .upload-page {
    max-width: 1000px;
    margin: 0 auto;
    padding: 2rem;
  }
  
  .header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 2rem;
  }
  
  .header h1 {
    font-size: 2rem;
    color: #2c5e3d;
  }
  
  .btn-back {
    padding: 0.5rem 1rem;
    background: #f5f5f5;
    border: 1px solid #ddd;
    border-radius: 6px;
    cursor: pointer;
    transition: all 0.2s;
  }
  
  .btn-back:hover {
    background: #e8e8e8;
  }
  
  .alert {
    padding: 1rem;
    border-radius: 8px;
    margin-bottom: 1.5rem;
  }
  
  .alert-error {
    background: #fee;
    color: #c33;
    border: 1px solid #fcc;
  }
  
  .alert-success {
    background: #efe;
    color: #3c3;
    border: 1px solid #cfc;
  }
  
  /* Steps */
  .steps {
    display: flex;
    justify-content: space-between;
    margin-bottom: 3rem;
    position: relative;
  }
  
  .steps::before {
    content: '';
    position: absolute;
    top: 20px;
    left: 10%;
    right: 10%;
    height: 2px;
    background: #ddd;
    z-index: 0;
  }
  
  .step {
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 0.5rem;
    position: relative;
    z-index: 1;
  }
  
  .step-number {
    width: 40px;
    height: 40px;
    border-radius: 50%;
    background: white;
    border: 2px solid #ddd;
    display: flex;
    align-items: center;
    justify-content: center;
    font-weight: 600;
    color: #999;
  }
  
  .step.active .step-number {
    border-color: #2c5e3d;
    color: #2c5e3d;
    background: #e8f5e9;
  }
  
  .step.complete .step-number {
    border-color: #2c5e3d;
    background: #2c5e3d;
    color: white;
  }
  
  .step-label {
    font-size: 0.9rem;
    color: #666;
  }
  
  .step.active .step-label {
    color: #2c5e3d;
    font-weight: 500;
  }
  
  /* Upload Options */
  .upload-options {
    display: flex;
    gap: 2rem;
    align-items: stretch;
  }
  
  .option-card {
    flex: 1;
    background: white;
    border: 2px solid #e8e8e8;
    border-radius: 12px;
    padding: 2rem;
  }
  
  .option-card h3 {
    color: #2c5e3d;
    margin-bottom: 0.5rem;
  }
  
  .option-card p {
    color: #666;
    margin-bottom: 1.5rem;
  }
  
  .divider {
    display: flex;
    align-items: center;
    color: #999;
    font-weight: 500;
  }
  
  /* File Input */
  .file-input-wrapper {
    margin-bottom: 1rem;
  }
  
  #file-input {
    display: none;
  }
  
  .file-label {
    display: block;
    padding: 0.75rem 1.5rem;
    background: #f8f7f4;
    border: 2px dashed #2c5e3d;
    border-radius: 8px;
    text-align: center;
    cursor: pointer;
    transition: all 0.2s;
  }
  
  .file-label:hover {
    background: #edebe8;
  }
  
  .image-preview {
    margin: 1rem 0;
    border-radius: 8px;
    overflow: hidden;
    max-height: 200px;
  }
  
  .image-preview img {
    width: 100%;
    height: auto;
    object-fit: cover;
  }
  
  /* Form */
  .artwork-form {
    background: white;
    border: 2px solid #e8e8e8;
    border-radius: 12px;
    padding: 2rem;
  }
  
  .form-group {
    margin-bottom: 1.5rem;
  }
  
  .form-group label {
    display: block;
    font-weight: 500;
    margin-bottom: 0.5rem;
    color: #2c5e3d;
  }
  
  .input-text,
  .input-textarea,
  .input-select {
    width: 100%;
    padding: 0.75rem;
    border: 1px solid #ddd;
    border-radius: 6px;
    font-size: 1rem;
    font-family: inherit;
  }
  
  .input-readonly {
    background: #f5f5f5;
    color: #666;
    cursor: not-allowed;
  }
  
  .input-textarea {
    resize: vertical;
  }
  
  .metadata-info {
    background: #f8f7f4;
    padding: 1rem;
    border-radius: 8px;
    margin-bottom: 1.5rem;
  }
  
  .metadata-info p {
    margin: 0.25rem 0;
    color: #666;
  }
  
  .form-group-row {
    display: flex;
    gap: 2rem;
    margin-bottom: 1.5rem;
  }
  
  .checkbox-label {
    display: flex;
    align-items: center;
    gap: 0.5rem;
    cursor: pointer;
  }
  
  .checkbox-label input[type="checkbox"] {
    width: 18px;
    height: 18px;
    cursor: pointer;
  }
  
  small {
    display: block;
    margin-top: 0.25rem;
    color: #999;
    font-size: 0.85rem;
  }
  
  .form-actions {
    display: flex;
    gap: 1rem;
    justify-content: flex-end;
    margin-top: 2rem;
    padding-top: 2rem;
    border-top: 1px solid #e8e8e8;
  }
  
  .btn-primary,
  .btn-secondary {
    padding: 0.75rem 2rem;
    border-radius: 6px;
    font-size: 1rem;
    font-weight: 500;
    cursor: pointer;
    transition: all 0.2s;
    border: none;
  }
  
  .btn-primary {
    background: #2c5e3d;
    color: white;
  }
  
  .btn-primary:hover:not(:disabled) {
    background: #1f4229;
  }
  
  .btn-primary:disabled {
    background: #ccc;
    cursor: not-allowed;
  }
  
  .btn-secondary {
    background: #f5f5f5;
    color: #333;
    border: 1px solid #ddd;
  }
  
  .btn-secondary:hover {
    background: #e8e8e8;
  }
  
  /* Story Section */
  .story-section {
    background: #f8f7f4;
    padding: 1.5rem;
    border-radius: 8px;
    margin-bottom: 1.5rem;
  }
  
  .checkbox-main {
    font-size: 1.1rem;
    font-weight: 500;
    color: #2c5e3d;
  }
  
  .checkbox-main-text {
    margin-left: 0.5rem;
  }
  
  .story-fields {
    margin-top: 1.5rem;
    padding-top: 1.5rem;
    border-top: 1px solid #ddd;
  }
  
  .info-box {
    background: white;
    padding: 1rem;
    border-radius: 6px;
    border-left: 3px solid #2c5e3d;
    margin-top: 1rem;
  }
  
  .info-box strong {
    display: block;
    margin-bottom: 0.5rem;
    color: #2c5e3d;
  }
  
  .info-box ul {
    margin: 0.5rem 0 0 1.5rem;
    padding: 0;
  }
  
  .info-box li {
    margin: 0.25rem 0;
    color: #666;
  }
  
  .info-box code {
    background: #f5f5f5;
    padding: 0.2rem 0.4rem;
    border-radius: 3px;
    font-size: 0.9em;
    color: #2c5e3d;
  }
  
  @media (max-width: 768px) {
    .upload-options {
      flex-direction: column;
    }
    
    .divider {
      justify-content: center;
      padding: 1rem 0;
    }
    
    .form-group-row {
      flex-direction: column;
      gap: 1rem;
    }
  }
</style>
