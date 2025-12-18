// src/lib/utils/generateStickerSheet.mjs
/**
 * Generates a printable sticker sheet with cut guides.
 * Each sticker is placed on a white background with a light dashed outline.
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
  if (stickers.length === 0) throw new Error('No artworks provided');

  const mmToPx = dpi / 25.4;
  const pageW = Math.round(210 * mmToPx);   // A4
  const pageH = Math.round(297 * mmToPx);
  const stickerSize = Math.round(60 * mmToPx); // 60mm = ~2.36"
  const padding = Math.round(10 * mmToPx);     // space between stickers

  const canvas = Object.assign(document.createElement('canvas'), {
    width: pageW,
    height: pageH
  });
  const ctx = canvas.getContext('2d', { alpha: false });
  ctx.fillStyle = '#ffffff';
  ctx.fillRect(0, 0, pageW, pageH);

  // Load images
  const imgPromises = stickers.map(({ imageUrl }) =>
    new Promise((resolve, reject) => {
      const img = new Image();
      img.crossOrigin = 'anonymous';
      img.src = imageUrl;
      img.onload = () => resolve(img);
      img.onerror = () => reject(new Error(`Failed to load: ${imageUrl}`));
    })
  );
  const images = await Promise.all(imgPromises);

  // Draw each sticker cell
  for (let i = 0; i < images.length; i++) {
    const row = Math.floor(i / cols);
    const col = i % cols;
    const x = col * (stickerSize + padding) + padding;
    const y = row * (stickerSize + padding) + padding;

    // Optional: draw light cut guide (dashed or solid)
    ctx.strokeStyle = '#cccccc';
    ctx.lineWidth = 1;
    ctx.setLineDash([4, 4]); // dashed line
    ctx.strokeRect(x, y, stickerSize, stickerSize);
    ctx.setLineDash([]); // reset

    // Draw image with safe margin (90% of sticker area)
    const img = images[i];
    const safeInset = stickerSize * 0.05; // 5% margin
    const contentSize = stickerSize - safeInset * 2;
    const scale = Math.min(contentSize / img.width, contentSize / img.height);
    const w = img.width * scale;
    const h = img.height * scale;
    const dx = x + safeInset + (contentSize - w) / 2;
    const dy = y + safeInset + (contentSize - h) / 2;

    ctx.drawImage(img, dx, dy, w, h);
  }

  return new Promise((resolve) => {
    canvas.toBlob(resolve, 'image/png', 1.0);
  });
}
