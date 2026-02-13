// Đây là file "Từ điển Chung" của bạn.
// Khi bạn cần định nghĩa 1 cấu trúc, bạn thêm vào đây.
// Ví dụ:

export interface User {
  id: string;
  phone_number: string;
  full_name: string;
}

export interface Booking {
  id: string;
  status: 'pending' | 'completed' | 'cancelled';
  job_description: string;
}