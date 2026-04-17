# 📍 Nền tảng Kết nối Dịch vụ Địa phương (Local Service Platform)

Chào mừng team! Đây là kho lưu trữ (monorepo) chính cho dự án của chúng ta, bao gồm toàn bộ Backend, Frontend Mobile, và Trang Admin.

## 🚀 Tổng quan Dự án

1.  **Thanh toán Tạm giữ (Escrow):** Tiền của khách được khóa an toàn trong Smart Contract và chỉ tự động nhả cho thợ khi cả hai bên xác nhận công việc hoàn thành.
2.  **Đánh giá Bất biến:** Các đánh giá (review) được ghi lên blockchain, đảm bảo tính minh bạch, không thể sửa đổi hoặc xóa bỏ.
3.  **Chứng chỉ NFT:** Thợ được xác thực sẽ được cấp một NFT chứng chỉ, tăng độ tin cậy.

## 🏗️ Cấu trúc Monorepo

Chúng ta sử dụng **pnpm Workspaces** để quản lý dự án.

````plaintext
local-service-platform/
├── apps/
│   ├── api/          # Backend (NestJS)
│   ├── mobile/       # App di động (React Native)
│   └── admin/        # Trang Admin (Next.js)
│
├── packages/
│   └── types/        # (RẤT QUAN TRỌNG) "Từ điển chung" - Nơi chứa các Interface (types)
│
├── .gitignore
├── package.json      # File package.json GỐC (Quản lý chung)
└── pnpm-workspace.yaml # Định nghĩa không gian làm việc


Chắc chắn rồi. Đây là một file README.md hoàn chỉnh, chuyên nghiệp. Bạn chỉ cần tạo file README.md ở thư mục gốc của dự án (local-service-platform/README.md) và dán nội dung này vào.

Markdown

# 📍 Nền tảng Kết nối Dịch vụ Địa phương (Local Service Platform)

Chào mừng team! Đây là kho lưu trữ (monorepo) chính cho dự án của chúng ta, bao gồm toàn bộ Backend, Frontend Mobile, và Trang Admin.

## 🚀 Tổng quan Dự án

Dự án này là một nền tảng **Web3** kết nối người dân địa phương (cần sửa chữa, dọn dẹp...) với các nhà cung cấp dịch vụ (thợ).

Chúng ta sử dụng **Blockchain (Hợp đồng Thông minh)** để giải quyết vấn đề cốt lõi về **lòng tin**, thông qua:
1.  **Thanh toán Tạm giữ (Escrow):** Tiền của khách được khóa an toàn trong Smart Contract và chỉ tự động nhả cho thợ khi cả hai bên xác nhận công việc hoàn thành.
2.  **Đánh giá Bất biến:** Các đánh giá (review) được ghi lên blockchain, đảm bảo tính minh bạch, không thể sửa đổi hoặc xóa bỏ.
3.  **Chứng chỉ NFT:** Thợ được xác thực sẽ được cấp một NFT chứng chỉ, tăng độ tin cậy.

## 🛠️ Cấu trúc Công nghệ (Tech Stack)

| Hạng mục | Công nghệ | Thư mục | Phụ trách |
| :--- | :--- | :--- | :--- |
| **Backend** | **NestJS** (Node.js, TypeScript) | `apps/api` | @*TênBackendLead* |
| **Mobile App** | **React Native** (TypeScript) | `apps/mobile` | @*TênFrontendLead* |
| **Admin Web** | **Next.js** (TypeScript) | `apps/admin` | @*TênFrontendLead* |
| **Blockchain** | **Solidity** (Hardhat, Ethers.js) | `apps/api` (Tích hợp) | @*TênBlockchainLead* |
| **Database** | **PostgreSQL** + **PostGIS** | `apps/api` | @*TênBackendLead* |
| **Code Chung** | TypeScript Interfaces | `packages/types`| Cả 3 thành viên |

---

## 🏗️ Cấu trúc Monorepo

Chúng ta sử dụng **pnpm Workspaces** để quản lý dự án.

