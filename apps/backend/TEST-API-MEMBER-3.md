# 🧪 Hướng Dẫn Test API Member 3 (Finance & Operations)

## 📋 Tổng quan

Tài liệu này hướng dẫn test **33 API endpoints** do Member 3 phát triển:
- **Wallets**: 4 endpoints (Quản lý ví điện tử)
- **Payments**: 2 endpoints (Thanh toán & webhook)
- **Conversations**: 5 endpoints (Chat/Messaging)
- **Disputes**: 1 endpoint (Khiếu nại)
- **Admin**: 1 endpoint (Giải quyết khiếu nại)

---

## 🚀 Chuẩn bị

### 1. Kiểm tra Backend đang chạy

```powershell
# Trong terminal, kiểm tra backend đang chạy
# Nếu chưa chạy, start bằng lệnh:
cd e:\local-service-platform\apps\backend
pnpm dev
```

✅ Backend chạy tại: `http://localhost:3000`  
✅ Swagger UI: `http://localhost:3000/api`

### 2. Kiểm tra Database

```powershell
# Kiểm tra PostgreSQL đang chạy
docker ps

# Nếu chưa có, start database
docker-compose up -d postgres
```

### 3. Import Postman Collection (Khuyến nghị)

Có 2 collection có sẵn:
- `postman_collection.json` - Full API (58 endpoints Member 1 & 2)
- `Wallets-API.postman_collection.json` - Wallets API (4 endpoints)

**Hoặc** dùng Swagger UI tại `http://localhost:3000/api` để test trực tiếp.

---

## 🔐 Bước 1: Authentication (Lấy Access Token)

### Cách 1: Dùng Postman Collection

1. Mở collection "Local Service Platform API"
2. Chạy request **1.5 Login Customer** hoặc **1.6 Login Provider**
3. Token tự động lưu vào biến `{{CUSTOMER_ACCESS_TOKEN}}`

### Cách 2: Dùng cURL/HTTP Client

**Login Customer:**
```bash
POST http://localhost:3000/auth/login
Content-Type: application/json

{
  "phone": "+84999111222",
  "password": "Customer123!@#"
}
```

**Response:**
```json
{
  "data": {
    "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "user": {
      "id": "1",
      "phone": "+84999111222",
      "fullName": "Nguyen Van Customer"
    }
  }
}
```

✅ **Lưu `accessToken` để dùng cho các request sau**

---

## 💰 Module 1: WALLETS (4 endpoints)

### 1.1. GET /wallets/balance - Xem số dư ví

**Request:**
```http
GET http://localhost:3000/wallets/balance
Authorization: Bearer YOUR_ACCESS_TOKEN
```

**Expected Response (200 OK):**
```json
{
  "data": {
    "balance": "0",
    "currency": "VND",
    "totalTransactions": 0,
    "createdAt": "2025-11-27T09:00:00.000Z"
  },
  "statusCode": 200,
  "message": "Wallet balance retrieved successfully"
}
```

**Test Cases:**
- ✅ User mới đăng ký → balance = 0
- ✅ Wallet tự động tạo khi user register
- ❌ Không có token → 401 Unauthorized

---

### 1.2. GET /wallets/transactions - Lịch sử giao dịch

**Request:**
```http
GET http://localhost:3000/wallets/transactions?page=1&limit=20
Authorization: Bearer YOUR_ACCESS_TOKEN
```

**Expected Response (200 OK):**
```json
{
  "data": {
    "data": [
      {
        "id": "1",
        "type": "deposit",
        "amount": 500000,
        "balanceAfter": 500000,
        "status": "completed",
        "description": "Deposit via momo",
        "createdAt": "2025-11-27T10:00:00.000Z"
      }
    ],
    "pagination": {
      "page": 1,
      "limit": 20,
      "total": 1,
      "totalPages": 1
    }
  }
}
```

**Test Cases:**
- ✅ Chưa có giao dịch → data = []
- ✅ Pagination hoạt động (page, limit)
- ✅ Sắp xếp theo thời gian mới nhất

---

### 1.3. POST /wallets/deposit - Nạp tiền vào ví

