-- Create booking_selected_items table
CREATE TABLE IF NOT EXISTS booking_selected_items (
    id BIGSERIAL PRIMARY KEY,
    booking_id BIGINT NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
    provider_service_item_id BIGINT NOT NULL REFERENCES provider_service_items(id) ON DELETE RESTRICT,
    quantity INT NOT NULL DEFAULT 1,
    unit_price DECIMAL(12, 2) NOT NULL,
    total_price DECIMAL(12, 2) NOT NULL,
    created_at TIMESTAMPTZ(6) NOT NULL DEFAULT NOW(),
    UNIQUE(booking_id, provider_service_item_id)
);

-- Create index
CREATE INDEX IF NOT EXISTS idx_booking_selected_items_booking_id ON booking_selected_items(booking_id);
