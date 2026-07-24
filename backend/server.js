const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const dotenv = require('dotenv');
const { initializeApp, cert } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');
const { getMessaging } = require('firebase-admin/messaging');
const jwt = require('jsonwebtoken');

dotenv.config();

// Initialize Firebase Admin
const serviceAccount = require('./firebase-service-account.json');
initializeApp({
  credential: cert(serviceAccount)
});

const { PrismaClient } = require('@prisma/client');
const { Pool } = require('pg');
const { PrismaPg } = require('@prisma/adapter-pg');

const app = express();
const pool = new Pool({ connectionString: process.env.DATABASE_URL });
const adapter = new PrismaPg(pool);
const prisma = new PrismaClient({ adapter });
// الكود يقرأ المنفذ من السيرفر أولاً، وإذا لم يجده يستخدم 8080 كمنفذ احتياطي محلي
const PORT = process.env.PORT || 8080;

// إعداد Helmet لحماية مسارات HTTP Headers ومنع الـ XSS
app.use(helmet());

app.use(cors());
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ limit: '50mb', extended: true }));

// إعداد الحد الأقصى للطلبات لمنع الـ DDoS
const rateLimit = require('express-rate-limit');
const globalLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 200, // Limit each IP to 200 requests per windowMs
  message: { error: 'Too many requests from this IP, please try again later.' }
});
app.use(globalLimiter);

// مستوى أشد حماية لمسار الدخول لمنع Brute Force
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, 
  max: 10, // Limit each IP to 10 login requests
  message: { error: 'Too many login attempts, please try again later.' }
});

// Middleware to verify Firebase Auth Token
const verifyFirebaseToken = async (req, res, next) => {
  const token = req.headers.authorization?.split(' ')[1];
  if (!token) {
    return res.status(401).json({ error: 'Unauthorized: No token provided' });
  }

  try {
    const decodedToken = await getAuth().verifyIdToken(token);
    req.user = decodedToken;
    next();
  } catch (error) {
    console.error('Error verifying Firebase token:', error);
    res.status(401).json({ error: 'Unauthorized: Invalid Firebase token' });
  }
};

// Middleware to verify Custom Backend JWT Token
const verifyCustomJWT = (req, res, next) => {
  const authHeader = req.headers.authorization;
  const token = authHeader?.split(' ')[1];
  if (!token) {
    console.error('JWT Verification Failed: No token provided in header:', authHeader);
    return res.status(401).json({ error: 'Unauthorized: No JWT provided' });
  }

  try {
    const secret = process.env.JWT_SECRET || 'super_secret_jwt_key_that_should_be_long_and_complex_12345';
    if (!secret) return res.status(500).json({ error: 'Server configuration error' });

    const decoded = jwt.verify(token, secret);
    req.user = decoded; // Contains id, firebaseUid, etc.
    next();
  } catch (error) {
    console.error('JWT Verification Failed:', error.message, 'Token received:', token);
    return res.status(401).json({ error: 'Unauthorized: Invalid Custom JWT' });
  }
};

// Helper: Send Push Notification
const sendPushNotification = async (fcmToken, title, body, data = {}) => {
  if (!fcmToken) return;
  try {
    const message = {
      notification: { title, body },
      data: data,
      token: fcmToken
    };
    await getMessaging().send(message);
    console.log(`Push notification sent successfully to ${fcmToken.substring(0, 10)}...`);
  } catch (error) {
    console.error('Error sending push notification:', error);
  }
};

// Route: Update FCM Token
app.post('/api/user/fcm-token', verifyCustomJWT, async (req, res) => {
  try {
    const { fcmToken } = req.body;
    if (!fcmToken) return res.status(400).json({ error: 'Token required' });
    
    await prisma.user.update({
      where: { id: req.user.id },
      data: { fcmToken: fcmToken }
    });
    
    res.json({ success: true });
  } catch (error) {
    console.error('Update FCM Token error:', error);
    res.status(500).json({ error: 'Internal Server Error' });
  }
});