**Request:**
```http
POST http://localhost:3000/wallets/deposit
Authorization: Bearer YOUR_ACCESS_TOKEN
Content-Type: application/json

{
  "amount": 500000,
  "gateway": "momo"
}
```

**Expected Response (201 Created):**
```json
{
  "data": {
    "transactionId": "1",
    "paymentId": "1",
    "paymentUrl": "http://localhost:3000/api/v1/payments/checkout/1?gateway=momo&amount=500000",
    "amount": 500000,
    "gateway": "momo",
    "status": "pending",
    "message": "Please complete payment at the provided URL"
  }
}
```

**Test Cases:**

✅ **Valid deposit:**
- Amount >= 100,000 VND
- Gateway: `momo`, `bank_transfer`, `card`

❌ **Invalid amount (< 100k):**
```json
{
  "amount": 50000,
  "gateway": "momo"
}
```
→ Response: `400 Bad Request` - "Minimum deposit is 100,000 VND"

❌ **Invalid gateway:**
```json
{
  "amount": 500000,
  "gateway": "paypal"
}
```
→ Response: `400 Bad Request` - "Gateway must be one of: momo, bank_transfer, card"

**Kiểm tra Database:**
```sql
-- Xem transaction vừa tạo
SELECT * FROM wallet_transactions WHERE wallet_user_id = 1;

-- Xem payment record
SELECT * FROM payments WHERE id = 1;
```

---

### 1.4. POST /wallets/withdraw - Rút tiền từ ví

**Request:**
```http
POST http://localhost:3000/wallets/withdraw
Authorization: Bearer YOUR_ACCESS_TOKEN
Content-Type: application/json

{
  "amount": 200000,
  "bankAccount": "1234567890",
  "bankName": "Vietcombank"
}
```

**Expected Response - Auto Approve (< 1M VND):**
```json
{
  "data": {
    "message": "Withdrawal processed successfully",
    "transactionId": "2",
    "amount": 200000,
    "status": "completed",
    "bankAccount": "1234567890",
    "bankName": "Vietcombank"
  }
}
```

**Expected Response - Need Approval (>= 1M VND):**
```json
{
  "data": {
    "message": "Withdrawal request submitted for approval",
    "transactionId": "3",
    "amount": 5000000,
    "status": "pending",
    "note": "Large withdrawals require admin approval (1-2 business days)"
  }
}
```

**Test Cases:**

✅ **Small amount (< 1M):**
- Auto approve
- Balance trừ ngay
- Status = `completed`

✅ **Large amount (>= 1M):**
- Cần admin approve
- Balance vẫn trừ (tránh double-spending)
- Status = `pending`

❌ **Insufficient balance:**
```json
{
  "amount": 10000000,
  "bankAccount": "1234567890",
  "bankName": "Vietcombank"
}
```
→ Response: `400 Bad Request` - "Insufficient balance. Available: 0 VND"

❌ **Exceed daily limit (> 10M VND/day):**
→ Response: `400 Bad Request` - "Daily withdrawal limit exceeded"

---

## 💳 Module 2: PAYMENTS (2 endpoints)

### 2.1. POST /payments/checkout - Thanh toán booking

**Request:**
```http
POST http://localhost:3000/payments/checkout
Authorization: Bearer YOUR_ACCESS_TOKEN
Content-Type: application/json

{
  "bookingId": 1,
  "paymentMethod": "wallet"
}
```

**Expected Response - Wallet Payment:**
```json
{
  "data": {
    "message": "Payment successful",
    "paymentId": "5",
    "booking": {
      "id": "1",
      "status": "confirmed",
      "paymentStatus": "paid"
    }
  }
}
```

**Expected Response - Gateway Payment (Momo/Stripe):**
```json
{
  "data": {
    "paymentId": "6",
    "paymentUrl": "http://localhost:3000/api/v1/payments/checkout/6?gateway=momo&amount=250000",
    "amount": "250000"
  }
}
```

**Test Cases:**

✅ **Wallet payment:**
- Trừ tiền từ wallet
- Tạo wallet transaction (type = `payment`)
- Update booking.paymentStatus = `paid`

✅ **Gateway payment:**
- Tạo payment record (status = `initiated`)
- Trả về paymentUrl
- Chờ webhook xác nhận

