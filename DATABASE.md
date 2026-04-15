# Thiết kế Cơ sở dữ liệu - Local Service Platform v2

> **Tài liệu thiết kế database** cho hệ thống đặt lịch dịch vụ tại nhà, bao gồm 28 bảng dữ liệu với các tính năng: Booking, Wallet, PostGIS (Location-based), Blockchain, Chat, và RBAC (Phân quyền).

**Yêu cầu:** PostgreSQL 13+ với extension PostGIS
```sql
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS pgcrypto;
```

---

## 📚 TỔNG QUAN HỆ THỐNG

### Kiến trúc Module

```
┌─────────────────────────────────────────────────────────────┐
│                    LOCAL SERVICE PLATFORM                    │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │   USER &     │  │     RBAC     │  │   SERVICE &  │      │
│  │     AUTH     │  │  (Phân quyền)│  │   PROVIDER   │      │
│  │   4 bảng     │  │   4 bảng     │  │   5 bảng     │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
│                                                               │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │   BOOKING &  │  │   PAYMENT &  │  │  INTERACTION │      │
│  │   LOCATION   │  │    WALLET    │  │ (Chat, Review)│     │
│  │   3 bảng     │  │   3 bảng     │  │   4 bảng     │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
│                                                               │
│  ┌──────────────────────────────────────────────────┐       │
│  │         SYSTEM & UTILITIES (5 bảng)              │       │
│  │  Media, Notifications, Audit, Blockchain, Settings│      │
│  └──────────────────────────────────────────────────┘       │
└─────────────────────────────────────────────────────────────┘
```

### Phân bổ 28 Bảng

| Module | Bảng | Mục đích |
|--------|------|----------|
| **User & Auth** | 4 | Quản lý tài khoản, profile, OTP, sessions |
| **RBAC** | 4 | Hệ thống phân quyền linh hoạt |
| **Service & Provider** | 5 | Dịch vụ, danh mục, thợ, yêu thích |
| **Booking & Location** | 3 | Đơn hàng, địa chỉ, lịch sử |
| **Payment & Wallet** | 3 | Thanh toán, ví, sổ cái giao dịch |
| **Interaction** | 4 | Chat, đánh giá, tranh chấp |
| **System & Utilities** | 5 | File, thông báo, audit, blockchain, config |

---

##  MODULE 1: USER & AUTH (4 bảng)

### 1.1 `users` - Tài khoản Người dùng

**Mục đích:** Bảng trung tâm, lưu thông tin đăng nhập cốt lõi

**Trường dữ liệu:**
- `id` (BIGSERIAL, PK) - ID người dùng
- `phone` (VARCHAR(20), UNIQUE, NOT NULL) - Số điện thoại (đăng nhập chính)
- `email` (VARCHAR(255), UNIQUE, NULL) - Email (tùy chọn)
- `password_hash` (VARCHAR(255), NULL) - Hash bcrypt (NULL nếu login bằng OTP)
- `status` (VARCHAR(30), DEFAULT 'active') - Trạng thái: active, inactive, banned
- `is_verified` (BOOLEAN, DEFAULT false) - Đã xác thực SĐT?
- `last_login_at` (TIMESTAMPTZ, NULL)
- `metadata` (JSONB, NULL) - Thông tin mở rộng
- `created_at`, `updated_at` (TIMESTAMPTZ)

**Quan hệ:**
- 1-1 → `user_profiles` (thông tin cá nhân)
- 1-1 → `provider_profiles` (nếu là thợ)
- 1-1 → `wallets` (ví tiền)
- 1-N → `user_roles` (vai trò)
- 1-N → `addresses`, `bookings`, `sessions`, `notifications`

**Index cần thiết:**
- `(email)` - WHERE email IS NOT NULL
- `(status)` - Filter theo trạng thái
- `(phone, status)` - Composite cho query phổ biến

** Cải tiến quan trọng:** Thêm soft delete
- Bổ sung: `deleted_at` (TIMESTAMPTZ, NULL)

---

### 1.2 `user_profiles` - Hồ sơ Người dùng

**Mục đích:** Thông tin mở rộng (profile), không bắt buộc khi đăng ký

**Trường dữ liệu:**
- `user_id` (BIGINT, PK, FK → users)
- `full_name` (VARCHAR(200))
- `avatar_url` (TEXT, NULL)
- `bio` (TEXT, NULL)
- `gender` (VARCHAR(20), NULL) - male, female, other
- `birth_date` (DATE, NULL)
- `address_text` (TEXT, NULL) - Địa chỉ dạng văn bản
- `location` (geography(Point,4326), NULL) - Tọa độ GPS (PostGIS)
- `created_at`, `updated_at`

**Index PostGIS:**
- `GIST(location)` - Truy vấn không gian

**ON DELETE:** CASCADE (xóa user → xóa profile)

---

### 1.3 `otp_codes` - Mã OTP

**Mục đích:** Xác thực OTP cho đăng nhập/đặt lại mật khẩu

**Trường dữ liệu:**
- `id` (BIGSERIAL, PK)
- `phone` (VARCHAR(20), NOT NULL)
- `code_hash` (VARCHAR(255), NOT NULL) - **[CẢI TIẾN]** Hash SHA256, không lưu plaintext
- `purpose` (VARCHAR(50), NOT NULL) - login, reset_password, verify_phone
- `expires_at` (TIMESTAMPTZ, NOT NULL) - Hết hạn sau 5-10 phút
- `used` (BOOLEAN, DEFAULT false)
- `attempt_count` (SMALLINT, DEFAULT 0) - **[CẢI TIẾN]** Đếm số lần thử
- `last_attempt_at` (TIMESTAMPTZ, NULL) - **[CẢI TIẾN]** Thời điểm thử cuối
- `ip_address` (VARCHAR(50), NULL) - **[CẢI TIẾN]** IP để tracking
- `created_at`

