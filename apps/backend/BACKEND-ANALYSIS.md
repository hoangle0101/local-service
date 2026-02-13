# 📊 Phân Tích Backend - Local Service Platform

## 🏗️ Tổng quan Kiến trúc

### Tech Stack
- **Framework**: NestJS 10.x
- **Database**: PostgreSQL 15+ (with PostGIS)
- **ORM**: Prisma 5.x
- **Authentication**: JWT (passport-jwt)
- **Validation**: class-validator, class-transformer
- **Documentation**: Swagger/OpenAPI

### Cấu trúc Thư mục

```
apps/backend/
├── src/
│   ├── modules/           # Feature modules (12 modules)
│   │   ├── auth/         # Authentication & Authorization
│   │   ├── users/        # User management
│   │   ├── provider/     # Provider profiles
│   │   ├── services/     # Service catalog
│   │   ├── bookings/     # Booking management
│   │   ├── payments/     # Payment processing ⭐
│   │   ├── wallets/      # Wallet & transactions ⭐
│   │   ├── conversations/# Chat & messaging ⭐
│   │   ├── disputes/     # Dispute resolution ⭐
│   │   ├── admin/        # Admin operations ⭐
│   │   ├── marketplace/  # Marketplace features
│   │   └── system/       # System utilities
│   ├── common/           # Shared code
│   │   ├── decorators/   # @CurrentUser, @Roles
│   │   ├── filters/      # Exception filters
│   │   ├── guards/       # JWT, Roles guards
│   │   └── interceptors/ # Response transform
│   ├── config/           # Configuration
│   └── prisma/           # Prisma client
├── prisma/
│   ├── schema.prisma     # Database schema
│   └── migrations/       # Database migrations
└── test/                 # Tests
```

⭐ = Modules do Member 3 phát triển

---

## 📦 Phân tích các Module (Member 3)

### 1. 💰 Wallets Module (4 endpoints)

**Chức năng**: Quản lý ví điện tử của user

**Files:**
- `wallets.controller.ts` - 4 endpoints
- `wallets.service.ts` - Business logic
- `dto/wallet.dto.ts` - DepositDto, WithdrawDto

**Endpoints:**

| Method | Path | Chức năng | Auth |
|--------|------|-----------|------|
| GET | `/wallets/balance` | Xem số dư ví | ✅ |
| GET | `/wallets/transactions` | Lịch sử giao dịch | ✅ |
| POST | `/wallets/deposit` | Nạp tiền vào ví | ✅ |
| POST | `/wallets/withdraw` | Rút tiền từ ví | ✅ |

**Business Logic:**

1. **Get Balance**:
   - Lấy thông tin wallet từ DB
   - Trả về balance, currency, totalTransactions

2. **Get Transactions**:
   - Pagination (page, limit)
   - Sắp xếp theo thời gian mới nhất
   - Trả về list transactions + metadata

3. **Deposit**:
   - Validate amount (min 100k VND)
   - Validate gateway (momo, bank_transfer, card)
   - Tạo wallet transaction (status = `pending`)
   - Tạo payment record (status = `initiated`)
   - Trả về payment URL (mock)
   - **Chờ webhook xác nhận** để cộng tiền vào wallet

4. **Withdraw**:
   - Check balance đủ không
   - Check daily limit (max 10M VND/day)
   - **Auto-approve nếu < 1M VND**:
     - Trừ balance ngay
     - Tạo transaction (status = `completed`)
     - Tạo payment record (status = `succeeded`)
   - **Need approval nếu >= 1M VND**:
     - Trừ balance ngay (tránh double-spending)
     - Tạo transaction (status = `pending`)
     - Admin sẽ approve/reject sau

**Database Tables:**
- `wallets` - Thông tin ví (userId, balance, currency)
- `wallet_transactions` - Lịch sử giao dịch (type, amount, status, balanceAfter)

---

### 2. 💳 Payments Module (2 endpoints)

**Chức năng**: Xử lý thanh toán cho booking và deposit

**Files:**
- `payments.controller.ts` - 2 endpoints
- `payments.service.ts` - Business logic
- `dto/payment.dto.ts` - CheckoutDto, WebhookDto