❌ **Booking not found:**
→ `404 Not Found`

❌ **Booking already paid:**
→ `400 Bad Request` - "Booking already paid"

❌ **Insufficient wallet balance:**
→ `400 Bad Request` - "Insufficient wallet balance"

---

### 2.2. POST /payments/webhook/:gateway - Webhook từ payment gateway

**⚠️ Endpoint này KHÔNG cần authentication (dành cho gateway callback)**

**Request:**
```http
POST http://localhost:3000/payments/webhook/momo
Content-Type: application/json
signature: MOCK_SIGNATURE

{
  "orderId": "pending_1732701234567",
  "resultCode": 0,
  "amount": 500000,
  "transactionId": "MOMO_TX_123456"
}
```

**Expected Response (200 OK):**
```json
{
  "message": "Webhook processed"
}
```

**Logic:**
1. Verify signature (skip trong dev mode)
2. Tìm payment record theo `gatewayTxId`
3. Nếu `resultCode = 0` (success):
   - Update payment.status = `succeeded`
   - Nếu là deposit: Cộng tiền vào wallet
   - Nếu là booking: Update booking.paymentStatus = `paid`
   - Tạo notification cho user
4. Nếu failed: Update payment.status = `failed`

**Test Cases:**

✅ **Successful payment:**
- Balance tăng (nếu deposit)
- Booking paid (nếu booking)
- Notification được tạo

✅ **Failed payment:**
- Payment status = `failed`
- Balance không thay đổi

✅ **Idempotency:**
- Gọi webhook 2 lần với cùng transactionId
- Lần 2 trả về "Already processed"

---

## 💬 Module 3: CONVERSATIONS (5 endpoints)

### 3.1. GET /conversations - Danh sách conversations

**Request:**
```http
GET http://localhost:3000/conversations
Authorization: Bearer YOUR_ACCESS_TOKEN
```

**Expected Response:**
```json
{
  "data": [
    {
      "id": "1",
      "bookingId": "1",
      "participants": ["1", "2"],
      "lastMessageAt": "2025-11-27T10:00:00.000Z",
      "unreadCount": 3
    }
  ]
}
```

---

### 3.2. POST /conversations - Tạo conversation mới

**Request:**
```http
POST http://localhost:3000/conversations
Authorization: Bearer YOUR_ACCESS_TOKEN
Content-Type: application/json

{
  "bookingId": 1
}
```

**Expected Response:**
```json
{
  "data": {
    "id": "1",
    "bookingId": "1",
    "participants": ["1", "2"],
    "createdAt": "2025-11-27T10:00:00.000Z"
  }
}
```

**Test Cases:**
- ✅ Tạo conversation cho booking
- ✅ Nếu đã tồn tại → trả về conversation cũ
- ❌ Booking not found → 404
- ❌ User không phải customer/provider của booking → 403

---

### 3.3. GET /conversations/:id/messages - Lấy messages

**Request:**
```http
GET http://localhost:3000/conversations/1/messages
Authorization: Bearer YOUR_ACCESS_TOKEN
```

**Expected Response:**
```json
{
  "data": [
    {
      "id": "1",
      "senderId": "1",
      "content": "Hello, when can you start?",
      "type": "text",
      "createdAt": "2025-11-27T10:00:00.000Z"
    }
  ]
}
```

---

### 3.4. POST /conversations/:id/messages - Gửi message

**Request:**
```http
POST http://localhost:3000/conversations/1/messages
Authorization: Bearer YOUR_ACCESS_TOKEN
Content-Type: application/json

{
  "content": "I can start tomorrow at 9 AM",
  "type": "text"
}
```

**Expected Response:**
```json
{
  "data": {
    "id": "2",
    "conversationId": "1",
    "senderId": "2",
    "content": "I can start tomorrow at 9 AM",
    "type": "text",
    "createdAt": "2025-11-27T10:05:00.000Z"
  }
}
```

**Test Cases:**
- ✅ Gửi text message
- ✅ Gửi image (với attachmentUrl)
- ✅ Update conversation.lastMessageAt
- ✅ Tạo notification cho người nhận
- ❌ Không phải participant → 403

