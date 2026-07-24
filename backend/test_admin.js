const axios = require('axios');
const { encrypt, decrypt } = require('./utils/encryption');

async function run() {
    try {
        const authRes = await axios.post('http://localhost:3000/api/auth/debug-login');
        const encryptedAuth = authRes.data.encryptedPayload;
        const decryptedAuth = JSON.parse(decrypt(encryptedAuth));
        const token = decryptedAuth.token;

        const res = await axios.get('http://localhost:3000/api/admin/metrics', {
            headers: { Authorization: `Bearer ${token}` }
        });
        
        const encryptedData = res.data.encryptedPayload;
        console.log('Metrics:', JSON.parse(decrypt(encryptedData)));
    } catch (e) {
        console.error('FULL ERROR:', e);
    }
}
run();
