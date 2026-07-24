const axios = require('axios');
const crypto = require('crypto');

const PAYMOB_API_KEY = process.env.PAYMOB_API_KEY;
const PAYMOB_INTEGRATION_ID = process.env.PAYMOB_INTEGRATION_ID;
const PAYMOB_HMAC_SECRET = process.env.PAYMOB_HMAC_SECRET;

class PaymobService {
  /**
   * Step 1: Authentication Request
   */
  async authenticate() {
    try {
      const response = await axios.post('https://accept.paymob.com/api/auth/tokens', {
        api_key: PAYMOB_API_KEY
      });
      return response.data.token;
    } catch (error) {
      console.error('Paymob Auth Error:', error?.response?.data || error);
      throw new Error('Failed to authenticate with Paymob');
    }
  }

  /**
   * Step 2: Order Registration Request
   */
  async registerOrder(authToken, amountCents, currency = 'EGP', merchantOrderId) {
    try {
      const response = await axios.post('https://accept.paymob.com/api/ecommerce/orders', {
        auth_token: authToken,
        delivery_needed: 'false',
        amount_cents: amountCents.toString(),
        currency: currency,
        items: [],
        merchant_order_id: merchantOrderId // Optional: Pass your DB order id here
      });
      return response.data.id;
    } catch (error) {
      console.error('Paymob Order Error:', error?.response?.data || error);
      throw new Error('Failed to register order with Paymob');
    }
  }

  /**
   * Step 3: Payment Key Request
   */
  async requestPaymentKey(authToken, orderId, amountCents, currency, billingData) {
    try {
      const response = await axios.post('https://accept.paymob.com/api/acceptance/payment_keys', {
        auth_token: authToken,
        amount_cents: amountCents.toString(),
        expiration: 3600, // 1 hour
        order_id: orderId,
        billing_data: billingData,
        currency: currency,
        integration_id: PAYMOB_INTEGRATION_ID,
        lock_order_when_paid: 'false'
      });
      return response.data.token;
    } catch (error) {
      console.error('Paymob Payment Key Error:', error?.response?.data || error);
      throw new Error('Failed to request payment key from Paymob');
    }
  }

  /**
   * Complete Flow: Generate Checkout Iframe URL
   */
  async generateCheckoutUrl(amountCents, localOrderId, user) {
    const authToken = await this.authenticate();
    const orderId = await this.registerOrder(authToken, amountCents, 'EGP', localOrderId);
    
    // Billing data requires specific fields, use dummies if missing
    const billingData = {
      apartment: "NA",
      email: user.email || "dummy@email.com",
      floor: "NA",
      first_name: user.name || "User",
      street: "NA",
      building: "NA",
      phone_number: user.phone || "+201000000000",
      shipping_method: "PKG",
      postal_code: "NA",
      city: "Cairo",
      country: "EG",
      last_name: "Customer",
      state: "NA"
    };

    const paymentKey = await this.requestPaymentKey(authToken, orderId, amountCents, 'EGP', billingData);
    
    const iframeId = process.env.PAYMOB_IFRAME_ID;
    return {
      iframeUrl: `https://accept.paymob.com/api/acceptance/iframes/${iframeId}?payment_token=${paymentKey}`,
      paymobOrderId: orderId
    };
  }

  /**
   * Step 4: Verify HMAC from Webhook
   */
  verifyHMAC(queryString, receivedHmac) {
    // Paymob sends lexicographically sorted concatenated string of specific parameters
    // We will assume string concatenation of the necessary parameters exactly as Paymob dictates
    // For production, you must implement the exact string builder from Paymob docs:
    const data = queryString; 
    
    // Example only, production requires proper param concatenation:
    /*
      const { amount_cents, created_at, currency, error_occured, has_parent_transaction, id, integration_id, is_3d_secure, is_auth, is_capture, is_refunded, is_standalone_payment, is_voided, order, owner, pending, source_data_pan, source_data_sub_type, source_data_type, success } = req.query.obj;
      const concatenatedString = amount_cents + created_at + currency + error_occured + has_parent_transaction + id + integration_id + is_3d_secure + is_auth + is_capture + is_refunded + is_standalone_payment + is_voided + order.id + owner + pending + source_data.pan + source_data.sub_type + source_data.type + success;
    */
    
    const hash = crypto.createHmac('sha512', PAYMOB_HMAC_SECRET).update(data).digest('hex');
    return hash === receivedHmac;
  }
}

module.exports = new PaymobService();