**Index:**
- `(phone, purpose, used)` - Query OTP còn hiệu lực

** Security Rules:**
1. **Hash OTP:** Sử dụng SHA256 hash thay vì lưu plaintext
2. **Rate Limiting:** Max 5 lần thử (`attempt_count <= 5`)
3. **Cooldown:** Giới hạn tạo OTP mới (1 OTP/60s cho mỗi phone)
4. **Auto Cleanup:** Xóa OTP cũ hơn 24h (cronjob)

**Flow sử dụng:**
```
1. Tạo OTP → hash và lưu code_hash
2. User nhập OTP → hash input, so sánh với code_hash
3. Tăng attempt_count mỗi lần thử sai
4. Block nếu attempt_count > 5 hoặc quá expires_at
```

---

### 1.4 `sessions` - Phiên đăng nhập

**Mục đích:** Quản lý refresh token, hỗ trợ "Đăng xuất khỏi tất cả thiết bị"

**Trường dữ liệu:**
- `id` (UUID, PK, DEFAULT gen_random_uuid())
- `user_id` (BIGINT, NOT NULL, FK → users)
- `refresh_token_hash` (VARCHAR(255), NOT NULL) - Hash của refresh token
- `user_agent` (TEXT, NULL) - Thông tin thiết bị
- `ip` (VARCHAR(50), NULL)
- `expires_at` (TIMESTAMPTZ, NOT NULL)
- `revoked` (BOOLEAN, DEFAULT false)
- `created_at`, `revoked_at`

**Index:**
- `(user_id, expires_at)` WHERE NOT revoked - Query session hợp lệ
- `(refresh_token_hash)` - Lookup nhanh

**Security:** Token được hash bằng bcrypt/SHA256 trước khi lưu

---

## 👥 MODULE 2: RBAC - ROLE BASED ACCESS CONTROL (4 bảng)

### Sơ đồ quan hệ RBAC

```
users (N) ←→ user_roles (M:N) ←→ (N) roles
                                      ↓
                                role_permissions (M:N)
                                      ↓
                                  permissions
```

### 2.1 `roles` - Vai trò

**Mục đích:** Định nghĩa vai trò trong hệ thống

**Trường dữ liệu:**
- `id` (SERIAL, PK)
- `name` (VARCHAR(50), UNIQUE, NOT NULL) - customer, provider, moderator, super_admin
- `description` (TEXT)
- `created_at` (TIMESTAMPTZ) - **[CẢI TIẾN]**

**Dữ liệu mẫu:**
- `customer` - Khách hàng
- `provider` - Nhà cung cấp (thợ)
- `moderator` - Quản trị viên cấp thấp
- `super_admin` - Quản trị viên hệ thống

---

### 2.2 `permissions` - Quyền hạn

**Mục đích:** Định nghĩa các action cụ thể

**Trường dữ liệu:**
- `id` (SERIAL, PK)
- `action` (VARCHAR(100), UNIQUE, NOT NULL) - manage_dispute, verify_provider, view_reports
- `description` (TEXT)
- `created_at` (TIMESTAMPTZ) - **[CẢI TIẾN]**

**Dữ liệu mẫu:**
- `bookings.create`, `bookings.update`, `bookings.cancel`
- `providers.verify`, `providers.suspend`
- `disputes.manage`, `disputes.resolve`
- `reports.view`, `reports.export`
- `users.ban`, `users.unban`

---

### 2.3 `user_roles` - Gán Vai trò cho User

**Bảng nối Many-to-Many**

**Trường dữ liệu:**
- `user_id` (BIGINT, FK → users, ON DELETE CASCADE)
- `role_id` (INT, FK → roles, ON DELETE CASCADE)
- `created_at` (TIMESTAMPTZ) - **[CẢI TIẾN]**
- **PK:** (user_id, role_id)

**Lưu ý:** 1 user có thể có nhiều role (vừa customer vừa provider)

---

### 2.4 `role_permissions` - Gán Quyền cho Role

**Bảng nối Many-to-Many**

**Trường dữ liệu:**
- `role_id` (INT, FK → roles, ON DELETE CASCADE)
- `permission_id` (INT, FK → permissions, ON DELETE CASCADE)
- `created_at` (TIMESTAMPTZ) - **[CẢI TIẾN]**
- **PK:** (role_id, permission_id)

**Check Permission Flow:**
```
user → user_roles → roles → role_permissions → permissions
```

---

## 🛠️ MODULE 3: SERVICE & PROVIDER (5 bảng)

### 3.1 `provider_profiles` - Hồ sơ Nhà cung cấp (Thợ)

**Mục đích:** Thông tin chuyên môn của thợ

**Trường dữ liệu:**
- `user_id` (BIGINT, PK, FK → users, ON DELETE CASCADE)
- `display_name` (VARCHAR(200), NOT NULL) - Tên hiển thị công khai
- `bio` (TEXT) - Giới thiệu
- `skills` (JSONB, NULL) - Mảng kỹ năng: `["dien_lanh", "sua_ong_nuoc"]`
- `rating_avg` (NUMERIC(3,2), DEFAULT 0) - Trung bình rating (0-5)
- `rating_count` (INT, DEFAULT 0) - Tổng số đánh giá
- `is_available` (BOOLEAN, DEFAULT true) - Đang sẵn sàng nhận việc?
- `verification_status` (VARCHAR(30), DEFAULT 'unverified')
  - unverified, pending, verified, rejected
- `location` (geography(Point,4326), NULL) - Vị trí hiện tại
- `service_radius_m` (INT, DEFAULT 5000) - Bán kính phục vụ (mét)
- `created_at`, `updated_at`

**Index:**
- `GIST(location)` - Tìm thợ gần
- `(is_available)` - Filter thợ sẵn sàng
- `(verification_status)` - Filter thợ đã verify

