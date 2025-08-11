<script>
  import ArtPiece from './ArtPiece.svelte';
  import { CF_IMAGES_ACCOUNT_HASH } from '$lib/config.js';


  // Sample artwork data - update with your actual URLs
  const artworks = [
{
      id: 1,
      title: "MujerFaceAntoine",
      type: "still",
      r2Url: "https://imagedelivery.net/${CF_IMAGES_ACCOUNT_HASH}/MujerFaceAntoine.jpg",
      thumbnailId: "thumb-meta-1",
      description: "Charcoal and digital manipulation, 2024",
      year: 2024
    },
    {
      id: 2,
      title: "MujerFaceAntoine",
      type: "still",
      r2Url: "https://imagedelivery.net/${CF_IMAGES_ACCOUNT_HASH}/MujerFaceAntoine.jpg",
      thumbnailId: "thumb-temporal",
      description: "Video installation, 3:42 min, 2024",
      year: 2024
    },
    {
      id: 3,
      title: "MujerFaceAntoine",
      type: "still",
      r2Url: "https://imagedelivery.net/${CF_IMAGES_ACCOUNT_HASH}/MujerFaceAntoine.jpg",
      thumbnailId: "thumb-memory",
      description: "Animated sequence, 2024",
      year: 2024
    },
    {
      id: 4,
      title: "MujerFaceAntoine",
      type: "still",
      r2Url: "https://imagedelivery.net/${CF_IMAGES_ACCOUNT_HASH}/MujerFaceAntoine.jpg",
      thumbnailId: "thumb-arch",
      description: "Mixed media on canvas, 2024",
      year: 2024
    },
    {
      id: 5,
      title: "MujerFaceAntoine",
      type: "still",
      r2Url: "https://imagedelivery.net/${CF_IMAGES_ACCOUNT_HASH}/MujerFaceAntoine.jpg",
      thumbnailId: "thumb-fluid",
      description: "Video study, 1:20 min, 2023",
      year: 2023
    },
    {
      id: 6,
      title: "MujerFaceAntoine",
      type: "still",
      r2Url: "https://imagedelivery.net/${CF_IMAGES_ACCOUNT_HASH}/MujerFaceAntoine.jpg",
      thumbnailId: "thumb-glitch",
      description: "Digital manipulation, 2023",
      year: 2023
    }
  ];

  let selectedType = 'all';
  
  $: filteredArtworks = selectedType === 'all' 
    ? artworks 
    : artworks.filter(artwork => artwork.type === selectedType);
  
  const artworkTypes = [
    { value: 'all', label: 'All Work' },
    { value: 'still', label: 'Still Images' },
    { value: 'animation', label: 'Videos' },
    { value: 'gif', label: 'Animated GIFs' }
  ];
</script>
