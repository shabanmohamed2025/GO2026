
Object.defineProperty(exports, "__esModule", { value: true });

const {
  PrismaClientKnownRequestError,
  PrismaClientUnknownRequestError,
  PrismaClientRustPanicError,
  PrismaClientInitializationError,
  PrismaClientValidationError,
  NotFoundError,
  getPrismaClient,
  sqltag,
  empty,
  join,
  raw,
  skip,
  Decimal,
  Debug,
  objectEnumValues,
  makeStrictEnum,
  Extensions,
  warnOnce,
  defineDmmfProperty,
  Public,
  getRuntime
} = require('./runtime/wasm.js')


const Prisma = {}

exports.Prisma = Prisma
exports.$Enums = {}

/**
 * Prisma Client JS version: 5.22.0
 * Query Engine version: 605197351a3c8bdd595af2d2a9bc3025bca48ea2
 */
Prisma.prismaVersion = {
  client: "5.22.0",
  engine: "605197351a3c8bdd595af2d2a9bc3025bca48ea2"
}

Prisma.PrismaClientKnownRequestError = PrismaClientKnownRequestError;
Prisma.PrismaClientUnknownRequestError = PrismaClientUnknownRequestError
Prisma.PrismaClientRustPanicError = PrismaClientRustPanicError
Prisma.PrismaClientInitializationError = PrismaClientInitializationError
Prisma.PrismaClientValidationError = PrismaClientValidationError
Prisma.NotFoundError = NotFoundError
Prisma.Decimal = Decimal

/**
 * Re-export of sql-template-tag
 */
Prisma.sql = sqltag
Prisma.empty = empty
Prisma.join = join
Prisma.raw = raw
Prisma.validator = Public.validator

/**
* Extensions
*/
Prisma.getExtensionContext = Extensions.getExtensionContext
Prisma.defineExtension = Extensions.defineExtension

/**
 * Shorthand utilities for JSON filtering
 */
Prisma.DbNull = objectEnumValues.instances.DbNull
Prisma.JsonNull = objectEnumValues.instances.JsonNull
Prisma.AnyNull = objectEnumValues.instances.AnyNull

Prisma.NullTypes = {
  DbNull: objectEnumValues.classes.DbNull,
  JsonNull: objectEnumValues.classes.JsonNull,
  AnyNull: objectEnumValues.classes.AnyNull
}





/**
 * Enums
 */
exports.Prisma.TransactionIsolationLevel = makeStrictEnum({
  ReadUncommitted: 'ReadUncommitted',
  ReadCommitted: 'ReadCommitted',
  RepeatableRead: 'RepeatableRead',
  Serializable: 'Serializable'
});

exports.Prisma.UserScalarFieldEnum = {
  id: 'id',
  firebaseUid: 'firebaseUid',
  phone: 'phone',
  name: 'name',
  role: 'role',
  walletBalance: 'walletBalance',
  fcmToken: 'fcmToken',
  createdAt: 'createdAt',
  updatedAt: 'updatedAt'
};

exports.Prisma.DriverScalarFieldEnum = {
  id: 'id',
  userId: 'userId',
  vehicleType: 'vehicleType',
  plateNumber: 'plateNumber',
  nationalId: 'nationalId',
  idCardFront: 'idCardFront',
  idCardBack: 'idCardBack',
  rating: 'rating',
  isOnline: 'isOnline',
  approvalStatus: 'approvalStatus',
  currentLat: 'currentLat',
  currentLng: 'currentLng',
  walletBalance: 'walletBalance',
  createdAt: 'createdAt',
  updatedAt: 'updatedAt'
};

exports.Prisma.TripScalarFieldEnum = {
  id: 'id',
  riderId: 'riderId',
  driverId: 'driverId',
  pickupLat: 'pickupLat',
  pickupLng: 'pickupLng',
  pickupAddress: 'pickupAddress',
  dropOffLat: 'dropOffLat',
  dropOffLng: 'dropOffLng',
  dropOffAddress: 'dropOffAddress',
  status: 'status',
  distanceKm: 'distanceKm',
  durationMin: 'durationMin',
  fare: 'fare',
  createdAt: 'createdAt',
  updatedAt: 'updatedAt'
};