---

### 3.5. PATCH /conversations/:id/read - Đánh dấu đã đọc

**Request:**
```http
PATCH http://localhost:3000/conversations/1/read
Authorization: Bearer YOUR_ACCESS_TOKEN
```

**Expected Response:**
```json
{
  "data": {
    "message": "Conversation marked as read",
    "unreadCount": 0
  }
}
```

---

## ⚖️ Module 4: DISPUTES (1 endpoint)

### 4.1. POST /disputes - Tạo khiếu nại

**Request:**
```http
POST http://localhost:3000/disputes
Authorization: Bearer YOUR_ACCESS_TOKEN
Content-Type: application/json

{
  "bookingId": 1,
  "reason": "poor_quality",
  "description": "The service was not completed as promised",
  "evidence": [
    "https://example.com/photo1.jpg",
    "https://example.com/photo2.jpg"
  ]
}
```

**Expected Response:**
```json
{
  "data": {
    "id": "1",
    "bookingId": "1",
    "raisedBy": "1",
    "reason": "poor_quality",
    "status": "open",
    "createdAt": "2025-11-27T10:00:00.000Z"
  }
}
```

**Test Cases:**
- ✅ Chỉ customer mới tạo được dispute
- ✅ Chỉ dispute được booking đã completed
- ❌ Booking chưa completed → 400
- ❌ Đã có dispute cho booking này → 400

---

## 👨‍💼 Module 5: ADMIN (1 endpoint)

### 5.1. POST /admin/disputes/:id/resolve - Giải quyết khiếu nại

**⚠️ Cần role `admin` hoặc `super_admin`**

**Request:**
```http
POST http://localhost:3000/admin/disputes/1/resolve
Authorization: Bearer ADMIN_ACCESS_TOKEN
Content-Type: application/json

{
  "resolution": "customer_favor",
  "refundAmount": 250000,
  "notes": "Service was not completed. Full refund approved."
}
```

**Expected Response:**
```json
{
  "data": {
    "message": "Dispute resolved successfully",
    "dispute": {
      "id": "1",
      "status": "resolved",
      "resolution": "customer_favor",
      "resolvedAt": "2025-11-27T11:00:00.000Z"
    }
  }
}
```

**Test Cases:**

✅ **Customer favor (có refund):**
- Update dispute.status = `resolved`
- Tạo wallet transaction (type = `refund`)
- Cộng tiền vào wallet customer
- Tạo audit log

✅ **Provider favor (không refund):**
- Chỉ update dispute status
- Không hoàn tiền

❌ **Không có role admin:**
→ `403 Forbidden`

---

## 📊 Test Flow Hoàn Chỉnh

### Scenario: Customer đặt dịch vụ, thanh toán, chat, và dispute

```
1. [Customer] Login → Lấy token
2. [Customer] GET /wallets/balance → Check balance = 0
3. [Customer] POST /wallets/deposit (500k) → Nhận paymentUrl
4. [System] POST /payments/webhook/momo → Xác nhận deposit thành công
5. [Customer] GET /wallets/balance → Balance = 500k
6. [Customer] POST /bookings → Tạo booking (250k)
7. [Customer] POST /payments/checkout → Thanh toán bằng wallet
8. [Customer] GET /wallets/balance → Balance = 250k
9. [Customer] POST /conversations → Tạo chat với provider
10. [Customer] POST /conversations/1/messages → Gửi tin nhắn
11. [Provider] GET /conversations/1/messages → Đọc tin nhắn
12. [Provider] POST /conversations/1/messages → Trả lời
13. [Provider] PATCH /provider/bookings/1/complete → Hoàn thành
14. [Customer] POST /disputes → Tạo khiếu nại (nếu không hài lòng)
15. [Admin] POST /admin/disputes/1/resolve → Giải quyết
16. [Customer] GET /wallets/balance → Nhận refund (nếu có)
```

---

## 🔍 Kiểm tra Database

