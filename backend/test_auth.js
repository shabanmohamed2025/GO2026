const axios = require('axios');
const { decrypt } = require('./utils/encryption');

async function test() {
  try {
    console.log('Logging in...');
    const res = await axios.post('http://localhost:3000/api/auth/debug-login');
    const decrypted = JSON.parse(decrypt(res.data.encryptedPayload));
    console.log('Token extracted length:', decrypted.token.length);

    console.log('Fetching metrics...');
    const metrics = await axios.get('http://localhost:3000/api/admin/metrics', {
      headers: { Authorization: 'Bearer ' + decrypted.token }
    });
    console.log('Metrics success!');
  } catch (err) {
    if (err.response) {
      console.error('Failed request:', err.response.status, err.response.data);
    } else {
      console.error('Failed:', err);
    }
  }
}
test();
