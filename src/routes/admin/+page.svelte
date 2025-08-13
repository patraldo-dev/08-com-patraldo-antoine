<script>
  // Add this to your existing script
  let uploadTitle = '';
  let uploadDescription = '';
  let uploadYear = new Date().getFullYear();
  let uploadFile = null;
  let uploading = false;
  let uploadMessage = '';
  let uploadSuccess = false;
  let checkingStatus = false;
  let currentImageId = null;
  let statusCheckInterval = null;
  
  function handleFileChange(event) {
    uploadFile = event.target.files[0];
  }
  
  async function handleUpload() {
    if (!uploadFile) return;
    
    uploading = true;
    uploadMessage = '';
    uploadSuccess = false;
    
    try {
      // Request upload URL
      const uploadResponse = await fetch('/api/upload-url', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          metadata: {
            title: uploadTitle,
            description: uploadDescription,
            year: uploadYear
          }
        })
      });
      
      const uploadData = await uploadResponse.json();
      
      if (!uploadData.success) {
        throw new Error(uploadData.error || 'Failed to get upload URL');
      }
      
      currentImageId = uploadData.imageId;
      
      // Upload the file
      const formData = new FormData();
      formData.append('file', uploadFile);
      
      const fileUploadResponse = await fetch(uploadData.uploadURL, {
        method: 'POST',
        body: formData
      });
      
      if (!fileUploadResponse.ok) {
        throw new Error('Failed to upload file');
      }
      
      uploadMessage = 'File uploaded successfully! Checking status...';
      
      // Start polling for upload status
      checkingStatus = true;
      statusCheckInterval = setInterval(checkUploadStatus, 2000); // Check every 2 seconds
      
    } catch (error) {
      console.error('Upload error:', error);
      uploadMessage = `Error: ${error.message}`;
      uploadSuccess = false;
      uploading = false;
    }
  }
  
  async function checkUploadStatus() {
    try {
      const response = await fetch('/api/check-upload-status', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          imageId: currentImageId
        })
      });
      
      const data = await response.json();
      
      if (!data.success) {
        throw new Error(data.error || 'Failed to check upload status');
      }
      
      if (data.status === 'uploaded') {
        // Upload is complete
        clearInterval(statusCheckInterval);
        checkingStatus = false;
        uploading = false;
        uploadMessage = 'Artwork added to gallery successfully!';
        uploadSuccess = true;
        
        // Reset form
        uploadTitle = '';
        uploadDescription = '';
        uploadYear = new Date().getFullYear();
        uploadFile = null;
        currentImageId = null;
        document.getElementById('file').value = '';
        
        // Reload artworks after a short delay
        setTimeout(() => {
          loadArtworks();
        }, 1000);
      }
      // If still pending, continue polling
      
    } catch (error) {
      console.error('Status check error:', error);
      clearInterval(statusCheckInterval);
      checkingStatus = false;
      uploading = false;
      uploadMessage = `Error checking status: ${error.message}`;
      uploadSuccess = false;
    }
  }
  
  // Clean up on component destroy
  import { onDestroy } from 'svelte';
  
  onDestroy(() => {
    if (statusCheckInterval) {
      clearInterval(statusCheckInterval);
    }
  });
</script>