// Route: Login/Sync - Validates Firebase token and issues Custom JWT
app.post('/api/auth/login', authLimiter, verifyFirebaseToken, async (req, res) => {
  try {
    const firebaseUid = req.user.uid;
    const providerName = req.user.name;
    const providerPhone = req.user.phone_number;
    
    // Fetch or create user in PostgreSQL
    let user = await prisma.user.findUnique({
      where: { firebaseUid: firebaseUid }
    });

    if (!user) {
      user = await prisma.user.create({
        data: {
          firebaseUid: firebaseUid,
          name: providerName || null,
          phone: providerPhone || null,
        }
      });
    } else {
      const updateData = {};
      if (!user.name && providerName) updateData.name = providerName;
      if (!user.phone && providerPhone) updateData.phone = providerPhone;

      if (Object.keys(updateData).length > 0) {
        user = await prisma.user.update({
          where: { id: user.id },
          data: updateData
        });
      }
    }

    // Generate Custom Backend JWT
    const secret = process.env.JWT_SECRET;
    if (!secret) throw new Error('SERVER CONFIG ERROR: JWT_SECRET is missing');

    const backendToken = jwt.sign(
      { id: user.id, firebaseUid: user.firebaseUid },
      secret,
      { expiresIn: '7d' } // Token valid for 7 days
    );

    res.json({ message: 'Login successful', backendToken, user });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ error: 'Internal Server Error' });
  }
});

const { encrypt } = require('./utils/encryption');

// Protected Route example using Custom Backend JWT
app.get('/api/user/profile', verifyCustomJWT, async (req, res) => {
  try {
    const userId = req.user.id;
    
    // Fetch user from PostgreSQL using the decoded JWT ID
    const user = await prisma.user.findUnique({
      where: { id: userId }
    });

    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    // تشفير الرد بالكامل باستخدام AES-256
    const payload = JSON.stringify({ message: 'Profile fetched successfully', user });
    const encryptedData = encrypt(payload);

    res.json({ encryptedPayload: encryptedData });
  } catch (error) {
    console.error('Database error:', error);
    res.status(500).json({ error: 'Internal Server Error' });
  }
});

// Route: Update User Profile
app.put('/api/user/profile', verifyCustomJWT, async (req, res) => {
  try {
    const userId = req.user.id;
    const { name, phone } = req.body;
    
    const updatedUser = await prisma.user.update({
      where: { id: userId },
      data: { name, phone }
    });

    const payload = JSON.stringify({ message: 'Profile updated successfully', user: updatedUser });
    const encryptedData = encrypt(payload);

    res.json({ encryptedPayload: encryptedData });
  } catch (error) {
    console.error('Update profile error:', error);
    res.status(500).json({ error: 'Failed to update profile' });
  }
});

// DEBUG Bypassed Login Endpoint (Only for development)
app.post('/api/auth/debug-login', async (req, res) => {
  try {
    let testUser = await prisma.user.findUnique({ where: { firebaseUid: 'debug_user_123456789' } });
    if (!testUser) {
      testUser = await prisma.user.create({
        data: {
          firebaseUid: 'debug_user_123456789',
          phone: '+201000000000',
          name: 'المطور (Debug)',
          role: 'ADMIN' // Set to ADMIN so they can see the dashboard
        }
      });
    } else {
      if (testUser.role !== 'ADMIN') {
        testUser = await prisma.user.update({
          where: { id: testUser.id },
          data: { role: 'ADMIN' }
        });
      }
    }

    const secret = process.env.JWT_SECRET || 'super_secret_jwt_key_that_should_be_long_and_complex_12345';
    const customToken = jwt.sign(
      { id: testUser.id, firebaseUid: testUser.firebaseUid, role: testUser.role },
      secret,
      { expiresIn: '30d' }
    );

    const payload = JSON.stringify({ message: 'Debug Sync successful', token: customToken, user: testUser });
    const encryptedData = encrypt(payload);

    res.json({ encryptedPayload: encryptedData });
  } catch (error) {
    console.error('Debug Sync error:', error);
    res.status(500).json({ error: 'Internal Server Error' });
  }
});

const paymobService = require('./services/paymobService');

// Route: Initiate Payment
app.post('/api/payment/checkout', verifyCustomJWT, async (req, res) => {
  try {
    const userId = req.user.id;
    const { amount, tripId } = req.body; // Amount in EGP. tripId is optional for wallet topups.

    const user = await prisma.user.findUnique({ where: { id: userId } });
    if (!user) return res.status(404).json({ error: 'User not found' });

    const amountCents = Math.round(amount * 100);
    // You can generate a custom order id for paymob or use DB ID. Here we pass a timestamp based ID for local tracking.
    const tempOrderId = 'WAL_' + Date.now();
    
    // Generate the iframe URL and get order ID from Paymob
    const { iframeUrl, paymobOrderId } = await paymobService.generateCheckoutUrl(amountCents, tempOrderId, user);

    // Save pending payment in DB
    await prisma.payment.create({
      data: {
        tripId: tripId || null,
        userId: userId,
        amount: amount,
        paymobOrderId: paymobOrderId.toString()
      }
    });

    res.json({ iframeUrl, paymobOrderId });
  } catch (error) {
    console.error('Payment checkout error:', error);
    res.status(500).json({ error: 'Failed to initiate payment' });
  }
});