**Endpoints:**

| Method | Path | Chức năng | Auth |
|--------|------|-----------|------|
| POST | `/payments/checkout` | Thanh toán booking | ✅ |
| POST | `/payments/webhook/:gateway` | Webhook từ gateway | ❌ |

**Business Logic:**

1. **Checkout**:
   - Validate booking tồn tại và chưa paid
   - **Wallet payment**:
     - Check balance đủ không
     - Trừ tiền từ wallet
     - Tạo wallet transaction (type = `payment`)
     - Tạo payment record (status = `succeeded`)
     - Update booking.paymentStatus = `paid`
   - **Gateway payment** (Momo/Stripe):
     - Tạo payment record (status = `initiated`)
     - Generate payment URL (mock)
     - Trả về URL cho user thanh toán
     - Chờ webhook xác nhận

2. **Webhook** (CRITICAL!):
   - **Verify signature** (skip trong dev)
   - Parse webhook data (gateway-specific)
   - Tìm payment record theo `gatewayTxId`
   - **Idempotency check**: Nếu đã processed → return
   - **Success**:
     - Update payment.status = `succeeded`
     - Nếu deposit: Cộng tiền vào wallet
     - Nếu booking: Update booking.paymentStatus = `paid`
     - Tạo notification cho user
   - **Failed**:
     - Update payment.status = `failed`
     - Tạo notification
   - Tạo audit log

**Database Tables:**
- `payments` - Payment records (bookingId, amount, method, gateway, status)

**⚠️ Important Notes:**
- Webhook không cần authentication (public endpoint)
- Phải verify signature trong production
- Phải handle idempotency (tránh double processing)

---

### 3. 💬 Conversations Module (5 endpoints)

**Chức năng**: Chat/messaging giữa customer và provider

**Files:**
- `conversations.controller.ts` - 5 endpoints
- `conversations.service.ts` - Business logic
- `dto/conversation.dto.ts` - CreateConversationDto, SendMessageDto

**Endpoints:**

| Method | Path | Chức năng | Auth |
|--------|------|-----------|------|
| GET | `/conversations` | List conversations | ✅ |
| POST | `/conversations` | Tạo conversation | ✅ |
| GET | `/conversations/:id/messages` | Lấy messages | ✅ |
| POST | `/conversations/:id/messages` | Gửi message | ✅ |
| PATCH | `/conversations/:id/read` | Đánh dấu đã đọc | ✅ |

**Business Logic:**

1. **Create Conversation**:
   - Validate booking tồn tại
   - Verify user là customer hoặc provider của booking
   - Check conversation đã tồn tại chưa → return nếu có
   - Tạo conversation mới với participants = [customerId, providerId]

2. **Send Message**:
   - Verify user là participant
   - Tạo message record
   - Update conversation.lastMessageAt
   - Increment conversation.unreadCount
   - Tạo notification cho người nhận

3. **Mark as Read**:
   - Reset conversation.unreadCount = 0

**Database Tables:**
- `conversations` - Conversations (bookingId, participants, lastMessageAt, unreadCount)
- `messages` - Messages (conversationId, senderId, content, type, attachmentUrl)

**Features:**
- Support text, image, file messages
- Real-time notification (via FCM)
- Unread count tracking

---

### 4. ⚖️ Disputes Module (1 endpoint)

**Chức năng**: Khiếu nại về dịch vụ

**Files:**
- `disputes.controller.ts` - 1 endpoint
- `disputes.service.ts` - Business logic
- `dto/dispute.dto.ts` - CreateDisputeDto

**Endpoints:**

| Method | Path | Chức năng | Auth |
|--------|------|-----------|------|
| POST | `/disputes` | Tạo khiếu nại | ✅ |

**Business Logic:**

1. **Create Dispute**:
   - Validate booking tồn tại và thuộc về customer
   - Check booking.status = `completed` (chỉ dispute được booking đã hoàn thành)
   - Check chưa có dispute cho booking này
   - Tạo dispute record (status = `open`)
   - Lưu evidence (photos, videos)

