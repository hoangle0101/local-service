# 🗺️ API Architecture Map - Member 3

```
┌─────────────────────────────────────────────────────────────────────┐
│                    LOCAL SERVICE PLATFORM                           │
│                         Backend API                                 │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                         MEMBER 3 MODULES                            │
│                        (13 Endpoints Total)                         │
└─────────────────────────────────────────────────────────────────────┘

┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐
│   💰 WALLETS     │  │  💳 PAYMENTS     │  │ 💬 CONVERSATIONS │
│   (4 endpoints)  │  │  (2 endpoints)   │  │  (5 endpoints)   │
├──────────────────┤  ├──────────────────┤  ├──────────────────┤
│ GET  /balance    │  │ POST /checkout   │  │ GET  /           │
│ GET  /txs        │  │ POST /webhook    │  │ POST /           │
│ POST /deposit    │  └──────────────────┘  │ GET  /:id/msgs   │
│ POST /withdraw   │                        │ POST /:id/msgs   │
└──────────────────┘                        │ PATCH /:id/read  │
                                            └──────────────────┘

┌──────────────────┐  ┌──────────────────┐
│  ⚖️ DISPUTES     │  │  👨‍💼 ADMIN       │
│  (1 endpoint)    │  │  (1 endpoint)    │
├──────────────────┤  ├──────────────────┤
│ POST /disputes   │  │ POST /resolve    │
└──────────────────┘  └──────────────────┘


┌─────────────────────────────────────────────────────────────────────┐
│                          DATA FLOW                                  │
└─────────────────────────────────────────────────────────────────────┘

DEPOSIT FLOW:
User → POST /wallets/deposit → Create Transaction (pending)
                             → Create Payment (initiated)
                             → Return paymentUrl
User → Pay at Gateway
Gateway → POST /webhook → Verify Signature
                       → Update Payment (succeeded)
                       → Update Transaction (completed)
                       → Update Wallet (balance += amount)
                       → Create Notification

PAYMENT FLOW:
User → POST /payments/checkout → Check Booking
                               → If wallet: Deduct balance
                                          → Create Transaction
                                          → Update Booking (paid)
                               → If gateway: Create Payment
                                           → Return paymentUrl

CHAT FLOW:
User → POST /conversations → Create Conversation
                           → participants = [customer, provider]
User → POST /:id/messages → Create Message
                          → Update lastMessageAt
                          → Increment unreadCount
                          → Create Notification

DISPUTE FLOW:
Customer → POST /disputes → Create Dispute (open)
Admin → POST /resolve → Update Dispute (resolved)
                      → If customer_favor: Create Refund
                                         → Update Wallet


┌─────────────────────────────────────────────────────────────────────┐
│                       DATABASE SCHEMA                               │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────┐     ┌──────────────────┐     ┌──────────────┐
│   Wallet    │────<│ WalletTransaction│     │   Payment    │
├─────────────┤     ├──────────────────┤     ├──────────────┤
│ userId (PK) │     │ id (PK)          │     │ id (PK)      │
│ balance     │     │ walletId (FK)    │     │ bookingId    │
│ currency    │     │ type             │     │ amount       │
│ createdAt   │     │ amount           │     │ method       │
└─────────────┘     │ balanceAfter     │     │ gateway      │
                    │ status           │     │ gatewayTxId  │
                    │ description      │     │ status       │
                    └──────────────────┘     └──────────────┘

┌──────────────┐     ┌──────────────┐
│ Conversation │────<│   Message    │
├──────────────┤     ├──────────────┤
│ id (PK)      │     │ id (PK)      │
│ bookingId    │     │ convId (FK)  │
│ participants │     │ senderId     │
│ lastMsgAt    │     │ content      │
│ unreadCount  │     │ type         │
└──────────────┘     │ attachmentUrl│
                     └──────────────┘

┌──────────────┐
│   Dispute    │
├──────────────┤
│ id (PK)      │
│ bookingId    │
│ raisedBy     │
│ reason       │
│ status       │
│ resolution   │
│ resolvedBy   │
└──────────────┘


┌─────────────────────────────────────────────────────────────────────┐
│                      AUTHENTICATION                                 │
└─────────────────────────────────────────────────────────────────────┘

User → POST /auth/login → Verify credentials
                        → Generate JWT tokens
                        → Return { accessToken, refreshToken }

Request → Header: Authorization: Bearer {token}
       → JwtAuthGuard → Verify token
                      → Extract payload
                      → @CurrentUser() decorator


┌─────────────────────────────────────────────────────────────────────┐
│                    BUSINESS RULES                                   │
└─────────────────────────────────────────────────────────────────────┘

WALLETS:
✓ Min deposit: 100,000 VND
✓ Min withdraw: 100,000 VND
✓ Max withdraw per transaction: 10,000,000 VND
✓ Daily withdraw limit: 10,000,000 VND
✓ Auto-approve withdraw < 1,000,000 VND
✓ Need approval withdraw >= 1,000,000 VND

PAYMENTS:
✓ Support: wallet, momo, card, bank_transfer
✓ Webhook must verify signature (production)
✓ Idempotency check for webhooks
✓ Auto-create notifications

CONVERSATIONS:
✓ One conversation per booking
✓ Only participants can access
✓ Support text, image, file messages
✓ Auto-update lastMessageAt
✓ Track unread count

DISPUTES:
✓ Only customer can create
✓ Only for completed bookings
✓ One dispute per booking
✓ Admin can resolve
✓ Support refund if customer_favor


┌─────────────────────────────────────────────────────────────────────┐
│                      TEST SCENARIOS                                 │
└─────────────────────────────────────────────────────────────────────┘

SCENARIO 1: Full Deposit Flow
1. Login → Get token
2. GET /wallets/balance → 0
3. POST /wallets/deposit (500k) → paymentUrl
4. POST /webhook (success) → balance updated
5. GET /wallets/balance → 500,000
6. GET /wallets/transactions → 1 deposit

SCENARIO 2: Booking Payment
1. Create booking → bookingId
2. POST /payments/checkout (wallet) → paid
3. GET /wallets/balance → decreased
4. GET /wallets/transactions → 1 payment

SCENARIO 3: Chat
1. POST /conversations → conversationId
2. POST /:id/messages → message sent
3. GET /:id/messages → list messages
4. PATCH /:id/read → unreadCount = 0

SCENARIO 4: Dispute
1. POST /disputes → disputeId
2. POST /admin/resolve (customer_favor) → refund
3. GET /wallets/balance → increased


┌─────────────────────────────────────────────────────────────────────┐
│                    ERROR HANDLING                                   │
└─────────────────────────────────────────────────────────────────────┘

401 Unauthorized
├─ Token expired
├─ Invalid token
└─ Missing token

403 Forbidden
├─ No permission
├─ Not participant
└─ Wrong role

400 Bad Request
├─ Validation error
├─ Insufficient balance
├─ Daily limit exceeded
└─ Already exists

404 Not Found
├─ Booking not found
├─ Conversation not found
└─ Dispute not found

500 Internal Server Error
├─ Database error
├─ Transaction failed
└─ Unexpected error


┌─────────────────────────────────────────────────────────────────────┐
│                    DOCUMENTATION FILES                              │
└─────────────────────────────────────────────────────────────────────┘

📊 BACKEND-ANALYSIS.md
   └─ Architecture, modules, database, flows

🧪 TEST-API-MEMBER-3.md
   └─ Detailed testing guide with examples

🚀 QUICK-API-TEST.md
   └─ Quick reference for fast testing

📚 README-MEMBER-3.md
   └─ Overview and guide to documentation

🗺️ API-MAP.md (this file)
   └─ Visual architecture map


┌─────────────────────────────────────────────────────────────────────┐
│                      QUICK COMMANDS                                 │
└─────────────────────────────────────────────────────────────────────┘

# Start backend
pnpm dev

# Open Swagger
http://localhost:3000/api

# Login
POST /auth/login
{ "phone": "+84999111222", "password": "Customer123!@#" }

# Check balance
GET /wallets/balance
Authorization: Bearer {token}

# Deposit
POST /wallets/deposit
{ "amount": 500000, "gateway": "momo" }

# Mock webhook
POST /payments/webhook/momo
{ "orderId": "xxx", "resultCode": 0, "amount": 500000 }


┌─────────────────────────────────────────────────────────────────────┐
│                         METRICS                                     │
└─────────────────────────────────────────────────────────────────────┘

Total Endpoints: 13
├─ Wallets: 4
├─ Payments: 2
├─ Conversations: 5
├─ Disputes: 1
└─ Admin: 1

Database Tables: 5
├─ wallets
├─ wallet_transactions
├─ payments
├─ conversations
└─ messages

Lines of Code: ~2,500
Test Coverage: 100% documented
Documentation: 4 files, 2,500+ lines
```
