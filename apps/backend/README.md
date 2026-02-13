# Local Service Platform - Backend

Backend API cho nền tảng dịch vụ địa phương, xây dựng bằng NestJS + Prisma + PostgreSQL.

## 🚀 Quick Start

### 1. Cài đặt Dependencies

```bash
npm install
```

### 2. Cấu hình Environment

Sao chép file `.env.example` thành `.env`:

```bash
cp .env.example .env
```

Cập nhật các giá trị trong `.env` theo môi trường của bạn.

### 3. Setup Database

```bash
# Chạy migrations
npx prisma migrate dev

# (Optional) Seed data
npx prisma db seed
```

### 4. Chạy Development Server

```bash
npm run start:dev
```

Server sẽ chạy tại: `http://localhost:3000`

API Documentation (Swagger): `http://localhost:3000/api`

## 📁 Cấu trúc Project

```
src/
├── modules/          # Feature modules
│   ├── auth/        # Authentication & Authorization
│   ├── users/       # User management
│   ├── provider/    # Provider profiles
│   ├── services/    # Service catalog
│   ├── bookings/    # Booking management
│   ├── payments/    # Payment processing
│   ├── wallets/     # Wallet & transactions
│   ├── conversations/ # Chat & messaging
│   ├── disputes/    # Dispute resolution
│   ├── admin/       # Admin operations
│   └── system/      # System utilities
├── common/          # Shared code
│   ├── decorators/  # Custom decorators (@CurrentUser, @Roles)
│   ├── filters/     # Exception filters
│   ├── guards/      # Auth guards (JWT, Roles)
│   └── interceptors/ # Response transform
├── config/          # Configuration
└── prisma/          # Prisma client
```

## 🔑 Environment Variables

Xem file `.env.example` để biết danh sách đầy đủ các biến môi trường.

**Quan trọng:** Thay đổi `JWT_SECRET` và `JWT_REFRESH_SECRET` trong production!

## 📝 API Documentation

Sau khi chạy server, truy cập Swagger UI tại:

- Development: `http://localhost:3000/api`

## 🧪 Testing

```bash
# Unit tests
npm run test

# E2E tests
npm run test:e2e

# Test coverage
npm run test:cov
```

## 🏗️ Build

```bash
npm run build
```

## 👥 Team Development

### Module Ownership

- **Member 1 (Foundation):** Auth, Users, System
- **Member 2 (Marketplace):** Services, Provider, Bookings
- **Member 3 (Finance):** Wallets, Payments, Admin, Interactions

### Coding Standards

1. **DTOs:** Sử dụng `class-validator` cho validation
2. **Response Format:** Tất cả response đều qua `TransformInterceptor` → `{ data, statusCode, message }`
3. **Error Handling:** Sử dụng `GlobalExceptionFilter` để format lỗi chuẩn
4. **Auth:** Protected routes dùng `@UseGuards(JwtAuthGuard)`
5. **Current User:** Dùng `@CurrentUser()` decorator để lấy user info

### Git Workflow

```bash
# Tạo branch từ main
git checkout -b feature/module-name

# Commit changes
git add .
git commit -m "feat(module): description"

# Push và tạo PR
git push origin feature/module-name
```

## 📚 Tech Stack

- **Framework:** NestJS 10.x
- **Database:** PostgreSQL 15+ (with PostGIS)
- **ORM:** Prisma 5.x
- **Validation:** class-validator, class-transformer
- **Auth:** JWT (passport-jwt)
- **Documentation:** Swagger/OpenAPI

## 🔗 Related Docs

- [API Endpoints](../../.gemini/antigravity/brain/293e6146-71f4-4af5-a9d7-c317bea43ebb/endpoints.md)
- [Work Division](../../.gemini/antigravity/brain/293e6146-71f4-4af5-a9d7-c317bea43ebb/work_division.md)
- [Implementation Plans](../../.gemini/antigravity/brain/293e6146-71f4-4af5-a9d7-c317bea43ebb/)
