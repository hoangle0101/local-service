-- Reset password for test accounts
-- Password: 123456
-- Hash: bcrypt hash (works with typical bcrypt validators)
UPDATE users 
SET password_hash = '$2b$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcg7b3XeKeUxWdeS86E36CM3/M.' 
WHERE email IN ('reviewer@test.com', 'provider@test.com');

SELECT id, email, phone FROM users WHERE id IN (7, 8);
