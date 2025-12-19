// src/lib/utils/generateStickerSheet.mjs
/**
 * Generates a printable sticker sheet with cut guides and corner watermark.
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
  const stickerSize = Math.round(60 * mmToPx);
  const padding = Math.round(10 * mmToPx);
  const safeInset = stickerSize * 0.05;

  const canvas = Object.assign(document.createElement('canvas'), {
    width: pageW,
    height: pageH
  });
  const ctx = canvas.getContext('2d', { alpha: false });
  ctx.fillStyle = '#ffffff';
  ctx.fillRect(0, 0, pageW, pageH);

  // ✅ WATERMARK FUNCTION
const addWatermark = (ctx, x, y, stickerSize) => {
  const fontSize = stickerSize * 0.07;
  ctx.fillStyle = 'rgba(0, 0, 0, 0.2)';
  ctx.font = `${fontSize}px 'Segoe UI', 'Helvetica Neue', Arial, sans-serif`;
  ctx.fontStyle = 'italic';

  // antoine. bottom-right
  ctx.textAlign = 'right';
  ctx.textBaseline = 'bottom';
  ctx.fillText('antoine.', x + stickerSize, y + stickerSize);

  // patraldo.com - bottom-right → vertical UP
  ctx.save();
  ctx.translate(x + stickerSize - 2, y + stickerSize);
  ctx.rotate(-Math.PI / 2);
  ctx.textAlign = 'start';
  ctx.textBaseline = 'bottom';
  ctx.fillText('patraldo.com', 0, 0);
  ctx.restore();
};


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

  for (let i = 0; i < images.length; i++) {
    const row = Math.floor(i / cols);
    const col = i % cols;
    const x = col * (stickerSize + padding) + padding;
    const y = row * (stickerSize + padding) + padding;

    // Dashed cut guide
    ctx.strokeStyle = '#cccccc';
    ctx.lineWidth = 1;
    ctx.setLineDash([4, 4]);
    ctx.strokeRect(x, y, stickerSize, stickerSize);
    ctx.setLineDash([]);

    // Artwork with margin
    const img = images[i];
    const contentSize = stickerSize - safeInset * 2;
    const scale = Math.min(contentSize / img.width, contentSize / img.height);
    const w = img.width * scale;
    const h = img.height * scale;
    const dx = x + safeInset + (contentSize - w) / 2;
    const dy = y + safeInset + (contentSize - h) / 2;
    ctx.drawImage(img, dx, dy, w, h);

    // Add L-shape watermark
    addWatermark(ctx, x, y, stickerSize);
  }

  return new Promise((resolve) => {
    canvas.toBlob(resolve, 'image/png', 1.0);
  });
}

