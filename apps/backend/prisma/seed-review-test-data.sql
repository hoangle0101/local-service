-- Seed test data for review feature testing

-- Create test users
INSERT INTO users (email, name, phone, user_type, verified, created_at, updated_at)
VALUES 
  ('reviewer@test.com', 'Test Reviewer', '0900000001', 'customer', true, NOW(), NOW()),
  ('provider@test.com', 'Test Provider', '0900000002', 'provider', true, NOW(), NOW())
ON CONFLICT (email) DO NOTHING;

-- Get user IDs
DO $$
DECLARE
  v_reviewer_id BIGINT;
  v_provider_id BIGINT;
  v_service_id INT;
BEGIN
  SELECT id INTO v_reviewer_id FROM users WHERE email = 'reviewer@test.com';
  SELECT id INTO v_provider_id FROM users WHERE email = 'provider@test.com';
  
  -- Create test service
  INSERT INTO services (name, category_id, provider_id, description, base_price, created_at, updated_at)
  VALUES ('Test Service for Reviews', 1, v_provider_id, 'Test service for review feature', 500000, NOW(), NOW())
  ON CONFLICT DO NOTHING;
  
  SELECT id INTO v_service_id FROM services WHERE name = 'Test Service for Reviews' LIMIT 1;
  
  -- Create test booking
  INSERT INTO bookings (
    customer_id, provider_id, service_id, status, scheduled_at, 
    address_text, estimated_price, actual_price, platform_fee, provider_earning,
    created_at, updated_at
  )
  VALUES (
    v_reviewer_id, v_provider_id, v_service_id, 'completed', NOW() - INTERVAL '7 days',
    'Test Address for Reviews', 500000, 500000, 50000, 450000,
    NOW(), NOW()
  )
  ON CONFLICT DO NOTHING;
  
  RAISE NOTICE 'Test data created successfully!';
  RAISE NOTICE 'Reviewer ID: %', v_reviewer_id;
  RAISE NOTICE 'Provider ID: %', v_provider_id;
  RAISE NOTICE 'Service ID: %', v_service_id;
END $$;
