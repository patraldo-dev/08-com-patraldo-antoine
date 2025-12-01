// Run in browser console
async function testEmail() {
  try {
    const response = await fetch('/api/test-email', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email: 'tu-email-real@gmail.com' }) // Replace with YOUR email
    });
    
    if (!response.ok) {
      const text = await response.text();
      console.error('HTTP Error:', response.status, text);
      return { error: `HTTP ${response.status}`, details: text };
    }
    
    const result = await response.json();
    console.log('✅ Email test result:', result);
    return result;
    
  } catch (error) {
    console.error('❌ Test failed:', error);
    return { error: error.message };
  }
}

testEmail();
