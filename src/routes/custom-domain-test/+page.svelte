<script>
  const accountHash = "4bRSwPonOXfEIBVZiDXg0w";
  const imageId = ""f8a136eb-363e-4a24-0f54-70bb4f4bf800; // Replace with your actual image ID
  const customDomain = "antoine.patraldo.com";
  
  // Test different URLs
  const urls = [
    {
      name: "Custom Domain - No variant",
      url: `https://${customDomain}/cdn-cgi/imagedelivery/${accountHash}/${imageId}`
    },
    {
      name: "Custom Domain - public",
      url: `https://${customDomain}/cdn-cgi/imagedelivery/${accountHash}/${imageId}/public`
    },
    {
      name: "Custom Domain - full",
      url: `https://${customDomain}/cdn-cgi/imagedelivery/${accountHash}/${imageId}/full`
    },
    {
      name: "Original Format",
      url: `https://imagedelivery.net/${accountHash}/${imageId}/full`
    }
  ];
</script>

<h1>Custom Domain Test</h1>

<div class="test-grid">
  {#each urls as urlInfo}
    <div class="test-item">
      <h3>{urlInfo.name}</h3>
      <p class="url">{urlInfo.url}</p>
      <img 
        src={urlInfo.url} 
        alt="{urlInfo.name}"
        style="max-width: 100%; max-height: 200px; object-fit: contain; border: 1px solid #ccc;"
        on:error={(e) => {
          console.error(`${urlInfo.name} failed to load:`, e);
          e.target.style.border = '2px solid red';
        }}
        on:load={() => {
          console.log(`${urlInfo.name} loaded successfully`);
          e.target.style.border = '2px solid green';
        }}
      />
    </div>
  {/each}
</div>

<style>
  .test-grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
    gap: 1rem;
    margin: 2rem 0;
  }
  .test-item {
    border: 1px solid #ccc;
    padding: 1rem;
    border-radius: 4px;
  }
  .test-item h3 {
    margin-top: 0;
  }
  .url {
    word-break: break-all;
    font-size: 0.8rem;
    color: #666;
    margin: 0.5rem 0;
  }
</style>