// Route: Paymob Webhook (Called by Paymob servers)
app.post('/api/payment/paymob-webhook', async (req, res) => {
  try {
    const receivedHmac = req.query.hmac;
    // Note: Proper HMAC verification string builder needs to be implemented here based on req.body.obj
    
    // For now, assume webhook is trusted in this scaffold
    const transaction = req.body.obj;
    if (transaction && transaction.order && transaction.order.id) {
      const paymobOrderId = transaction.order.id.toString();
      const success = transaction.success;

      // Update payment status in database
      const payment = await prisma.payment.update({
        where: { paymobOrderId: paymobOrderId },
        data: { status: success ? 'SUCCESS' : 'FAILED' }
      });

      // If success, add money to wallet
      if (success) {
        await prisma.user.update({
          where: { id: payment.userId },
          data: { walletBalance: { increment: payment.amount } }
        });
        console.log(`Payment successful for user ${payment.userId}, added ${payment.amount} EGP.`);
      }
    }
    
    res.status(200).send('Webhook received');
  } catch (error) {
    console.error('Webhook error:', error);
    res.status(500).send('Webhook Error');
  }
});

// Route: Get Nearby Active Drivers
app.get('/api/drivers/nearby', verifyCustomJWT, async (req, res) => {
  try {
    // Fetch all drivers where isOnline is true and coords are not null
    const drivers = await prisma.driver.findMany({
      where: {
        isOnline: true,
        approvalStatus: 'APPROVED',
        currentLat: { not: null },
        currentLng: { not: null }
      },
      select: {
        id: true,
        vehicleType: true,
        rating: true,
        currentLat: true,
        currentLng: true,
        user: { select: { name: true } }
      }
    });

    const payload = JSON.stringify({ message: 'Drivers fetched successfully', count: drivers.length, drivers });
    const encryptedData = encrypt(payload);

    res.json({ encryptedPayload: encryptedData });
  } catch (error) {
    console.error('Fetch drivers error:', error);
    res.status(500).json({ error: 'Failed to fetch nearby drivers' });
  }
});

