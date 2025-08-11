export async function GET({ platform }) {
  try {
    // In Cloudflare Workers, environment variables are accessed via platform.env
    const accountHash = platform?.env?.CF_IMAGES_ACCOUNT_HASH;
    console.log('Account hash from platform.env:', accountHash);
    
    if (!accountHash) {
      console.error('CF_IMAGES_ACCOUNT_HASH is not set in platform.env');
      return new Response(JSON.stringify({
        error: 'Environment variable not set',
        cfImagesAccountHash: null
      }), {
        status: 500,
        headers: {
          'Content-Type': 'application/json'
        }
      });
    }
    
    return new Response(JSON.stringify({
      cfImagesAccountHash: accountHash
    }), {
      headers: {
        'Content-Type': 'application/json'
      }
    });
  } catch (error) {
    console.error('Error in /api/config:', error);
    return new Response(JSON.stringify({
      error: error.message,
      cfImagesAccountHash: null
    }), {
      status: 500,
      headers: {
        'Content-Type': 'application/json'
      }
    });
  }
}
