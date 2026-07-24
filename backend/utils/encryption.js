const crypto = require('crypto');

// AES-256-CBC requires a 32-byte key and a 16-byte IV
const ENCRYPTION_KEY = process.env.ENCRYPTION_KEY || '12345678901234567890123456789012'; // Must be 32 chars
const IV_LENGTH = 16; 
const STATIC_IV = process.env.ENCRYPTION_IV || '1234567890123456'; // Must be 16 chars

function encrypt(text) {
    let cipher = crypto.createCipheriv('aes-256-cbc', Buffer.from(ENCRYPTION_KEY), Buffer.from(STATIC_IV));
    let encrypted = cipher.update(text);
    encrypted = Buffer.concat([encrypted, cipher.final()]);
    // Option to generate random IV: we prepend IV to encrypted data if dynamic. 
    // For simplicity with cross-platform Dart, we'll use a static IV, but in production, random IV is injected.
    return encrypted.toString('base64');
}

function decrypt(text) {
    let encryptedText = Buffer.from(text, 'base64');
    let decipher = crypto.createDecipheriv('aes-256-cbc', Buffer.from(ENCRYPTION_KEY), Buffer.from(STATIC_IV));
    let decrypted = decipher.update(encryptedText);
    decrypted = Buffer.concat([decrypted, decipher.final()]);
    return decrypted.toString();
}

module.exports = { encrypt, decrypt };