```plaintext
local-service-platform/
├── apps/
│   ├── api/          # Backend (NestJS)
│   ├── mobile/       # App di động (React Native)
│   └── admin/        # Trang Admin (Next.js)
│
├── packages/
│   └── types/        # (RẤT QUAN TRỌNG) "Từ điển chung" - Nơi chứa các Interface (types)
│
├── .gitignore
├── package.json      # File package.json GỐC (Quản lý chung)
└── pnpm-workspace.yaml # Định nghĩa không gian làm việc
Tại sao dùng packages/types? Đây là "Bản Hợp đồng Dữ liệu" của chúng ta. Bất kỳ thay đổi nào về cấu trúc dữ liệu (ví dụ: thêm trường mới vào Booking) phải được định nghĩa ở đây trước. Cả api, mobile, và admin đều import từ đây. Điều này giúp bắt lỗi không đồng bộ giữa Backend và Frontend ngay lập tức.

🚀 Bắt đầu (Getting Started)
Đây là các bước để cài đặt dự án trên máy của bạn.

Yêu cầu: Đã cài đặt pnpm, Node.js (v18+), và Git.

1. Clone (Sao chép) dự án:

Bash

git clone [https://github.com/hoangle0101/local-service-platform.git](https://github.com/hoangle0101/local-service-platform.git)
cd local-service-platform
2. Cài đặt Dependencies: Chạy lệnh này từ thư mục gốc. pnpm sẽ tự động cài đặt cho tất cả các dự án con (api, mobile, admin...).

Bash

pnpm install
3. Cấu hình Môi trường: Bạn cần tạo file .env cho backend.

Bash

# 1. Đi vào thư mục backend
cd apps/backend

# 2. Sao chép file mẫu
cp .env.example .env

# 3. Mở file .env và điền thông tin CSDL (PostgreSQL) của bạn
# (DB_HOST, DB_PORT, DB_USERNAME, DB_PASSWORD...)
🏃‍♂️ Cách Chạy Dự án (Development)
Tất cả các lệnh phải được chạy từ thư mục gốc.

1. Chạy Backend (NestJS):

Bash

# Chạy backend ở chế độ watch
pnpm --filter backend dev
# (Server sẽ chạy ở http://localhost:3000)
2. Chạy Mobile App (React Native):

Bash

# Chạy Metro bundler
pnpm --filter mobile start

# Mở một terminal khác, chạy trên Android hoặc iOS
pnpm --filter mobile android
# HOẶC
pnpm --filter mobile ios
3. Chạy Trang Admin (Next.js):

Bash

pnpm --filter admin dev
# (Web sẽ chạy ở http://localhost:3001)
4. Chạy Cả 3 cùng lúc (Dùng concurrently - nếu đã cài):

Bash

pnpm dev
(Bạn cần định nghĩa script "dev" trong package.json gốc để chạy song song).

🤝 Quy trình Làm việc & Đóng góp (BẮT BUỘC)
Chúng ta sử dụng quy trình Git Flow nghiêm ngặt để đảm bảo chất lượng code.

⚠️ CẤM TUYỆT ĐỐI push code trực tiếp lên nhánh main hoặc develop.

1. Bắt đầu một Task mới:

Bash

# 1. Luôn bắt đầu từ nhánh 'develop' mới nhất
git checkout develop
git pull

# 2. Tạo nhánh mới cho tính năng của bạn
# (feature/ten-tinh-nang HOẶC bugfix/ten-loi)
git checkout -b feature/auth-api
2. Code và Commit: Code trên nhánh feature/auth-api của bạn. Commit thường xuyên.

3. Tạo Pull Request (PR):

Khi hoàn thành, đẩy nhánh của bạn lên:

Bash

git push -u origin feature/auth-api
Lên GitHub, tạo một Pull Request (PR) từ nhánh của bạn vào nhánh develop.

Tag (gắn thẻ) 2 thành viên còn lại vào để review.

4. Review & Merge:

Một task chỉ được coi là "Done" khi PR của nó được ít nhất 1 thành viên khác "Approve" (Chấp thuận).

Sau khi được approve, chủ nhánh (hoặc người review) sẽ "Squash and Merge" PR đó vào develop.
````
