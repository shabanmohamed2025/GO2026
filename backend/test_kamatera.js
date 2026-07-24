const axios = require('axios');

const testApi = async (clientId, secret) => {
    try {
        const response = await axios.get('https://console.kamatera.com/service/server', {
            headers: {
                'AuthClientId': clientId,
                'AuthSecret': secret,
                'Accept': 'application/json'
            }
        });
        console.log(`SUCCESS with ClientId: ${clientId}`);
        console.dir(response.data.slice(0, 5));
        process.exit(0);
    } catch (error) {
        console.log(`Failed with ClientId: ${clientId} - ${error.response ? error.response.status : error.message}`);
    }
};

const key1 = 'c25fcb1ae0516d7ae81b5e293ecefe7d';
const key2 = '65a3df6dd77a199849b01e701896c86a';

async function run() {
    console.log("Testing combination 1...");
    await testApi(key1, key2);
    console.log("Testing combination 2...");
    await testApi(key2, key1);
}

run();
