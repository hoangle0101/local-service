-- Update test user passwords with correct bcrypt hash
UPDATE users 
SET password_hash = '$2b$10$eWWlzFLC5YEw46u8DjIqyO0fVvjf8TZOUjAbEplAQvuIxw1YZuGOa'
WHERE id IN (7, 8);

SELECT id, email, phone, password_hash FROM users WHERE id IN (7, 8);
