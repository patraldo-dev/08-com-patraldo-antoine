// src/routes/api/subscribe/+server.js
/**
 * @type {import('./$types').RequestHandler}
 */
export async function POST({ request }) {
  try {
    const { email } = await request.json();
    if (!email || !isValidEmail(email)) {
      return new Response(
        JSON.stringify({ message: 'Valid email is required' }),
        { 
          status: 400, 
          headers: { 'Content-Type': 'application/json' } 
        }
      );
    }
    
    // For now, skip the worker call and just return a success message
    // TODO: Uncomment and update with your actual worker URL once deployed
    /*
    const workerResponse = await fetch('https://your-worker.your-subdomain.workers.dev/subscribe', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ email })
    });
    
    if (!workerResponse.ok) {
      const error = await workerResponse.text();
      throw new Error(`Worker error: ${error}`);
    }
    
    const result = await workerResponse.json();
    */
    
    // Temporary success response
    return new Response(
      JSON.stringify({ message: 'Please check your email to confirm your subscription!' }),
      { 
        status: 200, 
        headers: { 'Content-Type': 'application/json' } 
      }
    );
  } catch (error) {
    console.error('Subscription error:', error);
    
    return new Response(
      JSON.stringify({ message: 'Failed to subscribe. Please try again.' }),
      { 
        status: 500, 
        headers: { 'Content-Type': 'application/json' } 
      }
    );
  }
}

function isValidEmail(email) {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
}
