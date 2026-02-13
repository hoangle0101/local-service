# 🚀 Quick API Test Reference - Member 3

## 📍 Base URL
```
http://localhost:3000
```

## 🔑 Authentication

### Login để lấy token
```bash
POST /auth/login
Content-Type: application/json

{
  "phone": "+84999111222",
  "password": "Customer123!@#"
}
```

**Lưu `accessToken` từ response để dùng cho các request sau**

---

## 💰 WALLETS API

### 1. Xem số dư
```bash
GET /wallets/balance
Authorization: Bearer YOUR_TOKEN
```

### 2. Lịch sử giao dịch
```bash
GET /wallets/transactions?page=1&limit=20
Authorization: Bearer YOUR_TOKEN
```

### 3. Nạp tiền (Deposit)
```bash
POST /wallets/deposit
Authorization: Bearer YOUR_TOKEN
Content-Type: application/json

{
  "amount": 500000,
  "gateway": "momo"
}
```

**Gateways**: `momo`, `bank_transfer`, `card`  
**Min amount**: 100,000 VND

### 4. Rút tiền (Withdraw)
```bash
POST /wallets/withdraw
Authorization: Bearer YOUR_TOKEN
Content-Type: application/json

{
  "amount": 200000,
  "bankAccount": "1234567890",
  "bankName": "Vietcombank"
}
```

**Logic**:
- < 1M VND → Auto approve
- >= 1M VND → Cần admin approve
- Max 10M VND/day

---

## 💳 PAYMENTS API

### 1. Thanh toán booking
```bash
POST /payments/checkout
Authorization: Bearer YOUR_TOKEN
Content-Type: application/json

{
  "bookingId": 1,
  "paymentMethod": "wallet"
}
```

**Payment Methods**: `wallet`, `momo`, `stripe`

### 2. Webhook (Mock)
```bash
POST /payments/webhook/momo
Content-Type: application/json

{
  "orderId": "pending_1732701234567",
  "resultCode": 0,
  "amount": 500000
}
```

**Note**: Endpoint này KHÔNG cần authentication

---

## 💬 CONVERSATIONS API

### 1. List conversations
```bash
GET /conversations
Authorization: Bearer YOUR_TOKEN
```

### 2. Tạo conversation
```bash
POST /conversations
Authorization: Bearer YOUR_TOKEN
Content-Type: application/json

{
  "bookingId": 1
}
```

### 3. Lấy messages
```bash
GET /conversations/1/messages
Authorization: Bearer YOUR_TOKEN
```

### 4. Gửi message
```bash
POST /conversations/1/messages
Authorization: Bearer YOUR_TOKEN
Content-Type: application/json

{
  "content": "Hello, when can you start?",
  "type": "text"
}
```

**Message Types**: `text`, `image`, `file`

### 5. Đánh dấu đã đọc
```bash
PATCH /conversations/1/read
Authorization: Bearer YOUR_TOKEN
```

---

## ⚖️ DISPUTES API

### Tạo khiếu nại
```bash
POST /disputes
Authorization: Bearer YOUR_TOKEN
Content-Type: application/json

{
  "bookingId": 1,
  "reason": "poor_quality",
  "description": "Service was not completed as promised",
  "evidence": [
    "https://example.com/photo1.jpg"
  ]
}
```

**Reasons**: `poor_quality`, `not_completed`, `wrong_service`, `other`

---

## 👨‍💼 ADMIN API

### Giải quyết khiếu nại
```bash
POST /admin/disputes/1/resolve
Authorization: Bearer ADMIN_TOKEN
Content-Type: application/json

{
  "resolution": "customer_favor",
  "refundAmount": 250000,
  "notes": "Full refund approved"
}
```

**Resolutions**: `customer_favor`, `provider_favor`

**⚠️ Cần role `admin` hoặc `super_admin`**

---

## 🧪 Test Flow Nhanh