** Cải tiến quan trọng:**
- **Rating tự động:** `rating_avg` và `rating_count` được update tự động bởi trigger khi có review mới
- **Trigger logic:**
  ```
  Khi INSERT vào reviews:
    → Tính lại AVG(rating) và COUNT(*) cho reviewee_id
    → UPDATE provider_profiles SET rating_avg, rating_count
  ```

---

### 3.2 `service_categories` - Danh mục Dịch vụ

**Mục đích:** Phân loại dịch vụ (có thể đa cấp)

**Trường dữ liệu:**
- `id` (SERIAL, PK)
- `code` (VARCHAR(50), UNIQUE, NOT NULL) - dien_lanh, ve_sinh
- `name` (VARCHAR(150), NOT NULL) - "Điện lạnh", "Vệ sinh"
- `slug` (VARCHAR(150), UNIQUE) - dien-lanh
- `description` (TEXT)
- `icon_url` (TEXT, NULL) - URL icon
- `parent_id` (INT, NULL, FK → service_categories, ON DELETE SET NULL)
- `created_at`, `updated_at`

**Cấu trúc cây (tùy chọn):**
```
Sửa chữa điện (parent_id = NULL)
  ├─ Điều hòa (parent_id = 1)
  ├─ Tủ lạnh (parent_id = 1)
Vệ sinh nhà cửa (parent_id = NULL)
  ├─ Tổng vệ sinh (parent_id = 2)
  └─ Vệ sinh máy lạnh (parent_id = 2)
```

---

### 3.3 `services` - Dịch vụ (Template)

**Mục đích:** Định nghĩa các gói dịch vụ chuẩn

**Trường dữ liệu:**
- `id` (SERIAL, PK)
- `category_id` (INT, FK → service_categories, ON DELETE SET NULL)
- `name` (VARCHAR(200), NOT NULL) - "Sửa điều hòa tại nhà"
- `description` (TEXT) - Mô tả chi tiết
- `base_price` (NUMERIC(12,2), DEFAULT 0) - Giá tham khảo
- `duration_minutes` (INT, NULL) - Thời gian ước tính
- `created_at`, `updated_at`

**Lưu ý:** 
- Giá `base_price` chỉ là tham khảo
- Giá thực tế do từng thợ tự định (bảng `provider_services`)

---

### 3.4 `provider_services` - Dịch vụ của từng Thợ

**Mục đích:** Bảng nối M:N, thợ A cung cấp dịch vụ B với giá C

**Trường dữ liệu:**
- `provider_user_id` (BIGINT, FK → provider_profiles, ON DELETE CASCADE)
- `service_id` (INT, FK → services, ON DELETE CASCADE)
- `price` (NUMERIC(12,2), NOT NULL) - Giá riêng của thợ này
- `currency` (VARCHAR(10), DEFAULT 'VND')
- `is_active` (BOOLEAN, DEFAULT true)
- `created_at`, `updated_at`
- `deleted_at` (TIMESTAMPTZ, NULL) - **[CẢI TIẾN]** Soft delete
- **PK:** (provider_user_id, service_id)

**Query pattern:**
```
Tìm thợ cung cấp dịch vụ X trong bán kính Y từ tọa độ Z:

SELECT pp.*, ps.price
FROM provider_profiles pp
JOIN provider_services ps ON ps.provider_user_id = pp.user_id
WHERE ps.service_id = X
  AND ps.is_active = true
  AND pp.is_available = true
  AND pp.verification_status = 'verified'
  AND ST_DWithin(pp.location, ST_MakePoint(lng, lat)::geography, Y)
ORDER BY pp.location <-> ST_MakePoint(lng, lat)::geography
```

---

### 3.5 `favorites` - Yêu thích

**Mục đích:** User lưu thợ hoặc dịch vụ yêu thích

**Trường dữ liệu:**
- `user_id` (BIGINT, FK → users, ON DELETE CASCADE)
- `target_type` (VARCHAR(20), NOT NULL) - 'provider' hoặc 'service'
- `target_id` (BIGINT, NOT NULL) - ID của provider hoặc service
- `created_at`
- **PK:** (user_id, target_type, target_id)

**Ví dụ:**
```
user_id=1, target_type='provider', target_id=5 → User 1 yêu thích thợ 5
user_id=1, target_type='service', target_id=3 → User 1 yêu thích dịch vụ 3
```

---

## 📍 MODULE 4: BOOKING & LOCATION (3 bảng)

### 4.1 `addresses` - Địa chỉ đã lưu

**Mục đích:** Sổ địa chỉ của người dùng (Nhà, Công ty...)

**Trường dữ liệu:**
- `id` (BIGSERIAL, PK)
- `user_id` (BIGINT, FK → users, ON DELETE CASCADE)
- `label` (VARCHAR(100)) - "Nhà", "Công ty", "Nhà bố mẹ"
- `address_text` (TEXT, NOT NULL) - Địa chỉ đầy đủ
- `location` (geography(Point,4326), NOT NULL) - Tọa độ
- `is_default` (BOOLEAN, DEFAULT false)
- `created_at`, `updated_at`

**Index:**
- `GIST(location)`

**⚠️ Cải tiến quan trọng: Constraint is_default**
- **Vấn đề:** Nhiều địa chỉ có thể cùng `is_default = true`
- **Giải pháp:** Partial unique index
  ```sql
  CREATE UNIQUE INDEX idx_addresses_user_default 
    ON addresses(user_id) WHERE is_default = true;
  ```
- **Kết quả:** Mỗi user chỉ có tối đa 1 địa chỉ mặc định

---

### 4.2 `bookings` - Đơn hàng/Đặt lịch ⭐

**Mục đích:** Bảng nghiệp vụ cốt lõi nhất của hệ thống

