const axios = require('axios');
const { decrypt } = require('./utils/encryption');

async function main() {
    try {
        const response1 = await axios.post('http://localhost:3000/api/auth/debug-login');
        const decryptedStr = decrypt(response1.data.encryptedPayload);
        const token = JSON.parse(decryptedStr).token;
        
        const payload = {
            name: "Test Driver 2",
            phone: "01000000002",
            vehicleType: "Motorcycle",
            plateNumber: "321654",
            nationalId: "28807241880218",
            idCardFront: "A".repeat(10000),
            idCardBack: "B".repeat(10000)
        };
        console.log("Sending registration request...");
        const response2 = await axios.post('http://localhost:3000/api/drivers/register', payload, {
            headers: { Authorization: `Bearer ${token}` }
        });
        console.log("Success:", JSON.parse(decrypt(response2.data.encryptedPayload)));
    } catch(err) {
        console.error("Error:", err.response?.status, err.response?.data, err.message);
    }
}
main();