**Database Tables:**
- `disputes` - Disputes (bookingId, raisedBy, reason, status, evidence, resolution)

**Dispute Reasons:**
- `poor_quality` - Chất lượng kém
- `not_completed` - Không hoàn thành
- `wrong_service` - Sai dịch vụ
- `other` - Khác

---

### 5. 👨‍💼 Admin Module (1 endpoint - Member 3)

**Chức năng**: Quản trị hệ thống

**Files:**
- `admin.controller.ts` - 1 endpoint (Member 3)
- `admin.service.ts` - Business logic
- `dto/admin.dto.ts` - ResolveDisputeDto

**Endpoints:**

| Method | Path | Chức năng | Auth | Role |
|--------|------|-----------|------|------|
| POST | `/admin/disputes/:id/resolve` | Giải quyết khiếu nại | ✅ | admin |

**Business Logic:**

1. **Resolve Dispute**:
   - Validate dispute tồn tại
   - Update dispute (status = `resolved`, resolution, resolvedBy, resolvedAt)
   - **Nếu customer_favor**:
     - Tạo wallet transaction (type = `refund`)
     - Cộng tiền vào wallet customer
   - **Nếu provider_favor**:
     - Không hoàn tiền
   - Tạo audit log
   - Tạo notification cho cả 2 bên

**Database Tables:**
- `disputes` - Update status và resolution
- `wallet_transactions` - Refund transaction
- `audit_logs` - Log admin action

**⚠️ RBAC:**
- Chỉ user có role `admin` hoặc `super_admin` mới access được
- Sử dụng `@Roles('admin', 'super_admin')` decorator
- `RolesGuard` check role từ DB

---

## 🔐 Authentication & Authorization

### JWT Authentication

**Flow:**
1. User login → Nhận `accessToken` và `refreshToken`
2. Mỗi request gửi `Authorization: Bearer {accessToken}`
3. `JwtAuthGuard` verify token
4. Extract user info → `@CurrentUser()` decorator

**Token Payload:**
```typescript
interface JwtPayload {
  userId: string;
  phone: string;
  sub: string;
}
```

### Role-Based Access Control (RBAC)

**Roles:**
- `customer` - Người dùng thông thường
- `provider` - Nhà cung cấp dịch vụ
- `admin` - Quản trị viên
- `super_admin` - Quản trị viên cấp cao

**Implementation:**
```typescript
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('admin', 'super_admin')
async resolveDispute() { ... }
```

**RolesGuard:**
- Query `user_roles` table
- Check user có role yêu cầu không
- Return true/false

---

## 🗄️ Database Schema (Member 3 Tables)

### Wallets
```prisma
model Wallet {
  userId    BigInt   @id @map("user_id")
  balance   Decimal  @default(0) @db.Decimal(15, 2)
  currency  String   @default("VND") @db.VarChar(3)
  createdAt DateTime @default(now()) @map("created_at")
  updatedAt DateTime @updatedAt @map("updated_at")

  user         User               @relation(fields: [userId], references: [id])
  transactions WalletTransaction[]
}
```

### WalletTransaction
```prisma
model WalletTransaction {
  id           BigInt   @id @default(autoincrement())
  walletId     BigInt   @map("wallet_user_id")
  type         String   @db.VarChar(20) // deposit, withdraw, payment, refund
  amount       Decimal  @db.Decimal(15, 2)
  balanceAfter Decimal  @map("balance_after") @db.Decimal(15, 2)
  status       String   @db.VarChar(20) // pending, completed, failed
  description  String?  @db.Text
  metadata     Json     @default("{}")
  createdAt    DateTime @default(now()) @map("created_at")

  wallet Wallet @relation(fields: [walletId], references: [userId])
}
```

### Payment
```prisma
model Payment {
  id          BigInt    @id @default(autoincrement())
  bookingId   BigInt?   @map("booking_id")
  amount      Decimal   @db.Decimal(15, 2)
  currency    String    @default("VND") @db.VarChar(3)
  method      String    @db.VarChar(20) // wallet, momo, card, bank_transfer
  gateway     String    @db.VarChar(50)
  gatewayTxId String    @map("gateway_tx_id") @db.VarChar(255)
  status      String    @db.VarChar(20) // initiated, succeeded, failed
  payload     Json      @default("{}")
  createdAt   DateTime  @default(now()) @map("created_at")

  booking Booking? @relation(fields: [bookingId], references: [id])
}
```