// Haversine formula to calculate distance between two lat/lng points in km
function calculateDistance(lat1, lon1, lat2, lon2) {
  const R = 6371; // km
  const dLat = (lat2 - lat1) * Math.PI / 180;
  const dLon = (lon2 - lon1) * Math.PI / 180;
  const a = Math.sin(dLat/2) * Math.sin(dLat/2) +
            Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
            Math.sin(dLon/2) * Math.sin(dLon/2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
  return R * c;
}


// Route: Get Trip Messages
app.get('/api/trips/:id/messages', verifyCustomJWT, async (req, res) => {
  try {
    const tripId = parseInt(req.params.id);
    const userId = req.user.id;

    const messages = await prisma.message.findMany({
      where: { tripId },
      orderBy: { createdAt: 'asc' }
    });

    const formattedMessages = messages.map(msg => ({
      ...msg,
      isMine: msg.senderId === userId
    }));

    const encryptedData = encrypt(JSON.stringify(formattedMessages));
    res.json({ encryptedPayload: encryptedData });
  } catch (error) {
    console.error('Fetch messages error:', error);
    res.status(500).json({ error: 'Failed to fetch messages' });
  }
});

// Route: Send Trip Message
app.post('/api/trips/:id/messages', verifyCustomJWT, async (req, res) => {
  try {
    const tripId = parseInt(req.params.id);
    const userId = req.user.id;
    const { content } = req.body;

    if (!content) return res.status(400).json({ error: 'Content is required' });

    const message = await prisma.message.create({
      data: {
        tripId,
        senderId: userId,
        content
      }
    });

    const encryptedData = encrypt(JSON.stringify({ success: true, message }));
    res.json({ encryptedPayload: encryptedData });
  } catch (error) {
    console.error('Send message error:', error);
    res.status(500).json({ error: 'Failed to send message' });
  }
});

// Route: Estimate Trip Fare
app.get('/api/trips/estimate', async (req, res) => {
  try {
    const distanceKm = parseFloat(req.query.distance);
    const vehicleType = req.query.vehicleType || 'Tricycle';

    if (isNaN(distanceKm) || distanceKm < 0) {
      return res.status(400).json({ error: 'Invalid distance' });
    }

    // Fetch active Pricing Rules
    let pricing = await prisma.pricingRule.findUnique({ where: { vehicleType: vehicleType } });
    if (!pricing) {
      pricing = { baseFare: 5.0, perKmRate: 3.0, surgeMultiplier: 1.0 }; // Fallback values
    }

    // Calculate Fare
    let estimatedFare = pricing.baseFare + (distanceKm * pricing.perKmRate) * pricing.surgeMultiplier;
    // ensure at least min fare
    estimatedFare = Math.max(estimatedFare, 10.0);

    const payload = JSON.stringify({ estimatedFare });
    const encryptedData = encrypt(payload);

    res.json({ encryptedPayload: encryptedData });
  } catch (error) {
    console.error('Trip estimate error:', error);
    res.status(500).json({ error: 'Failed to estimate trip cost' });
  }
});

// Route: Request a new Trip
app.post('/api/trips/request', verifyCustomJWT, async (req, res) => {
  try {
    const userId = req.user.id;
    const { pickupLat, pickupLng, dropOffLat, dropOffLng, paymentMethod } = req.body;
    const method = paymentMethod || 'CASH';

    if (!pickupLat || !pickupLng || !dropOffLat || !dropOffLng) {
      return res.status(400).json({ error: 'Missing coordinates' });
    }

    // Fetch User to check wallet
    const user = await prisma.user.findUnique({ where: { id: userId } });

    // 1. Calculate approximate distance
    const distanceKm = calculateDistance(pickupLat, pickupLng, dropOffLat, dropOffLng);

    // 2. Fetch active Pricing Rules (Assuming 'Tricycle' default exists)
    let pricing = await prisma.pricingRule.findUnique({ where: { vehicleType: 'Tricycle' } });
    if (!pricing) {
      pricing = { baseFare: 5.0, perKmRate: 3.0, surgeMultiplier: 1.0 }; // Fallback values
    }

    // 3. Calculate Fare
    let calculatedFare = pricing.baseFare + (distanceKm * pricing.perKmRate) * pricing.surgeMultiplier;
    // ensure at least min fare
    calculatedFare = Math.max(calculatedFare, 10.0);

    // Wallet check
    if (method === 'WALLET') {
      if (!user || user.walletBalance < calculatedFare) {
        return res.status(400).json({ error: 'رصيد المحفظة غير كافٍ. برجاء الشحن أو الدفع نقداً.' });
      }
      // Deduct from wallet
      await prisma.user.update({
        where: { id: userId },
        data: { walletBalance: { decrement: calculatedFare } }
      });
    }

    // 4. Create the Trip in DB
    const newTrip = await prisma.trip.create({
      data: {
        riderId: userId,
        pickupLat,
        pickupLng,
        dropOffLat,
        dropOffLng,
        distanceKm,
        status: 'PENDING',
        fare: calculatedFare
      }
    });

    // Record Payment Intent
    await prisma.payment.create({
      data: {
        tripId: newTrip.id,
        userId: userId,
        amount: calculatedFare,
        method: method,
        status: method === 'WALLET' ? 'SUCCESS' : 'PENDING',
      }
    });

    const payload = JSON.stringify({ message: 'Trip requested successfully', trip: newTrip });
    const encryptedData = encrypt(payload);

    // Notify online drivers (simplified to all online drivers for MVP)
    const onlineDrivers = await prisma.driver.findMany({
      where: { isOnline: true },
      include: { user: true }
    });
    
    for (const d of onlineDrivers) {
      if (d.user && d.user.fcmToken) {
        sendPushNotification(
          d.user.fcmToken,
          'طلب رحلة جديد!',
          `هناك طلب رحلة جديد بالقرب منك بمسافة ${distanceKm.toFixed(1)} كم`,
          { tripId: newTrip.id.toString(), type: 'NEW_TRIP' }
        );
      }
    }

    res.json({ encryptedPayload: encryptedData });
  } catch (error) {
    console.error('Trip request error:', error);
    res.status(500).json({ error: 'Failed to request trip' });
  }
});

// Route: Register as Driver
app.post('/api/drivers/register', verifyCustomJWT, async (req, res) => {
  try {
    const userId = req.user.id;
    const { name, phone, vehicleType, plateNumber, nationalId, idCardFront, idCardBack } = req.body;

    if (!name || !phone) {
      return res.status(400).json({ error: 'الاسم ورقم الهاتف مطلوبان' });
    }
    
    if (phone.length !== 11) {
      return res.status(400).json({ error: 'يجب أن يكون رقم الهاتف مكوناً من 11 رقماً' });
    }

    if (!plateNumber || plateNumber.length !== 6) {
      return res.status(400).json({ error: 'يجب إدخال 6 أحرف/أرقام بالضبط للوحة المعدنية' });
    }

    if (!nationalId || nationalId.length !== 14) {
      return res.status(400).json({ error: 'الرقم القومي غير صالح' });
    }

    // Update user name and phone
    await prisma.user.update({
      where: { id: userId },
      data: { name, phone, role: 'DRIVER' }
    });

    // Upsert driver record (Tolerate multiple registrations for testing)
    const newDriver = await prisma.driver.upsert({
      where: { userId: userId },
      update: {
        vehicleType: vehicleType,
        plateNumber: plateNumber,
        nationalId: nationalId,
        idCardFront: idCardFront,
        idCardBack: idCardBack,
        isOnline: false,
        approvalStatus: 'PENDING'
      },
      create: {
        userId: userId,
        vehicleType: vehicleType,
        plateNumber: plateNumber,
        nationalId: nationalId,
        idCardFront: idCardFront,
        idCardBack: idCardBack,
        isOnline: false,
        approvalStatus: 'PENDING'
      }
    });

    const { idCardFront: frontSrc, idCardBack: backSrc, ...driverSafe } = newDriver;
    const payload = JSON.stringify({ message: 'Driver registered successfully', driver: driverSafe });
    const encryptedData = encrypt(payload);
    res.json({ encryptedPayload: encryptedData });

  } catch (error) {
    const fs = require('fs');
    fs.appendFileSync('d:\\GO\\backend\\registration_error.log', new Date().toISOString() + ' ERROR: ' + error.stack + '\n');
    console.error('Driver registration error:', error);
    if (error.code === 'P2002') {
      return res.status(400).json({ error: 'الرقم القومي أو اللوحة مسجلة مسبقاً' });
    }
    res.status(500).json({ error: 'Internal Server Error' });
  }
});

// Route: Get Pending Trips (For Drivers)
app.get('/api/trips/pending', verifyCustomJWT, async (req, res) => {
  try {
    const pendingTrips = await prisma.trip.findMany({
      where: { status: 'PENDING' },
      include: {
        rider: { select: { name: true, phone: true } }
      },
      orderBy: { createdAt: 'desc' },
      take: 20
    });

    const payload = JSON.stringify({ trips: pendingTrips });
    const encryptedData = encrypt(payload);
    res.json({ encryptedPayload: encryptedData });
  } catch (error) {
    console.error('Fetch pending trips error:', error);
    res.status(500).json({ error: 'Failed to fetch pending trips' });
  }
});

// Route: Accept a Trip
app.post('/api/trips/:id/accept', verifyCustomJWT, async (req, res) => {
  try {
    const tripId = parseInt(req.params.id);
    const userId = req.user.id;

    // find driver record tied to user
    const driver = await prisma.driver.findUnique({ where: { userId } });
    if (!driver) {
      return res.status(403).json({ error: 'You must be a registerd driver to accept trips.' });
    }

    // Verify trip is still pending
    const trip = await prisma.trip.findUnique({ where: { id: tripId } });
    if (!trip || trip.status !== 'PENDING') {
      return res.status(400).json({ error: 'Trip is no longer available.' });
    }

    // Assign to driver 
    const updatedTrip = await prisma.trip.update({
      where: { id: tripId },
      data: {
        driverId: driver.id,
        status: 'ACCEPTED'
      }
    });

    const payload = JSON.stringify({ message: 'Trip accepted successfully', trip: updatedTrip });
    const encryptedData = encrypt(payload);
    res.json({ encryptedPayload: encryptedData });

    // Notify Rider
    const rider = await prisma.user.findUnique({ where: { id: trip.riderId } });
    if (rider && rider.fcmToken) {
      sendPushNotification(
        rider.fcmToken,
        'تم قبول رحلتك!',
        'الكابتن الآن في طريقه إليك.',
        { tripId: updatedTrip.id.toString(), type: 'TRIP_ACCEPTED' }
      );
    }

  } catch (error) {
    console.error('Accept trip error:', error);
    res.status(500).json({ error: 'Internal Server Error' });
  }
});

// Route: Get Trip Status (For Live Tracking)
app.get('/api/trips/:id/status', async (req, res) => {
  try {
    const tripId = parseInt(req.params.id);

    const trip = await prisma.trip.findUnique({
      where: { id: tripId },
      include: {
        driver: {
          select: {
            vehicleType: true,
            plateNumber: true,
            rating: true,
            currentLat: true,
            currentLng: true,
            user: { select: { name: true, phone: true } }
          }
        },
        rider: { select: { name: true, phone: false } } // Phone hidden for privacy
      }
    });

    if (!trip) return res.status(404).json({ error: 'Trip not found' });

    const payload = JSON.stringify({ trip: trip });
    const encryptedData = encrypt(payload);
    res.json({ encryptedPayload: encryptedData });

  } catch (error) {
    console.error('Get trip status error:', error);
    res.status(500).json({ error: 'Internal Server Error' });
  }
});

// Route: Update Trip Status (Driver action)
app.post('/api/trips/:id/update-status', verifyCustomJWT, async (req, res) => {
  try {
    const tripId = parseInt(req.params.id);
    const userId = req.user.id;
    const { status } = req.body; // e.g. 'IN_PROGRESS', 'COMPLETED'

    const driver = await prisma.driver.findUnique({ where: { userId } });
    if (!driver) return res.status(403).json({ error: 'Only drivers can update status' });

    const trip = await prisma.trip.findUnique({ where: { id: tripId } });
    if (trip.driverId !== driver.id) {
      return res.status(403).json({ error: 'You are not assigned to this trip' });
    }

    const updatedTrip = await prisma.trip.update({
      where: { id: tripId },
      data: { status: status }
    });

    // If completed, maybe check payment or transfer money, etc. omitted for briefness

    const payload = JSON.stringify({ message: 'Status updated', trip: updatedTrip });
    const encryptedData = encrypt(payload);
    res.json({ encryptedPayload: encryptedData });

  } catch (error) {
    console.error('Update trip status error:', error);
    res.status(500).json({ error: 'Internal Server Error' });
  }
});

// Route: Get Trip Messages
app.get('/api/trips/:id/messages', verifyCustomJWT, async (req, res) => {
  try {
    const tripId = parseInt(req.params.id);
    const userId = req.user.id;

    // Optional: Verify user is part of the trip
    const messages = await prisma.message.findMany({
      where: { tripId: tripId },
      orderBy: { createdAt: 'asc' }
    });

    const payload = JSON.stringify({ messages: messages });
    const encryptedData = encrypt(payload);
    res.json({ encryptedPayload: encryptedData });
  } catch (error) {
    console.error('Get messages error:', error);
    res.status(500).json({ error: 'Internal Server Error' });
  }
});

// Route: Send Trip Message
app.post('/api/trips/:id/messages', verifyCustomJWT, async (req, res) => {
  try {
    const tripId = parseInt(req.params.id);
    const userId = req.user.id;
    const { content } = req.body;

    if (!content) return res.status(400).json({ error: 'Message content is empty' });

    const trip = await prisma.trip.findUnique({ where: { id: tripId }, include: { driver: true } });
    if (!trip || trip.status === 'COMPLETED') {
      return res.status(400).json({ error: 'Cannot send messages to this trip' });
    }

    const newMessage = await prisma.message.create({
      data: {
        tripId: tripId,
        senderId: userId,
        content: content
      }
    });

    const payload = JSON.stringify({ message: 'Message sent', data: newMessage });
    const encryptedData = encrypt(payload);
    res.json({ encryptedPayload: encryptedData });
  } catch (error) {
    console.error('Send message error:', error);
    res.status(500).json({ error: 'Internal Server Error' });
  }
});

// Route: Update Driver Location
app.post('/api/drivers/location', verifyCustomJWT, async (req, res) => {
  try {
    const userId = req.user.id;
    const { lat, lng } = req.body;

    if (lat === undefined || lng === undefined) {
      return res.status(400).json({ error: 'Missing coordinates' });
    }

    const driver = await prisma.driver.findUnique({ where: { userId } });
    if (!driver) {
      return res.status(403).json({ error: 'You must be a registered driver.' });
    }

    await prisma.driver.update({
      where: { id: driver.id },
      data: {
        currentLat: lat,
        currentLng: lng
      }
    });

    res.json({ success: true, message: 'Location updated' });
  } catch (error) {
    console.error('Update driver location error:', error);
    res.status(500).json({ error: 'Internal Server Error' });
  }
});

// Route: Admin Get Driver Tracking Info
app.get('/api/admin/drivers/:id/tracking', verifyCustomJWT, async (req, res) => {
  try {
    if (req.user.role !== 'ADMIN') return res.status(403).json({ error: 'Forbidden' });
    
    const driverId = parseInt(req.params.id);
    const driver = await prisma.driver.findUnique({
      where: { id: driverId },
      include: {
        user: true,
        trips: {
          where: {
            status: { in: ['ACCEPTED', 'IN_PROGRESS'] }
          },
          orderBy: { createdAt: 'desc' },
          take: 1
        }
      }
    });

    if (!driver) return res.status(404).json({ error: 'Driver not found' });

    const activeTrip = driver.trips.length > 0 ? driver.trips[0] : null;

    const payload = JSON.stringify({
      driver: {
        id: driver.id,
        currentLat: driver.currentLat,
        currentLng: driver.currentLng,
        isOnline: driver.isOnline,
        vehicleType: driver.vehicleType,
        user: { name: driver.user.name, phone: driver.user.phone }
      },
      activeTrip
    });
    
    const encryptedData = encrypt(payload);
    res.json({ encryptedPayload: encryptedData });
  } catch (error) {
    console.error('Admin driver tracking error:', error);
    res.status(500).json({ error: 'Internal Server Error' });
  }
});

// Route: Admin Metrics
app.get('/api/admin/metrics', verifyCustomJWT, async (req, res) => {
  try {
    const userId = req.user.id;
    // Verify admin role 
    // Usually via user.role, but let's query DB for safety
    const user = await prisma.user.findUnique({ where: { id: userId } });
    
    // Verify admin role 
    if (!user || user.role !== 'ADMIN') return res.status(403).json({ error: 'Forbidden' });
    
    const totalUsers = await prisma.user.count();
    const totalDrivers = await prisma.driver.count();
    const totalTrips = await prisma.trip.count();
    const completedTrips = await prisma.trip.count({ where: { status: 'COMPLETED' } });
    
    // Sum revenue from payments
    const payments = await prisma.payment.aggregate({
      _sum: { amount: true },
      where: { status: 'SUCCESS' }
    });
    const totalRevenue = payments._sum.amount ?? 0;

    const recentTrips = await prisma.trip.findMany({
      orderBy: { createdAt: 'desc' },
      take: 10,
      include: {
        rider: { select: { name: true, phone: true } },
        driver: { select: { vehicleType: true, plateNumber: true, user: { select: { name: true } } } }
      }
    });

    const payload = JSON.stringify({
      metrics: {
        totalUsers,
        totalDrivers,
        totalTrips,
        completedTrips,
        totalRevenue
      },
      recentTrips
    });
    
    const encryptedData = encrypt(payload);
    res.json({ encryptedPayload: encryptedData });
  } catch (error) {
    console.error('Admin metrics error:', error);
    res.status(500).json({ error: 'Internal Server Error' });
  }
});


// Route: Admin Drivers
app.get('/api/admin/drivers', verifyCustomJWT, async (req, res) => {
  try {
    const userId = req.user.id;
    // Assuming backend limits this to role === 'ADMIN' eventually
    
    // Fetch all drivers including user details
    const drivers = await prisma.driver.findMany({
      orderBy: { createdAt: 'desc' },
      include: {
        user: { select: { name: true, phone: true } }
      }
    });

    const payload = JSON.stringify({ drivers });
    const encryptedData = encrypt(payload);
    res.json({ encryptedPayload: encryptedData });
  } catch (error) {
    console.error('Admin drivers error:', error);
    res.status(500).json({ error: 'Internal Server Error' });
  }
});

// Route: Admin Approve Driver
app.post('/api/admin/drivers/:id/approve', verifyCustomJWT, async (req, res) => {
  try {
    const driverId = parseInt(req.params.id);
    const updatedDriver = await prisma.driver.update({
      where: { id: driverId },
      data: { approvalStatus: 'APPROVED' }
    });
    const payload = JSON.stringify({ message: 'Driver approved successfully', driver: updatedDriver });
    const encryptedData = encrypt(payload);
    res.json({ encryptedPayload: encryptedData });
  } catch (error) {
    console.error('Admin approve driver error:', error);
    res.status(500).json({ error: 'Internal Server Error' });
  }
});

// Route: Admin Reject Driver
app.post('/api/admin/drivers/:id/reject', verifyCustomJWT, async (req, res) => {
  try {
    const driverId = parseInt(req.params.id);
    const updatedDriver = await prisma.driver.update({
      where: { id: driverId },
      data: { approvalStatus: 'REJECTED' }
    });
    const payload = JSON.stringify({ message: 'Driver rejected successfully', driver: updatedDriver });
    const encryptedData = encrypt(payload);
    res.json({ encryptedPayload: encryptedData });
  } catch (error) {
    console.error('Admin reject driver error:', error);
    res.status(500).json({ error: 'Internal Server Error' });
  }
});


// Route: Admin Users
app.get('/api/admin/users', verifyCustomJWT, async (req, res) => {
  try {
    const users = await prisma.user.findMany({
      orderBy: { createdAt: 'desc' },
    });
    const payload = JSON.stringify({ users });
    const encryptedData = encrypt(payload);
    res.json({ encryptedPayload: encryptedData });
  } catch (error) {
    console.error('Admin users error:', error);
    res.status(500).json({ error: 'Internal Server Error' });
  }
});

// Route: Admin Trips
app.get('/api/admin/trips', verifyCustomJWT, async (req, res) => {
  try {
    const trips = await prisma.trip.findMany({
      orderBy: { createdAt: 'desc' },
      include: {
        rider: { select: { name: true, phone: true } },
        driver: { select: { vehicleType: true, plateNumber: true, user: { select: { name: true, phone: true } } } }
      }
    });
    const payload = JSON.stringify({ trips });
    const encryptedData = encrypt(payload);
    res.json({ encryptedPayload: encryptedData });
  } catch (error) {
    console.error('Estimate trip error:', error);
    res.status(500).json({ error: 'Internal Server Error' });
  }
});



// Route: Request Promo Code
app.post('/api/wallet/promo', verifyCustomJWT, async (req, res) => {
  try {
    const { code } = req.body;
    if (code !== 'FREE50') return res.status(400).json({ error: 'Invalid Promo Code' });

    // Validate if the user has used it (Simplified logic: always give it for MVP testing)
    const newBalance = await prisma.user.update({
      where: { id: req.user.id },
      data: { walletBalance: { increment: 50.0 } }
    });

    const encryptedData = encrypt(JSON.stringify({ balance: newBalance.walletBalance }));
    res.json({ encryptedPayload: encryptedData });
  } catch (error) {
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Route: Pay Trip Cost from Wallet
app.post('/api/trips/:id/pay', verifyCustomJWT, async (req, res) => {
  try {
    const tripId = parseInt(req.params.id);
    const trip = await prisma.trip.findUnique({
      where: { id: tripId },
      include: { driver: { include: { user: true } }, user: true }
    });

    if (!trip || trip.userId !== req.user.id) return res.status(404).json({ error: 'Trip not found or unauthorized' });
    if (trip.status !== 'FINISHED' && trip.status !== 'IN_PROGRESS') return res.status(400).json({ error: 'Trip must be active or finished' });

    const cost = trip.fare || 0;
    
    // Check rider wallet
    if (trip.user.walletBalance < cost) {
      return res.status(400).json({ error: 'Insufficient wallet balance' });
    }

    // Trip cost logic (10% app commission, 90% driver)
    const appCommission = cost * 0.10;
    const driverShare = cost * 0.90;

    await prisma.$transaction([
      // Deduct from Rider
      prisma.user.update({
        where: { id: trip.userId },
        data: { walletBalance: { decrement: cost } }
      }),
      // Add to Driver user
      prisma.user.update({
        where: { id: trip.driver.userId },
        data: { walletBalance: { increment: driverShare } }
      }),
      // Log payment history
      prisma.payment.create({
        data: {
          userId: trip.userId,
          tripId: trip.id,
          amount: cost,
          paymentMethod: 'WALLET',
          status: 'COMPLETED'
        }
      }),
      // Mark trip as COMPLETED
      prisma.trip.update({
        where: { id: trip.id },
        data: { status: 'COMPLETED' }
      })
    ]);

    // Add app profit metric (System Revenue log) could exist here if Metric table exists
    
    const encryptedData = encrypt(JSON.stringify({ success: true }));
    res.json({ encryptedPayload: encryptedData });
  } catch (error) {
    console.error('Wallet Pay Trip error:', error);
    res.status(500).json({ error: 'Internal Server Error' });
  }
});

// Route: Admin Financials
app.get('/api/admin/financials', verifyCustomJWT, async (req, res) => {
  try {
    const payments = await prisma.payment.findMany({
      where: { status: 'SUCCESS' },
      orderBy: { createdAt: 'desc' },
      include: {
        user: { select: { name: true, phone: true } },
        trip: { select: { id: true, fare: true } }
      }
    });
    
    const aggregated = await prisma.payment.aggregate({
      _sum: { amount: true },
      _count: { id: true },
      where: { status: 'SUCCESS' }
    });

    const payload = JSON.stringify({
      payments,
      totalRevenue: aggregated._sum.amount ?? 0,
      totalTransactions: aggregated._count.id
    });
    const encryptedData = encrypt(payload);
    res.json({ encryptedPayload: encryptedData });
  } catch (error) {
    console.error('Admin financials error:', error);
    res.status(500).json({ error: 'Internal Server Error' });
  }
});

// A public health-check route
app.get('/health', (req, res) => {
  res.json({ status: 'ok', db: 'PostgreSQL will be connected here' });
});

app.listen(PORT, '0.0.0.0', () => {
    console.log(`Server is running on port ${PORT}`);
});