exports.Prisma.PricingRuleScalarFieldEnum = {
  id: 'id',
  vehicleType: 'vehicleType',
  baseFare: 'baseFare',
  perKmRate: 'perKmRate',
  perMinRate: 'perMinRate',
  surgeMultiplier: 'surgeMultiplier',
  updatedAt: 'updatedAt'
};

exports.Prisma.PaymentScalarFieldEnum = {
  id: 'id',
  tripId: 'tripId',
  userId: 'userId',
  amount: 'amount',
  method: 'method',
  status: 'status',
  paymobOrderId: 'paymobOrderId',
  createdAt: 'createdAt'
};

exports.Prisma.MessageScalarFieldEnum = {
  id: 'id',
  tripId: 'tripId',
  senderId: 'senderId',
  content: 'content',
  createdAt: 'createdAt'
};

exports.Prisma.SortOrder = {
  asc: 'asc',
  desc: 'desc'
};

exports.Prisma.QueryMode = {
  default: 'default',
  insensitive: 'insensitive'
};

exports.Prisma.NullsOrder = {
  first: 'first',
  last: 'last'
};


exports.Prisma.ModelName = {
  User: 'User',
  Driver: 'Driver',
  Trip: 'Trip',
  PricingRule: 'PricingRule',
  Payment: 'Payment',
  Message: 'Message'
};
/**
 * Create the Client
 */
