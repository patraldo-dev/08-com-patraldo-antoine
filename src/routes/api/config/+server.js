// src/routes/api/config/+server.js
export async function GET() {
  // For development, return a placeholder if the environment variable isn't set
  const accountHash = process.env.CF_IMAGES_ACCOUNT_HASH || 'your-account-hash-here';
  
  return new Response(JSON.stringify({
    cfImagesAccountHash: accountHash
  }), {
    headers: {
      'Content-Type': 'application/json'
    }
  });
}