**Trường dữ liệu:**
- `id` (BIGSERIAL, PK)
- `code` (VARCHAR(50), UNIQUE) - Mã tracking: "BK-10001"
- `customer_id` (BIGINT, NOT NULL, FK → users, ON DELETE RESTRICT)
- `provider_id` (BIGINT, NULL, FK → provider_profiles(user_id), ON DELETE RESTRICT)
  - **[CẢI TIẾN]** Constraint đảm bảo provider_id phải là thợ thực sự
  - NULL = đang chờ thợ nhận
- `service_id` (INT, NOT NULL, FK → services, ON DELETE RESTRICT)
- `provider_service_price` (NUMERIC(12,2)) - Giá copy từ provider_services
- `status` (VARCHAR(30), NOT NULL, DEFAULT 'pending')
  - **States:** pending, accepted, in_progress, completed, cancelled, disputed
- `scheduled_at` (TIMESTAMPTZ, NOT NULL) - Giờ hẹn
- `address_text` (TEXT, NOT NULL)
- `location` (geography(Point,4326), NOT NULL)
- `notes` (TEXT) - Ghi chú của khách
- `estimated_duration_minutes` (INT)
- `estimated_price` (NUMERIC(12,2))
- `actual_price` (NUMERIC(12,2), NULL) - Giá cuối (thợ update sau khi hoàn thành)
- `platform_fee` (NUMERIC(12,2), DEFAULT 0) - Phí nền tảng
- `provider_earning` (NUMERIC(12,2), DEFAULT 0) - Thu nhập của thợ
- `escrow_contract_address` (VARCHAR(66), NULL) - Smart contract address (Blockchain)
- `created_at`, `updated_at`
- `completed_at` (TIMESTAMPTZ, NULL)
- `cancelled_at` (TIMESTAMPTZ, NULL)

**Index:**
- `(customer_id, status)`
- `(provider_id, status)`
- `(scheduled_at)`
- `(status, scheduled_at)` - Lọc đơn theo status và thời gian
- `GIST(location)`

**⚠️ Cải tiến quan trọng: Status Validation**

**Vấn đề:** Không validate chuyển trạng thái (ví dụ: completed → pending là không hợp lệ)

**Giải pháp:** State Machine Validation
```
Valid transitions:
  pending → accepted, cancelled
  accepted → in_progress, cancelled
  in_progress → completed, disputed
  completed → disputed
  (disputed không thể chuyển, chỉ resolve qua bảng disputes)
```

**Implementation:** 
- Tạo bảng `booking_status_transitions` chứa các cặp (from_status, to_status) hợp lệ
- Trigger validate trước khi UPDATE status

**Booking Lifecycle:**
```
1. CREATE: customer tạo → status = 'pending', provider_id = NULL
2. ACCEPT: provider nhận → status = 'accepted', gán provider_id
3. START: provider bắt đầu → status = 'in_progress'
4. COMPLETE: provider hoàn thành → status = 'completed', cập nhật actual_price
5. PAYMENT: Giải ngân từ escrow → provider_earning vào wallet
6. REVIEW: Customer đánh giá
```

---

### 4.3 `booking_events` - Lịch sử Booking

**Mục đích:** Audit log cho mọi thay đổi status

**Trường dữ liệu:**
- `id` (BIGSERIAL, PK)
- `booking_id` (BIGINT, NOT NULL, FK → bookings, ON DELETE CASCADE)
- `previous_status` (VARCHAR(30), NULL)
- `new_status` (VARCHAR(30), NOT NULL)
- `actor_user_id` (BIGINT, NULL, FK → users) - Ai thực hiện (customer/provider/admin)
- `note` (TEXT) - Lý do, ghi chú
- `created_at`

**Index:**
- `(booking_id, created_at DESC)` - Xem timeline của 1 booking

**Auto-trigger:** Mỗi khi `bookings.status` thay đổi → tự động INSERT vào `booking_events`

---

## 💰 MODULE 5: PAYMENT & WALLET (3 bảng)

### Luồng tiền (Money Flow)

```
Customer → Payment Gateway → payments table
                             ↓
                    wallet (balance tăng)
                             ↓
                    wallet_transactions (ledger)
                             ↓
         Booking completed → Escrow release
                             ↓
            Provider wallet (balance tăng)
            Platform wallet (fee)
```

### 5.1 `payments` - Giao dịch qua Cổng thanh toán

**Mục đích:** Ghi lại mọi giao dịch qua bên thứ 3

**Trường dữ liệu:**
- `id` (BIGSERIAL, PK)
- `booking_id` (BIGINT, NULL, FK → bookings, ON DELETE SET NULL)
  - NULL = nạp tiền vào ví (topup)
- `amount` (NUMERIC(15,2), NOT NULL)
- `currency` (VARCHAR(10), DEFAULT 'VND')
- `method` (VARCHAR(50), NOT NULL) - card, momo, bank_transfer, wallet, crypto
- `gateway` (VARCHAR(100), NULL) - Stripe, VNPay, OnChain
- `gateway_tx_id` (VARCHAR(200), NOT NULL) - Mã GD của gateway
- `environment` (VARCHAR(20), DEFAULT 'production') - **[CẢI TIẾN]** production, sandbox
- `status` (VARCHAR(30), NOT NULL, DEFAULT 'initiated')
  - **States:** initiated, succeeded, failed
- `payload` (JSONB) - Raw callback data
- `reconciled` (BOOLEAN, DEFAULT false) - Đã đối soát?
- `created_at`, `updated_at`

**Index:**
- `(booking_id)`
- `(status)`
- `(gateway, gateway_tx_id, environment)` - **[CẢI TIẾN]** Composite unique

**⚠️ Cải tiến: Gateway TX Uniqueness**
- **Vấn đề:** `gateway_tx_id` UNIQUE có thể trùng giữa production và sandbox
- **Giải pháp:** Thêm `environment` vào constraint
  ```sql
  UNIQUE (gateway, gateway_tx_id, environment)
  ```