```sql
-- 1. Xem wallets
SELECT user_id, balance, currency, created_at 
FROM wallets 
ORDER BY created_at DESC;

-- 2. Xem wallet transactions
SELECT 
    id, 
    wallet_user_id, 
    type, 
    amount, 
    balance_after, 
    status, 
    description,
    created_at 
FROM wallet_transactions 
ORDER BY created_at DESC;

-- 3. Xem payments
SELECT 
    id, 
    booking_id,
    amount, 
    method, 
    gateway, 
    gateway_tx_id, 
    status, 
    created_at 
FROM payments 
ORDER BY created_at DESC;

-- 4. Xem conversations
SELECT 
    id, 
    booking_id, 
    participants, 
    last_message_at, 
    unread_count 
FROM conversations;

-- 5. Xem messages
SELECT 
    id, 
    conversation_id, 
    sender_id, 
    content, 
    type, 
    created_at 
FROM messages 
ORDER BY created_at DESC;

-- 6. Xem disputes
SELECT 
    id, 
    booking_id, 
    raised_by, 
    reason, 
    status, 
    resolution, 
    resolved_at 
FROM disputes;

-- 7. Join để xem full picture
SELECT 
    wt.id as tx_id,
    wt.type,
    wt.amount,
    wt.status as tx_status,
    p.gateway,
    p.status as payment_status,
    wt.created_at
FROM wallet_transactions wt
LEFT JOIN payments p ON p.payload->>'transactionId' = wt.id::text
ORDER BY wt.created_at DESC;
```

---

## 🐛 Troubleshooting

### Lỗi 401 Unauthorized
- Token hết hạn → Login lại
- Token không đúng → Check header `Authorization: Bearer TOKEN`

### Lỗi 403 Forbidden
- Không có quyền truy cập (ví dụ: không phải admin)
- Không phải participant của conversation

### Lỗi 404 Not Found
- Resource không tồn tại (booking, conversation, etc.)
- ID sai

### Lỗi 500 Internal Server Error
- Database chưa chạy → `docker ps`
- Migrations chưa run → `pnpm prisma:migrate`
- Check logs trong terminal backend

---

## ✅ Checklist Test Cases

### Wallets (4 endpoints)
- [ ] GET /wallets/balance - Xem số dư
- [ ] GET /wallets/transactions - Lịch sử giao dịch
- [ ] POST /wallets/deposit - Nạp tiền (valid)
- [ ] POST /wallets/deposit - Validation errors (< 100k, invalid gateway)
- [ ] POST /wallets/withdraw - Rút tiền < 1M (auto approve)
- [ ] POST /wallets/withdraw - Rút tiền >= 1M (need approval)
- [ ] POST /wallets/withdraw - Insufficient balance
- [ ] POST /wallets/withdraw - Daily limit exceeded

### Payments (2 endpoints)
- [ ] POST /payments/checkout - Wallet payment
- [ ] POST /payments/checkout - Gateway payment
- [ ] POST /payments/checkout - Booking not found
- [ ] POST /payments/checkout - Already paid
- [ ] POST /payments/webhook/momo - Success
- [ ] POST /payments/webhook/momo - Failed
- [ ] POST /payments/webhook/momo - Idempotency

### Conversations (5 endpoints)
- [ ] GET /conversations - List conversations
- [ ] POST /conversations - Create new
- [ ] POST /conversations - Already exists
- [ ] GET /conversations/:id/messages - Get messages
- [ ] POST /conversations/:id/messages - Send text
- [ ] POST /conversations/:id/messages - Send image
- [ ] PATCH /conversations/:id/read - Mark as read

### Disputes (1 endpoint)
- [ ] POST /disputes - Create dispute
- [ ] POST /disputes - Booking not completed
- [ ] POST /disputes - Already disputed

### Admin (1 endpoint)
- [ ] POST /admin/disputes/:id/resolve - Customer favor
- [ ] POST /admin/disputes/:id/resolve - Provider favor
- [ ] POST /admin/disputes/:id/resolve - No admin role

---

## 📝 Notes

1. **Mock Data**: Sử dụng file `create_mock_data.sql` để tạo dữ liệu test
2. **Swagger UI**: Truy cập `http://localhost:3000/api` để test trực tiếp
3. **Postman**: Import `postman_collection.json` để có sẵn tất cả requests
4. **Logs**: Check terminal backend để xem logs chi tiết

**Happy Testing! 🎉**
