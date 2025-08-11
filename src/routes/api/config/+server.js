// src/routes/api/config/+server.js
export async function GET() {
  try {
    // Check if the environment variable exists
    if (!process.env.CF_IMAGES_ACCOUNT_HASH) {
      console.error('CF_IMAGES_ACCOUNT_HASH environment variable is not set');
      return new Response(JSON.stringify({
        error: 'Configuration not set',
        cfImagesAccountHash: null
      }), {
        status: 500,
        headers: {
          'Content-Type': 'application/json'
        }
      });
    }
    
    return new Response(JSON.stringify({
      cfImagesAccountHash: process.env.CF_IMAGES_ACCOUNT_HASH
    }), {
      headers: {
        'Content-Type': 'application/json'
      }
    });
  } catch (error) {
    console.error('Error in /api/config:', error);
    return new Response(JSON.stringify({
      error: 'Internal server error',
      cfImagesAccountHash: null
    }), {
      status: 500,
      headers: {
        'Content-Type': 'application/json'
      }
    });
  }
}