---

### 5.2 `wallets` - Ví Người dùng

**Mục đích:** Lưu số dư hiện tại (hot wallet)

**Trường dữ liệu:**
- `user_id` (BIGINT, PK, FK → users, ON DELETE CASCADE)
- `balance` (NUMERIC(18,4), NOT NULL, DEFAULT 0, CHECK balance >= 0)
- `currency` (VARCHAR(10), DEFAULT 'VND')
- `blockchain_address` (VARCHAR(66), NULL, UNIQUE) - Cold wallet address
- `version` (INT, NOT NULL, DEFAULT 0) - **[CẢI TIẾN]** Optimistic locking
- `locked_until` (TIMESTAMPTZ, NULL) - **[CẢI TIẾN]** Pessimistic locking
- `locked_by` (VARCHAR(100), NULL) - **[CẢI TIẾN]** Transaction ID đang lock
- `created_at`, `updated_at`

**⚠️ Cải tiến quan trọng: Concurrency Control**

**Vấn đề:** Race condition khi cập nhật balance đồng thời
```
User có 100k
Transaction A: Trừ 50k → đọc 100k, tính 50k, ghi 50k
Transaction B: Trừ 30k → đọc 100k, tính 70k, ghi 70k
Kết quả: 70k (sai! phải là 20k)
```

**Giải pháp 1: Optimistic Locking**
```
1. SELECT balance, version WHERE user_id = X
2. Tính toán: new_balance = balance - amount
3. UPDATE wallets 
   SET balance = new_balance, version = version + 1
   WHERE user_id = X AND version = old_version
4. Nếu affected_rows = 0 → Retry (có transaction khác đã update)
```

**Giải pháp 2: Pessimistic Locking (Row-level lock)**
```sql
BEGIN;
SELECT * FROM wallets WHERE user_id = X FOR UPDATE;
UPDATE wallets SET balance = balance - amount WHERE user_id = X;
COMMIT;
```

**Giải pháp 3: Application-level lock**
```
1. UPDATE wallets SET locked_until = NOW() + '5 seconds', locked_by = 'tx_123'
   WHERE user_id = X AND (locked_until IS NULL OR locked_until < NOW())
2. Nếu success → xử lý
3. UPDATE wallets SET balance = ..., locked_until = NULL
```

**Khuyến nghị:** Dùng Pessimistic Locking (SELECT FOR UPDATE) trong transaction

---

### 5.3 `wallet_transactions` - Sổ cái Giao dịch

**Mục đích:** Immutable ledger, ghi MỌI thay đổi số dư

**Trường dữ liệu:**
- `id` (BIGSERIAL, PK)
- `wallet_user_id` (BIGINT, NOT NULL, FK → wallets(user_id), ON DELETE RESTRICT)
- `related_payment_id` (BIGINT, NULL, FK → payments, ON DELETE SET NULL)
- `type` (VARCHAR(30), NOT NULL)
  - **Types:** deposit, withdrawal, payment, fee, refund, earning
- `amount` (NUMERIC(18,4), NOT NULL)
  - DƯƠNG: Nạp tiền, nhận tiền (earning, refund)
  - ÂM: Rút tiền, trả tiền (payment, fee)
- `balance_after` (NUMERIC(18,4), NOT NULL) - Số dư sau giao dịch
- `idempotency_key` (VARCHAR(100), UNIQUE, NULL) - Chống double-entry
- `status` (VARCHAR(30), DEFAULT 'completed') - pending, completed, failed
- `metadata` (JSONB) - Thông tin bổ sung
- `created_at`

**Index:**
- `(wallet_user_id, created_at DESC)` - Lịch sử giao dịch
- `(type)`
- `(related_payment_id)` WHERE related_payment_id IS NOT NULL

**Immutability:** Bảng này là APPEND-ONLY, không UPDATE/DELETE
- Nếu cần hoàn tiền → INSERT record mới type='refund'

**Idempotency:** Đảm bảo 1 giao dịch không bị xử lý 2 lần
```
idempotency_key = "topup_payment_12345"
→ Nếu đã tồn tại → skip (đã xử lý rồi)
```

---

## 💬 MODULE 6: INTERACTION (4 bảng)

### 6.1 `reviews` - Đánh giá

**Mục đích:** Customer đánh giá provider sau khi hoàn thành

**Trường dữ liệu:**
- `id` (BIGSERIAL, PK)
- `booking_id` (BIGINT, NOT NULL, UNIQUE, FK → bookings, ON DELETE CASCADE)
- `reviewer_id` (BIGINT, NOT NULL, FK → users, ON DELETE CASCADE)
- `reviewee_id` (BIGINT, NOT NULL, FK → users, ON DELETE CASCADE)
  - Thường là provider_id từ booking
- `rating` (SMALLINT, NOT NULL, CHECK rating BETWEEN 1 AND 5)
- `title` (VARCHAR(255), NULL)
- `comment` (TEXT, NULL)
- `blockchain_tx_hash` (VARCHAR(66), NULL, UNIQUE) - Hash của review on-chain
- `created_at`

**Index:**
- `(reviewee_id, rating)` - Tính rating provider
- `(reviewee_id, created_at DESC)` - **[CẢI TIẾN]** Danh sách review mới nhất
- `(reviewer_id)` - **[CẢI TIẾN]** Review của user

**Constraint:**
- 1 booking chỉ có 1 review (UNIQUE booking_id)
- rating phải từ 1-5

**Auto-trigger:** Khi INSERT review → update `provider_profiles.rating_avg` và `rating_count`

---

### 6.2 `disputes` - Tranh chấp

**Mục đích:** Khiếu nại, tranh chấp cần admin can thiệp

