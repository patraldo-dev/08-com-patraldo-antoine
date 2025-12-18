/**
 * Generates a printable sticker sheet as a PNG Blob using HTML5 Canvas.
 * Optimized for A4 (210×297mm) at 300 DPI.
 * 
 * @param {Array<{id: string, displayName: string, imageUrl: string}>} artworks
 * @param {Object} options
 * @param {number} [options.cols=3]
 * @param {number} [options.rows=3]
 * @param {number} [options.dpi=300]
 * @returns {Promise<Blob>}
 */
export async function generateStickerSheet(artworks, {
  cols = 3,
  rows = 3,
  dpi = 300
} = {}) {
  const stickers = artworks.slice(0, cols * rows);
  if (stickers.length === 0) {
    throw new Error('No artworks provided');
  }

  const mmToPx = dpi / 25.4;
  const pageW = Math.round(210 * mmToPx);   // A4 width in pixels
  const pageH = Math.round(297 * mmToPx);   // A4 height
  const stickerSize = Math.round(60 * mmToPx); // 60mm square stickers
  const padding = Math.round(10 * mmToPx);     // 10mm between stickers

  const canvas = Object.assign(document.createElement('canvas'), {
    width: pageW,
    height: pageH
  });
  const ctx = canvas.getContext('2d', { alpha: false });
  ctx.fillStyle = '#ffffff';
  ctx.fillRect(0, 0, pageW, pageH);

  // Load all images with CORS support (critical for Cloudflare R2)
  const imgPromises = stickers.map(({ imageUrl }) => {
    return new Promise((resolve, reject) => {
      const img = new Image();
      img.crossOrigin = 'anonymous';
      img.src = imageUrl;
      img.onload = () => resolve(img);
      img.onerror = () => reject(new Error(`Failed to load: ${imageUrl}`));
    });
  });

  const images = await Promise.all(imgPromises);

  // Draw each sticker in a grid
  for (let i = 0; i < images.length; i++) {
    const row = Math.floor(i / cols);
    const col = i % cols;
    const x = col * (stickerSize + padding) + padding;
    const y = row * (stickerSize + padding) + padding;

    const img = images[i];
    const scale = Math.min(stickerSize / img.width, stickerSize / img.height);
    const w = img.width * scale;
    const h = img.height * scale;
    const dx = x + (stickerSize - w) / 2;
    const dy = y + (stickerSize - h) / 2;

    ctx.drawImage(img, dx, dy, w, h);
  }

  return new Promise((resolve) => {
    canvas.toBlob(resolve, 'image/png', 1.0);
  });
}
