const tls = require('tls');
const crypto = require('crypto');

const options = {
    host: 'go.com',
    port: 443,
    servername: 'go.com'
};

const socket = tls.connect(options, () => {
    const cert = socket.getPeerCertificate();
    const fingerprint256 = cert.fingerprint256;
    console.log('FINGERPRINT=' + fingerprint256);
    socket.end();
});

socket.on('error', (err) => {
    console.error('Error:', err);
});