**Trường dữ liệu:**
- `id` (BIGSERIAL, PK)
- `booking_id` (BIGINT, NOT NULL, UNIQUE, FK → bookings, ON DELETE RESTRICT)
- `raised_by` (BIGINT, NOT NULL, FK → users) - Người khiếu nại
- `reason` (TEXT, NOT NULL)
- `status` (VARCHAR(30), DEFAULT 'open')
  - **States:** open, under_review, resolved, closed
- `resolution` (TEXT, NULL) - Kết quả xử lý
- `resolved_by_admin_id` (BIGINT, NULL, FK → users)
- `created_at`
- `resolved_at` (TIMESTAMPTZ, NULL)

**Business Logic:**
- Khi tạo dispute → `bookings.status` chuyển thành 'disputed'
- Tiền escrow bị hold, chờ admin xử lý

---

### 6.3 `conversations` - Phiên Chat

**Mục đích:** Tạo "phòng" chat 1-1 giữa customer và provider

**Trường dữ liệu:**
- `id` (BIGSERIAL, PK)
- `customer_id` (BIGINT, NOT NULL, FK → users, ON DELETE CASCADE)
- `provider_id` (BIGINT, NOT NULL, FK → users, ON DELETE CASCADE)
- `booking_id` (BIGINT, NULL, FK → bookings, ON DELETE SET NULL)
  - NULL = chat chung, không liên quan booking cụ thể
- `last_message_id` (BIGINT, NULL) - Pointer đến message cuối
- `last_message_at` (TIMESTAMPTZ, NULL) - **[CẢI TIẾN]** Thời gian message cuối
- `unread_count` (INT, DEFAULT 0) - **[CẢI TIẾN]** Số tin chưa đọc
- `created_at`, `updated_at`

**Index:**
- `(customer_id)` - List conversations của customer
- `(provider_id)` - List conversations của provider
- `(booking_id)` WHERE booking_id IS NOT NULL - **[CẢI TIẾN]** 1 booking = 1 conversation

**⚠️ Cải tiến: Unique Constraint**
- **Vấn đề cũ:** UNIQUE (customer_id, provider_id, booking_id) → không cho chat nhiều lần
- **Giải pháp mới:**
  ```sql
  -- Cho phép nhiều conversation giữa 2 người
  -- Nhưng mỗi booking chỉ có 1 conversation
  CREATE UNIQUE INDEX idx_conversations_booking 
    ON conversations(booking_id) 
    WHERE booking_id IS NOT NULL;
  ```

**Auto-update:** Trigger tự động cập nhật `last_message_id`, `last_message_at`, `unread_count` khi có tin nhắn mới

---

### 6.4 `messages` - Tin nhắn

**Mục đích:** Lưu nội dung từng tin nhắn

**Trường dữ liệu:**
- `id` (BIGSERIAL, PK)
- `conversation_id` (BIGINT, NOT NULL, FK → conversations, ON DELETE CASCADE)
- `sender_id` (BIGINT, NOT NULL, FK → users)
- `body` (TEXT, NOT NULL) - Nội dung tin nhắn
- `read_at` (TIMESTAMPTZ, NULL) - Người nhận đọc lúc nào?
- `created_at`

**Index:**
- `(conversation_id, created_at DESC)` - List messages trong 1 conversation
- `(sender_id)` - **[CẢI TIẾN]** Messages của user
- `(conversation_id, read_at)` WHERE read_at IS NULL - **[CẢI TIẾN]** Tin chưa đọc

**Pagination:** Sử dụng cursor-based hoặc offset với created_at

---

## ⚙️ MODULE 7: SYSTEM & UTILITIES (5 bảng)

### 7.1 `media` - File/Media Storage

**Mục đích:** Lưu metadata của file (URL S3/GCS), không lưu binary

**Trường dữ liệu:**
- `id` (BIGSERIAL, PK)
- `owner_type` (VARCHAR(50), NOT NULL) - user, service, booking, dispute, message
- `owner_id` (BIGINT, NOT NULL) - ID của owner
- `url` (TEXT, NOT NULL) - Full URL (S3/GCS/CDN)
- `mime_type` (VARCHAR(100)) - image/jpeg, application/pdf
- `size` (INT) - Bytes
- `meta` (JSONB) - Width, height, duration...
- `uploaded_by` (BIGINT, FK → users) - **[CẢI TIẾN]** Ai upload
- `category` (VARCHAR(50)) - **[CẢI TIẾN]** avatar, booking_proof, dispute_evidence
- `is_public` (BOOLEAN, DEFAULT true)
- `deleted_at` (TIMESTAMPTZ, NULL) - **[CẢI TIẾN]** Soft delete
- `created_at`

**Index:**
- `(owner_type, owner_id)`
- `(uploaded_by)` - **[CẢI TIẾN]**
- `(owner_type, category)` - **[CẢI TIẾN]**

**Ví dụ:**
```
owner_type='booking', owner_id=123 → Ảnh chụp của booking 123
owner_type='user', owner_id=5, category='avatar' → Avatar của user 5
owner_type='dispute', owner_id=7 → Evidence cho dispute 7
```

---

### 7.2 `notifications` - Thông báo

**Mục đích:** In-app notification và push notification

**Trường dữ liệu:**
- `id` (BIGSERIAL, PK)
- `user_id` (BIGINT, NOT NULL, FK → users, ON DELETE CASCADE)
- `type` (VARCHAR(100), NOT NULL)
  - new_booking, booking_status_changed, new_message, payment_received
- `title` (TEXT)
- `body` (TEXT)
- `payload` (JSONB) - Deep link data
- `is_read` (BOOLEAN, DEFAULT false)
- `sent_at` (TIMESTAMPTZ, NULL) - Thời gian gửi push
- `delivered_at` (TIMESTAMPTZ, NULL) - Thời gian delivered
- `created_at`

