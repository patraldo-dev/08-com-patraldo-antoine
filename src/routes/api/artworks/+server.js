import fs from 'fs';
import path from 'path';
import { json } from '@sveltejs/kit';

const filePath = path.resolve('src/data/artworks.json');

export async function GET() {
  try {
    const data = fs.readFileSync(filePath, 'utf8');
    return json(JSON.parse(data));
  } catch (error) {
    return json({ error: 'Failed to read artworks data' }, { status: 500 });
  }
}

export async function POST({ request }) {
  try {
    const newArtwork = await request.json();
    
    // Read current artworks
    const data = fs.readFileSync(filePath, 'utf8');
    const artworks = JSON.parse(data);
    
    // Add new artwork
    artworks.push(newArtwork);
    
    // Write back to file
    fs.writeFileSync(filePath, JSON.stringify(artworks, null, 2));
    
    return json({ success: true, artwork: newArtwork });
  } catch (error) {
    console.error('Error adding artwork:', error);
    return json({ error: 'Failed to add artwork' }, { status: 500 });
  }
}
