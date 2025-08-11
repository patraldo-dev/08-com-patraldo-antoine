// src/routes/api/test-db/+server.js
export async function GET({ platform }) {
  try {
    // Test database connection
    const result = await platform.env.DB.prepare('SELECT COUNT(*) as count FROM subscribers').first();
    
    return new Response(JSON.stringify({
      success: true,
      subscriberCount: result.count,
      databaseAccessible: true
    }), {
      headers: {
        'Content-Type': 'application/json'
      }
    });
  } catch (error) {
    console.error('Database test error:', error);
    return new Response(JSON.stringify({
      success: false,
      error: error.message,
      databaseAccessible: false
    }), {
      status: 500,
      headers: {
        'Content-Type': 'application/json'
      }
    });
  }
}
