const axios = require('axios');
const fs = require('fs');
const { encrypt, decrypt } = require('d:/GO/backend/utils/encryption');

async function test() {
  try {
    const loginRes = await axios.post('http://localhost:3000/api/auth/debug-login');
    const decLogin = JSON.parse(decrypt(loginRes.data.encryptedPayload));
    
    console.log("Token:", decLogin.token);
    
    // hit admin metrics
    const metricsRes = await axios.get('http://localhost:3000/api/admin/metrics', {
      headers: { Authorization: `Bearer ${decLogin.token}` }
    });
    
    const decMetrics = JSON.parse(decrypt(metricsRes.data.encryptedPayload));
    console.log("Metrics:", JSON.stringify(decMetrics, null, 2));
    
  } catch(e) {
    console.error("Error:", e.response ? e.response.data : e.message);
  }
}

test();