### Conversation
```prisma
model Conversation {
  id            BigInt   @id @default(autoincrement())
  bookingId     BigInt   @unique @map("booking_id")
  participants  Json     // [userId1, userId2]
  lastMessageAt DateTime @map("last_message_at")
  unreadCount   Int      @default(0) @map("unread_count")
  createdAt     DateTime @default(now()) @map("created_at")

  booking  Booking   @relation(fields: [bookingId], references: [id])
  messages Message[]
}
```

### Message
```prisma
model Message {
  id             BigInt   @id @default(autoincrement())
  conversationId BigInt   @map("conversation_id")
  senderId       BigInt   @map("sender_id")
  content        String   @db.Text
  type           String   @default("text") @db.VarChar(20) // text, image, file
  attachmentUrl  String?  @map("attachment_url") @db.Text
  createdAt      DateTime @default(now()) @map("created_at")

  conversation Conversation @relation(fields: [conversationId], references: [id])
  sender       User         @relation(fields: [senderId], references: [id])
}
```

### Dispute
```prisma
model Dispute {
  id          BigInt    @id @default(autoincrement())
  bookingId   BigInt    @unique @map("booking_id")
  raisedBy    BigInt    @map("raised_by")
  reason      String    @db.VarChar(50)
  description String    @db.Text
  status      String    @db.VarChar(20) // open, resolved, rejected
  evidence    Json      @default("[]") // [url1, url2, ...]
  resolution  String?   @db.Text
  resolvedBy  BigInt?   @map("resolved_by")
  resolvedAt  DateTime? @map("resolved_at")
  adminNotes  String?   @map("admin_notes") @db.Text
  createdAt   DateTime  @default(now()) @map("created_at")

  booking    Booking @relation(fields: [bookingId], references: [id])
  customer   User    @relation("DisputeRaisedBy", fields: [raisedBy], references: [id])
  admin      User?   @relation("DisputeResolvedBy", fields: [resolvedBy], references: [id])
}
```

---

## 🔄 Data Flow Examples

### 1. Deposit Flow

```
User Request
    ↓
POST /wallets/deposit
    ↓
WalletsService.deposit()
    ├─ Create WalletTransaction (status: pending)
    ├─ Create Payment (status: initiated)
    └─ Return paymentUrl
    ↓
User thanh toán tại gateway
    ↓
Gateway gọi webhook
    ↓
POST /payments/webhook/momo
    ↓
PaymentsService.handleWebhook()
    ├─ Verify signature
    ├─ Find Payment by gatewayTxId
    ├─ Update Payment (status: succeeded)
    ├─ Update WalletTransaction (status: completed)
    ├─ Update Wallet (balance += amount)
    └─ Create Notification
```

### 2. Booking Payment Flow

```
User Request
    ↓
POST /payments/checkout
    ↓
PaymentsService.checkout()
    ├─ Find Booking
    ├─ Check paymentStatus != paid
    └─ If wallet payment:
        ├─ Check wallet balance
        ├─ Deduct from wallet
        ├─ Create WalletTransaction (type: payment)
        ├─ Create Payment (status: succeeded)
        └─ Update Booking (paymentStatus: paid)
    └─ If gateway payment:
        ├─ Create Payment (status: initiated)
        └─ Return paymentUrl
```

### 3. Dispute Resolution Flow

```
Admin Request
    ↓
POST /admin/disputes/:id/resolve
    ↓
AdminService.resolveDispute()
    ├─ Find Dispute
    ├─ Update Dispute (status: resolved)
    └─ If customer_favor:
        ├─ Create WalletTransaction (type: refund)
        ├─ Update Wallet (balance += refundAmount)
        └─ Create Notification
    └─ Create AuditLog
```

---

## 🧪 Testing