const config = {
  "generator": {
    "name": "client",
    "provider": {
      "fromEnvVar": null,
      "value": "prisma-client-js"
    },
    "output": {
      "value": "D:\\GO\\backend\\generated_client",
      "fromEnvVar": null
    },
    "config": {
      "engineType": "library"
    },
    "binaryTargets": [
      {
        "fromEnvVar": null,
        "value": "windows",
        "native": true
      }
    ],
    "previewFeatures": [
      "driverAdapters"
    ],
    "sourceFilePath": "D:\\GO\\backend\\prisma\\schema.prisma",
    "isCustomOutput": true
  },
  "relativeEnvPaths": {
    "rootEnvPath": null,
    "schemaEnvPath": "../.env"
  },
  "relativePath": "../prisma",
  "clientVersion": "5.22.0",
  "engineVersion": "605197351a3c8bdd595af2d2a9bc3025bca48ea2",
  "datasourceNames": [
    "db"
  ],
  "activeProvider": "postgresql",
  "postinstall": false,
  "inlineDatasources": {
    "db": {
      "url": {
        "fromEnvVar": "DATABASE_URL",
        "value": null
      }
    }
  },
  "inlineSchema": "// This is your Prisma schema file.\n// Learn more about it in the docs: https://pris.ly/d/prisma-schema\n\ngenerator client {\n  provider        = \"prisma-client-js\"\n  output          = \"../generated_client\"\n  previewFeatures = [\"driverAdapters\"]\n}\n\ndatasource db {\n  provider = \"postgresql\"\n  url      = env(\"DATABASE_URL\")\n}\n\nmodel User {\n  id            Int      @id @default(autoincrement())\n  firebaseUid   String   @unique\n  phone         String?  @unique\n  name          String?\n  role          String   @default(\"USER\") // USER, DRIVER, ADMIN\n  walletBalance Float    @default(0.0) // محفظة المستخدم\n  fcmToken      String? // رمز الإشعارات للهاتف\n  createdAt     DateTime @default(now())\n  updatedAt     DateTime @updatedAt\n\n  driverProfile Driver?\n  tripsAsRider  Trip[]    @relation(\"RiderTrips\")\n  payments      Payment[]\n}\n\nmodel Driver {\n  id             Int      @id @default(autoincrement())\n  userId         Int      @unique\n  user           User     @relation(fields: [userId], references: [id])\n  vehicleType    String   @default(\"Tricycle\")\n  plateNumber    String?  @unique\n  nationalId     String?  @unique\n  idCardFront    String?\n  idCardBack     String?\n  rating         Float    @default(5.0)\n  isOnline       Boolean  @default(false)\n  approvalStatus String   @default(\"PENDING\") // PENDING, APPROVED, REJECTED\n  currentLat     Float?\n  currentLng     Float?\n  walletBalance  Float    @default(0.0) // محفظة السائق المتخصصة في الأرباح\n  createdAt      DateTime @default(now())\n  updatedAt      DateTime @updatedAt\n\n  trips Trip[] @relation(\"DriverTrips\")\n}\n\nmodel Trip {\n  id       Int     @id @default(autoincrement())\n  riderId  Int\n  rider    User    @relation(\"RiderTrips\", fields: [riderId], references: [id])\n  driverId Int?\n  driver   Driver? @relation(\"DriverTrips\", fields: [driverId], references: [id])\n\n  pickupLat      Float\n  pickupLng      Float\n  pickupAddress  String?\n  dropOffLat     Float\n  dropOffLng     Float\n  dropOffAddress String?\n\n  status      String @default(\"PENDING\") // PENDING, ACCEPTED, IN_PROGRESS, COMPLETED, CANCELLED\n  distanceKm  Float?\n  durationMin Int?\n  fare        Float? // التسعيرة الإجمالية\n\n  createdAt DateTime @default(now())\n  updatedAt DateTime @updatedAt\n\n  payment  Payment?\n  messages Message[]\n}\n\nmodel PricingRule {\n  id              Int      @id @default(autoincrement())\n  vehicleType     String   @unique @default(\"Tricycle\")\n  baseFare        Float    @default(5.0) // السعر الابتدائي\n  perKmRate       Float    @default(3.0) // السعر لكل كيلو متر\n  perMinRate      Float    @default(0.5) // السعر لكل دقيقة انتظار\n  surgeMultiplier Float    @default(1.0) // وقت الذروة\n  updatedAt       DateTime @updatedAt\n}\n\nmodel Payment {\n  id     Int   @id @default(autoincrement())\n  tripId Int?  @unique\n  trip   Trip? @relation(fields: [tripId], references: [id])\n  userId Int\n  user   User  @relation(fields: [userId], references: [id])\n\n  amount        Float\n  method        String  @default(\"PAYMOB\") // CASH, WALLET, PAYMOB\n  status        String  @default(\"PENDING\") // PENDING, SUCCESS, FAILED\n  paymobOrderId String? @unique // To map Paymob transaction locally\n\n  createdAt DateTime @default(now())\n}\n\nmodel Message {\n  id        Int      @id @default(autoincrement())\n  tripId    Int\n  trip      Trip     @relation(fields: [tripId], references: [id])\n  senderId  Int\n  content   String\n  createdAt DateTime @default(now())\n}\n",
  "inlineSchemaHash": "dfdd7c172ee1250ec6b1923ba8a337db3e13c2a08d1391b10854cc4f7e10b2ba",
  "copyEngine": true
}
config.dirname = '/'

