// hash-password.mjs
// Run with: node hash-password.mjs yourpassword

async function hashPassword(password) {
    const encoder = new TextEncoder();
    const data = encoder.encode(password);
    const salt = crypto.getRandomValues(new Uint8Array(16));
    const iterations = 100000;
    
    const key = await crypto.subtle.importKey(
        'raw',
        data,
        { name: 'PBKDF2' },
        false,
        ['deriveBits']
    );
    
    const derivedBits = await crypto.subtle.deriveBits(
        {
            name: 'PBKDF2',
            salt: salt,
            iterations: iterations,
            hash: 'SHA-256'
        },
        key,
        256
    );
    
    const hashArray = new Uint8Array(derivedBits);
    const hashB64 = Buffer.from(hashArray).toString('base64');
    const saltB64 = Buffer.from(salt).toString('base64');
    
    return `${iterations}:${saltB64}:${hashB64}`;
}

const password = process.argv[2];
if (!password) {
    console.error('Usage: node hash-password.mjs <password>');
    console.error('Example: node hash-password.mjs MySecurePassword123');
    process.exit(1);
}

hashPassword(password).then(hash => {
    console.log('\n✅ Password hashed successfully!\n');
    console.log('Hashed password:');
    console.log(hash);
    console.log('\n📋 Copy this hash and use it in the INSERT command');
});