**Index:**
- `(user_id, is_read)`
- `(user_id, created_at DESC)` WHERE NOT is_read - **[CẢI TIẾN]** Thông báo chưa đọc

**Payload example:**
```json
{
  "action": "open_booking",
  "booking_id": 123,
  "screen": "BookingDetail"
}
```

---

### 7.3 `audit_logs` - Audit Trail

**Mục đích:** Ghi log hành động quan trọng (admin actions, security events)

**Trường dữ liệu:**
- `id` (BIGSERIAL, PK)
- `actor_user_id` (BIGINT, NULL, FK → users) - NULL = hệ thống
- `action` (VARCHAR(200), NOT NULL)
  - ban_user, verify_provider, resolve_dispute, update_settings
- `object_type` (VARCHAR(100)) - booking, user, provider_profile
- `object_id` (BIGINT)
- `detail` (JSONB) - Dữ liệu trước/sau
- `ip` (VARCHAR(50))
- `user_agent` (TEXT)
- `created_at`

**Index:**
- `(actor_user_id)`
- `(object_type, object_id)`
- `(created_at DESC)` - **[CẢI TIẾN]** Recent logs

**Detail example:**
```json
{
  "before": {"status": "active"},
  "after": {"status": "banned"},
  "reason": "Spam"
}
```

---

### 7.4 `blockchain_transactions` - Blockchain Tracking

**Mục đích:** Theo dõi giao dịch on-chain (escrow, review hash)

**Trường dữ liệu:**
- `id` (BIGSERIAL, PK)
- `tx_hash` (VARCHAR(66), UNIQUE, NOT NULL) - 0x...
- `from_address` (VARCHAR(66), NOT NULL)
- `to_address` (VARCHAR(66), NOT NULL)
- `value` (NUMERIC(36,18)) - Số token (hỗ trợ 18 decimals)
- `token_symbol` (VARCHAR(20)) - ETH, USDT, BNB
- `decimals` (INT) - 18 cho ETH
- `status` (VARCHAR(30), DEFAULT 'pending')
  - **States:** pending, confirmed, failed
- `related_booking_id` (BIGINT, NULL, FK → bookings, ON DELETE SET NULL)
- `payload` (JSONB) - Logs, events từ smart contract
- `block_number` (BIGINT)
- `created_at`
- `confirmed_at` (TIMESTAMPTZ, NULL)

**Index:**
- `(status)`
- `(related_booking_id)`

**Use cases:**
1. **Escrow:** Tạo smart contract khi booking accepted
2. **Release:** Release escrow khi booking completed
3. **Review on-chain:** Lưu hash review lên blockchain (chống giả mạo)

---

### 7.5 `settings` - System Configuration

**Mục đích:** Key-value store cho cấu hình hệ thống

**Trường dữ liệu:**
- `key` (VARCHAR(200), PK) - platform_fee_percent, min_booking_amount
- `value` (JSONB, NOT NULL) - Giá trị (có thể là object/array)
- `description` (TEXT)
- `updated_at`

**Dữ liệu mẫu:**
```
key: 'platform_fee_percent'
value: {"value": 15, "type": "percent"}

key: 'payment_methods'
value: ["momo", "vnpay", "card", "wallet"]

key: 'maintenance_mode'
value: {"enabled": false, "message": ""}
```

**Access:** Cache trong Redis, reload khi có thay đổi

---

## 📊 SƠ ĐỒ QUAN HỆ TỔNG QUAN

```
┌─────────────┐
│    users    │──┐
└─────────────┘  │
       │         │
       ├─────────┼────────┬────────┬────────┬────────┐
       │         │        │        │        │        │
       ↓         ↓        ↓        ↓        ↓        ↓
 user_profiles  wallets  sessions  addresses  user_roles  notifications
                  │
                  ↓
           wallet_transactions
                  │
                  ↓ (related_payment_id)
              payments
                  │
                  ↓ (booking_id)

┌─────────────────────────────────────────────────────┐
│                      BOOKINGS                       │ ← Bảng trung tâm
└─────────────────────────────────────────────────────┘
       │         │           │           │
       ↓         ↓           ↓           ↓
booking_events  reviews   disputes  conversations
                             │            │
                             └────────────┴─→ messages

┌─────────────┐
│   users     │
└─────────────┘
       │ (provider)
       ↓
provider_profiles ──→ provider_services ←── services ←── service_categories
                            │
                            └────→ bookings


RBAC Flow:
users → user_roles → roles → role_permissions → permissions
```

---

## 🔧 INDEX VÀ CONSTRAINTS QUAN TRỌNG

### Indexes cần thiết (chưa nhắc ở trên)

```
users:
  - (email) WHERE email IS NOT NULL
  - (status)
  - (phone, status)

sessions:
  - (user_id, expires_at) WHERE NOT revoked
  - (refresh_token_hash)

bookings:
  - (customer_id, status)
  - (provider_id, status)
  - (scheduled_at)
  - (status, scheduled_at)
  - GIST(location)

provider_profiles:
  - GIST(location)
  - (is_available)
  - (verification_status)

wallet_transactions:
  - (wallet_user_id, created_at DESC)
  - (type)
  - (related_payment_id) WHERE related_payment_id IS NOT NULL

reviews:
  - (reviewee_id, rating)
  - (reviewee_id, created_at DESC)
  - (reviewer_id)

messages:
  - (conversation_id, created_at DESC)
  - (sender_id)
  - (conversation_id, read_at) WHERE read_at IS NULL

notifications:
  - (user_id, is_read)
  - (user_id, created_at DESC) WHERE NOT is_read

audit_logs:
  - (actor_user_id)
  - (object_type, object_id)
  - (created_at DESC)

media:
  - (owner_type, owner_id)
  - (uploaded_by)

addresses:
  - GIST(location)
  - (user_id) WHERE is_default = true (UNIQUE)

conversations:
  - (booking_id) WHERE booking_id IS NOT NULL (UNIQUE)
  - (customer_id)
  - (provider_id)

booking_events:
  - (booking_id, created_at DESC)
```

