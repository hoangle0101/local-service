-- Update booking 2 to completed status
UPDATE bookings SET status = 'completed' WHERE id = 2;

-- Verify the update
SELECT id, code, status, created_at FROM bookings WHERE id = 2;