### Test Files
- `TEST-API-MEMBER-3.md` - Hướng dẫn test chi tiết
- `TEST-WALLETS-POSTMAN.md` - Test wallets với Postman
- `postman_collection.json` - Postman collection (58 endpoints)
- `Wallets-API.postman_collection.json` - Wallets collection

### Test Tools
1. **Postman** - Import collection và test
2. **Swagger UI** - `http://localhost:3000/api`
3. **cURL** - Command line testing
4. **Database Client** - Kiểm tra data trực tiếp

### Mock Data
- `create_mock_data.sql` - Script tạo dữ liệu test

---

## 📈 Performance Considerations

### Database Optimization
1. **Indexes**:
   - `wallet_transactions.wallet_user_id` - Tăng tốc query transactions
   - `payments.gateway_tx_id` - Tăng tốc webhook lookup
   - `conversations.booking_id` - Unique index
   - `messages.conversation_id` - Tăng tốc query messages

2. **Pagination**:
   - Tất cả list endpoints đều có pagination
   - Default limit = 20

3. **Transactions**:
   - Sử dụng `prisma.$transaction()` cho operations phức tạp
   - Đảm bảo ACID properties

### Security
1. **JWT Expiration**:
   - Access token: 15 minutes
   - Refresh token: 7 days

2. **Webhook Signature**:
   - Verify trong production
   - Skip trong development

3. **Rate Limiting**:
   - TODO: Implement rate limiting cho deposit/withdraw

---

## 🚀 Deployment Checklist

### Environment Variables
```env
# Database
DATABASE_URL=postgresql://user:password@localhost:5432/dbname

# JWT
JWT_SECRET=your-secret-key
JWT_REFRESH_SECRET=your-refresh-secret
JWT_EXPIRES_IN=15m
JWT_REFRESH_EXPIRES_IN=7d

# Payment Gateways
MOMO_WEBHOOK_SECRET=xxx
STRIPE_WEBHOOK_SECRET=xxx

# App
APP_URL=https://your-domain.com
NODE_ENV=production
```

### Production Checklist
- [ ] Set strong JWT secrets
- [ ] Enable webhook signature verification
- [ ] Configure real payment gateway credentials
- [ ] Set up database backups
- [ ] Configure logging (Winston, Sentry)
- [ ] Set up monitoring (Prometheus, Grafana)
- [ ] Enable CORS properly
- [ ] Set up rate limiting
- [ ] Configure file upload limits
- [ ] Set up SSL/TLS

---

## 📚 API Documentation

### Swagger UI
- URL: `http://localhost:3000/api`
- Auto-generated từ decorators
- Interactive testing

### Postman Collection
- `postman_collection.json` - 58 endpoints
- Auto-save tokens
- Pre-request scripts
- Test scripts

---

## 🎯 Kết luận

### Điểm mạnh
✅ Kiến trúc rõ ràng, module hóa tốt  
✅ Validation đầy đủ với class-validator  
✅ Error handling chuẩn với GlobalExceptionFilter  
✅ Response format thống nhất với TransformInterceptor  
✅ Authentication & Authorization đầy đủ  
✅ Database schema được thiết kế tốt  
✅ Business logic phức tạp được xử lý đúng (transactions, webhooks)  

### Cần cải thiện
⚠️ Chưa có unit tests  
⚠️ Chưa có integration tests  
⚠️ Chưa implement rate limiting  
⚠️ Chưa có logging system (Winston)  
⚠️ Chưa có monitoring (Prometheus)  
⚠️ Payment gateway chỉ mock, chưa integrate thật  
⚠️ Chưa có email/SMS notifications  

### Roadmap
1. **Phase 1** (Current): Core features ✅
2. **Phase 2**: Testing & Quality
   - Unit tests
   - Integration tests
   - E2E tests
3. **Phase 3**: Production Ready
   - Real payment gateway integration
   - Email/SMS notifications
   - Monitoring & logging
   - Rate limiting
4. **Phase 4**: Advanced Features
   - Real-time chat (WebSocket)
   - Push notifications (FCM)
   - Analytics dashboard
   - Mobile app APIs

---

**Tài liệu này được tạo tự động bởi AI Assistant**  
**Last Updated**: 2025-11-27
