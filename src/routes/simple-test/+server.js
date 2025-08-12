// src/routes/api/simple-test/+server.js
export async function POST({ request, platform }) {
  try {
    const { email } = await request.json();
    
    // Direct database insert test
    const result = await platform.env.DB.prepare(`
      INSERT INTO subscribers (email, type, confirmed, created_at)
      VALUES (?, 'art-updates', 0, datetime('now'))
    `).bind(email).run();
    
    return new Response(JSON.stringify({
      success: true,
      result: result
    }), {
      headers: {
        'Content-Type': 'application/json'
      }
    });
  } catch (error) {
    return new Response(JSON.stringify({
      success: false,
      error: error.message
    }), {
      status: 500,
      headers: {
        'Content-Type': 'application/json'
      }
    });
  }
}