config.runtimeDataModel = JSON.parse("{\"models\":{\"User\":{\"fields\":[{\"name\":\"id\",\"kind\":\"scalar\",\"type\":\"Int\"},{\"name\":\"firebaseUid\",\"kind\":\"scalar\",\"type\":\"String\"},{\"name\":\"phone\",\"kind\":\"scalar\",\"type\":\"String\"},{\"name\":\"name\",\"kind\":\"scalar\",\"type\":\"String\"},{\"name\":\"role\",\"kind\":\"scalar\",\"type\":\"String\"},{\"name\":\"walletBalance\",\"kind\":\"scalar\",\"type\":\"Float\"},{\"name\":\"fcmToken\",\"kind\":\"scalar\",\"type\":\"String\"},{\"name\":\"createdAt\",\"kind\":\"scalar\",\"type\":\"DateTime\"},{\"name\":\"updatedAt\",\"kind\":\"scalar\",\"type\":\"DateTime\"},{\"name\":\"driverProfile\",\"kind\":\"object\",\"type\":\"Driver\",\"relationName\":\"DriverToUser\"},{\"name\":\"tripsAsRider\",\"kind\":\"object\",\"type\":\"Trip\",\"relationName\":\"RiderTrips\"},{\"name\":\"payments\",\"kind\":\"object\",\"type\":\"Payment\",\"relationName\":\"PaymentToUser\"}],\"dbName\":null},\"Driver\":{\"fields\":[{\"name\":\"id\",\"kind\":\"scalar\",\"type\":\"Int\"},{\"name\":\"userId\",\"kind\":\"scalar\",\"type\":\"Int\"},{\"name\":\"user\",\"kind\":\"object\",\"type\":\"User\",\"relationName\":\"DriverToUser\"},{\"name\":\"vehicleType\",\"kind\":\"scalar\",\"type\":\"String\"},{\"name\":\"plateNumber\",\"kind\":\"scalar\",\"type\":\"String\"},{\"name\":\"nationalId\",\"kind\":\"scalar\",\"type\":\"String\"},{\"name\":\"idCardFront\",\"kind\":\"scalar\",\"type\":\"String\"},{\"name\":\"idCardBack\",\"kind\":\"scalar\",\"type\":\"String\"},{\"name\":\"rating\",\"kind\":\"scalar\",\"type\":\"Float\"},{\"name\":\"isOnline\",\"kind\":\"scalar\",\"type\":\"Boolean\"},{\"name\":\"approvalStatus\",\"kind\":\"scalar\",\"type\":\"String\"},{\"name\":\"currentLat\",\"kind\":\"scalar\",\"type\":\"Float\"},{\"name\":\"currentLng\",\"kind\":\"scalar\",\"type\":\"Float\"},{\"name\":\"walletBalance\",\"kind\":\"scalar\",\"type\":\"Float\"},{\"name\":\"createdAt\",\"kind\":\"scalar\",\"type\":\"DateTime\"},{\"name\":\"updatedAt\",\"kind\":\"scalar\",\"type\":\"DateTime\"},{\"name\":\"trips\",\"kind\":\"object\",\"type\":\"Trip\",\"relationName\":\"DriverTrips\"}],\"dbName\":null},\"Trip\":{\"fields\":[{\"name\":\"id\",\"kind\":\"scalar\",\"type\":\"Int\"},{\"name\":\"riderId\",\"kind\":\"scalar\",\"type\":\"Int\"},{\"name\":\"rider\",\"kind\":\"object\",\"type\":\"User\",\"relationName\":\"RiderTrips\"},{\"name\":\"driverId\",\"kind\":\"scalar\",\"type\":\"Int\"},{\"name\":\"driver\",\"kind\":\"object\",\"type\":\"Driver\",\"relationName\":\"DriverTrips\"},{\"name\":\"pickupLat\",\"kind\":\"scalar\",\"type\":\"Float\"},{\"name\":\"pickupLng\",\"kind\":\"scalar\",\"type\":\"Float\"},{\"name\":\"pickupAddress\",\"kind\":\"scalar\",\"type\":\"String\"},{\"name\":\"dropOffLat\",\"kind\":\"scalar\",\"type\":\"Float\"},{\"name\":\"dropOffLng\",\"kind\":\"scalar\",\"type\":\"Float\"},{\"name\":\"dropOffAddress\",\"kind\":\"scalar\",\"type\":\"String\"},{\"name\":\"status\",\"kind\":\"scalar\",\"type\":\"String\"},{\"name\":\"distanceKm\",\"kind\":\"scalar\",\"type\":\"Float\"},{\"name\":\"durationMin\",\"kind\":\"scalar\",\"type\":\"Int\"},{\"name\":\"fare\",\"kind\":\"scalar\",\"type\":\"Float\"},{\"name\":\"createdAt\",\"kind\":\"scalar\",\"type\":\"DateTime\"},{\"name\":\"updatedAt\",\"kind\":\"scalar\",\"type\":\"DateTime\"},{\"name\":\"payment\",\"kind\":\"object\",\"type\":\"Payment\",\"relationName\":\"PaymentToTrip\"},{\"name\":\"messages\",\"kind\":\"object\",\"type\":\"Message\",\"relationName\":\"MessageToTrip\"}],\"dbName\":null},\"PricingRule\":{\"fields\":[{\"name\":\"id\",\"kind\":\"scalar\",\"type\":\"Int\"},{\"name\":\"vehicleType\",\"kind\":\"scalar\",\"type\":\"String\"},{\"name\":\"baseFare\",\"kind\":\"scalar\",\"type\":\"Float\"},{\"name\":\"perKmRate\",\"kind\":\"scalar\",\"type\":\"Float\"},{\"name\":\"perMinRate\",\"kind\":\"scalar\",\"type\":\"Float\"},{\"name\":\"surgeMultiplier\",\"kind\":\"scalar\",\"type\":\"Float\"},{\"name\":\"updatedAt\",\"kind\":\"scalar\",\"type\":\"DateTime\"}],\"dbName\":null},\"Payment\":{\"fields\":[{\"name\":\"id\",\"kind\":\"scalar\",\"type\":\"Int\"},{\"name\":\"tripId\",\"kind\":\"scalar\",\"type\":\"Int\"},{\"name\":\"trip\",\"kind\":\"object\",\"type\":\"Trip\",\"relationName\":\"PaymentToTrip\"},{\"name\":\"userId\",\"kind\":\"scalar\",\"type\":\"Int\"},{\"name\":\"user\",\"kind\":\"object\",\"type\":\"User\",\"relationName\":\"PaymentToUser\"},{\"name\":\"amount\",\"kind\":\"scalar\",\"type\":\"Float\"},{\"name\":\"method\",\"kind\":\"scalar\",\"type\":\"String\"},{\"name\":\"status\",\"kind\":\"scalar\",\"type\":\"String\"},{\"name\":\"paymobOrderId\",\"kind\":\"scalar\",\"type\":\"String\"},{\"name\":\"createdAt\",\"kind\":\"scalar\",\"type\":\"DateTime\"}],\"dbName\":null},\"Message\":{\"fields\":[{\"name\":\"id\",\"kind\":\"scalar\",\"type\":\"Int\"},{\"name\":\"tripId\",\"kind\":\"scalar\",\"type\":\"Int\"},{\"name\":\"trip\",\"kind\":\"object\",\"type\":\"Trip\",\"relationName\":\"MessageToTrip\"},{\"name\":\"senderId\",\"kind\":\"scalar\",\"type\":\"Int\"},{\"name\":\"content\",\"kind\":\"scalar\",\"type\":\"String\"},{\"name\":\"createdAt\",\"kind\":\"scalar\",\"type\":\"DateTime\"}],\"dbName\":null}},\"enums\":{},\"types\":{}}")
defineDmmfProperty(exports.Prisma, config.runtimeDataModel)
config.engineWasm = {
  getRuntime: () => require('./query_engine_bg.js'),
  getQueryEngineWasmModule: async () => {
    const loader = (await import('#wasm-engine-loader')).default
    const engine = (await loader).default
    return engine 
  }
}

config.injectableEdgeEnv = () => ({
  parsed: {
    DATABASE_URL: typeof globalThis !== 'undefined' && globalThis['DATABASE_URL'] || typeof process !== 'undefined' && process.env && process.env.DATABASE_URL || undefined
  }
})

if (typeof globalThis !== 'undefined' && globalThis['DEBUG'] || typeof process !== 'undefined' && process.env && process.env.DEBUG || undefined) {
  Debug.enable(typeof globalThis !== 'undefined' && globalThis['DEBUG'] || typeof process !== 'undefined' && process.env && process.env.DEBUG || undefined)
}

const PrismaClient = getPrismaClient(config)
exports.PrismaClient = PrismaClient
Object.assign(exports, Prisma)

