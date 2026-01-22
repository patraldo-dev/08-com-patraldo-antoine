import { json } from '@sveltejs/kit';
import { ADMIN_SECRET } from '$env/static/private';

export async function GET({ params }) {
  const { imgId } = params;
  
  // Admin auth check
  const auth = request?.headers?.get('Authorization');
  if (auth !== `Bearer ${ADMIN_SECRET}`) {
    return new Response('Unauthorized', { status: 401 });
  }
  
  try {
    // Cloudflare Images API
    const response = await fetch(
      `https://api.cloudflare.com/client/v4/accounts/ACCOUNT_ID/images/v1/${imgId}`,
      {
        headers: {
          'Authorization': `Bearer ${CF_API_TOKEN}`,
          'X-Auth-Email': 'your-email@example.com',
          'X-Auth-Key': CF_API_KEY
        }
      }
    );
    
    if (!response.ok) {
      return json({ error: 'Image not found' }, { status: 404 });
    }
    
    const data = await response.json();
    return json({
      title: data.result?.meta?.title || '',
      filename: data.result?.filename,
      width: data.result?.dimensions?.width,
      height: data.result?.dimensions?.height
    });
    
  } catch (error) {
    return json({ error: 'Failed to fetch metadata' }, { status: 500 });
  }
}

