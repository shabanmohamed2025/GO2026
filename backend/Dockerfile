# Build standard Node.js image
FROM node:20-slim

# Install OpenSSL for Prisma
RUN apt-get update -y && apt-get install -y openssl

WORKDIR /workspace/backend

# 1. نسخ ملفات الحزم لتثبيت الاعتماديات
COPY package*.json ./

# 2. نسخ مجلد prisma
COPY prisma ./prisma/

# 3. تثبيت الحزم (بدون إزالة حزم التطوير لضمان عمل Prisma إذا لزم)
RUN npm install

# 4. توليد عميل Prisma الأساسي
RUN npx prisma generate

# 5. نسخ باقي الكود والبناء
COPY . .

# فك المنفذ 3000
EXPOSE 3000

# 6. أمر التشغيل النهائي
CMD ["npm", "start"]