### Scenario 1: Deposit và Check Balance
```bash
# 1. Login
POST /auth/login
→ Lưu accessToken

# 2. Check balance ban đầu
GET /wallets/balance
→ Balance = 0

# 3. Deposit 500k
POST /wallets/deposit
{
  "amount": 500000,
  "gateway": "momo"
}
→ Nhận paymentUrl

# 4. Mock webhook success
POST /payments/webhook/momo
{
  "orderId": "pending_xxx",
  "resultCode": 0,
  "amount": 500000
}

# 5. Check balance sau deposit
GET /wallets/balance
→ Balance = 500,000

# 6. Xem lịch sử giao dịch
GET /wallets/transactions
→ Có 1 transaction type=deposit
```

### Scenario 2: Thanh toán Booking
```bash
# 1. Tạo booking (Member 2 API)
POST /bookings
→ bookingId = 1

# 2. Thanh toán bằng wallet
POST /payments/checkout
{
  "bookingId": 1,
  "paymentMethod": "wallet"
}

# 3. Check balance giảm
GET /wallets/balance

# 4. Check transaction history
GET /wallets/transactions
→ Có transaction type=payment
```

### Scenario 3: Chat với Provider
```bash
# 1. Tạo conversation
POST /conversations
{
  "bookingId": 1
}
→ conversationId = 1

# 2. Gửi message
POST /conversations/1/messages
{
  "content": "Hello!",
  "type": "text"
}

# 3. Xem messages
GET /conversations/1/messages

# 4. Đánh dấu đã đọc
PATCH /conversations/1/read
```

### Scenario 4: Dispute
```bash
# 1. Tạo dispute
POST /disputes
{
  "bookingId": 1,
  "reason": "poor_quality",
  "description": "Not satisfied"
}
→ disputeId = 1

# 2. Admin giải quyết
POST /admin/disputes/1/resolve
{
  "resolution": "customer_favor",
  "refundAmount": 250000
}

# 3. Check balance tăng (refund)
GET /wallets/balance
```

---

## 🔍 Kiểm tra Database

```sql
-- Wallets
SELECT * FROM wallets WHERE user_id = 1;

-- Transactions
SELECT * FROM wallet_transactions 
WHERE wallet_user_id = 1 
ORDER BY created_at DESC;

-- Payments
SELECT * FROM payments 
ORDER BY created_at DESC;

-- Conversations
SELECT * FROM conversations WHERE booking_id = 1;

-- Messages
SELECT * FROM messages 
WHERE conversation_id = 1 
ORDER BY created_at DESC;

-- Disputes
SELECT * FROM disputes WHERE booking_id = 1;
```

---

## ❌ Common Errors

### 401 Unauthorized
→ Token hết hạn hoặc không đúng  
→ Login lại để lấy token mới

### 403 Forbidden
→ Không có quyền truy cập  
→ Check role (admin endpoints)

### 400 Bad Request
→ Validation error  
→ Check request body format

### 404 Not Found
→ Resource không tồn tại  
→ Check ID

### 500 Internal Server Error
→ Server error  
→ Check logs trong terminal backend

---

## 📝 Notes

- **Swagger UI**: `http://localhost:3000/api` - Test trực tiếp
- **Postman**: Import `postman_collection.json`
- **Mock Data**: Chạy `create_mock_data.sql`
- **Logs**: Check terminal backend để debug

---

## 🎯 Checklist Test Nhanh

- [ ] Login thành công
- [ ] Xem balance = 0
- [ ] Deposit 500k
- [ ] Mock webhook success
- [ ] Balance = 500k
- [ ] Withdraw 200k (auto approve)
- [ ] Balance = 300k
- [ ] Thanh toán booking bằng wallet
- [ ] Tạo conversation
- [ ] Gửi message
- [ ] Tạo dispute
- [ ] Admin resolve dispute
- [ ] Check refund vào wallet

**Happy Testing! 🎉**