### Constraints quan trọng

```
bookings:
  - provider_id REFERENCES provider_profiles(user_id)
  - Status transition validation (via trigger)

otp_codes:
  - attempt_count <= 5
  - Code phải được hash

wallets:
  - balance >= 0
  - Optimistic/Pessimistic locking

wallet_transactions:
  - APPEND-ONLY (no UPDATE/DELETE)
  - idempotency_key UNIQUE

payments:
  - UNIQUE (gateway, gateway_tx_id, environment)

addresses:
  - UNIQUE (user_id) WHERE is_default = true

reviews:
  - rating BETWEEN 1 AND 5
  - booking_id UNIQUE
```

---

## 🚀 TRIỂN KHAI VÀ MIGRATION

### Thứ tự tạo bảng (dependencies)

```
1. Bảng không phụ thuộc:
   - users
   - roles
   - permissions
   - service_categories

2. Phụ thuộc users:
   - user_profiles
   - sessions
   - otp_codes
   - wallets
   - provider_profiles
   - addresses

3. Phụ thuộc roles/permissions:
   - user_roles
   - role_permissions

4. Phụ thuộc service_categories:
   - services

5. Phụ thuộc provider_profiles + services:
   - provider_services
   - favorites

6. Phụ thuộc nhiều bảng:
   - bookings (users, provider_profiles, services)
   - payments (bookings - optional)
   - wallet_transactions (wallets, payments)

7. Phụ thuộc bookings:
   - booking_events
   - reviews
   - disputes
   - conversations

8. Phụ thuộc conversations:
   - messages

9. Utilities:
   - media
   - notifications
   - audit_logs
   - blockchain_transactions
   - settings
```

### Seed Data cần thiết

```
1. roles:
   - customer, provider, moderator, super_admin

2. permissions:
   - Danh sách permissions cơ bản

3. role_permissions:
   - Gán quyền mặc định cho từng role

4. service_categories:
   - Các danh mục dịch vụ phổ biến

5. services:
   - Template dịch vụ cơ bản

6. settings:
   - platform_fee_percent: 15
   - min_booking_amount: 50000
   - max_service_radius_m: 50000
```

---

## 📝 TRIGGERS VÀ FUNCTIONS CẦN TRIỂN KHAI

### 1. Auto-update rating cho provider

```
Trigger: AFTER INSERT ON reviews
Action: 
  - Tính AVG(rating), COUNT(*) cho reviewee_id
  - UPDATE provider_profiles SET rating_avg, rating_count
```

### 2. Validate booking status transition

```
Trigger: BEFORE UPDATE OF status ON bookings
Action:
  - Check transition hợp lệ trong booking_status_transitions
  - RAISE EXCEPTION nếu invalid
```

### 3. Auto-log booking events

```
Trigger: AFTER UPDATE OF status ON bookings
Action:
  - INSERT vào booking_events với old/new status
```

### 4. Auto-update conversation metadata

```
Trigger: AFTER INSERT ON messages
Action:
  - UPDATE conversations SET last_message_id, last_message_at, unread_count
```

### 5. Auto-update timestamps

```
Trigger: BEFORE UPDATE ON <all tables>
Action:
  - SET updated_at = NOW()
```

### 6. Enforce addresses default constraint

```
Trigger: BEFORE INSERT/UPDATE ON addresses
Action:
  - Nếu is_default = true
    → Unset các địa chỉ khác của cùng user
```

---

## 🔒 BẢO MẬT VÀ BEST PRACTICES

### Security Checklist

✅ **OTP Security:**
- Hash OTP code (SHA256)
- Rate limiting (5 attempts)
- Cooldown giữa các lần gửi OTP
- Auto cleanup OTP cũ

✅ **Token Security:**
- Hash refresh token trước khi lưu
- Session expiry và revocation
- User agent + IP tracking

✅ **Wallet Security:**
- Optimistic/Pessimistic locking
- Transaction atomicity (BEGIN/COMMIT)
- Immutable ledger (wallet_transactions)
- Idempotency key

✅ **Payment Security:**
- Gateway transaction uniqueness
- Reconciliation flag
- Webhook signature verification (trong code)

✅ **Data Security:**
- Soft delete quan trọng (users, bookings)
- Audit logs cho admin actions
- ON DELETE RESTRICT cho foreign keys quan trọng

### Performance Best Practices

✅ **Indexes:**
- Tất cả foreign keys có index
- Composite index cho query patterns phổ biến
- Partial index cho filtered queries
- GIST index cho PostGIS

✅ **Query Optimization:**
- Pagination: Cursor-based hoặc OFFSET/LIMIT
- N+1 queries: Eager loading
- Heavy aggregations: Materialized views (nếu cần)

✅ **Data Management:**
- Partition cho bảng lớn (bookings, messages, wallet_transactions)
- Archive data cũ (> 2 years)
- Regular VACUUM ANALYZE

✅ **Caching:**
- Redis cache cho:
  - Provider profiles (location, ratings)
  - Service categories/services
  - Settings
  - User sessions

---

##  KẾT LUẬN

Database này được thiết kế để:

✅ **Scalable:** Sẵn sàng cho hàng triệu users và bookings
✅ **Secure:** Bảo mật OTP, wallet, payment transactions
✅ **Auditable:** Tracking đầy đủ mọi thay đổi quan trọng
✅ **Extensible:** Dễ dàng thêm tính năng mới
✅ **Performant:** Indexes và constraints được tối ưu

**28 bảng** được tổ chức thành **7 module** rõ ràng, mỗi module đảm nhiệm một phần nghiệp vụ cụ thể.

---

**Version:** 2.0  
**Last Updated:** 2025-01-16  
**Author:** Local Service Platform Team


