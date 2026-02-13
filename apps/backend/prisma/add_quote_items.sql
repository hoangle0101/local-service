-- Add new columns to service_quotes
ALTER TABLE service_quotes 
ADD COLUMN IF NOT EXISTS surcharge DECIMAL(18, 2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS provider_notes TEXT,
ADD COLUMN IF NOT EXISTS has_changes_from_customer BOOLEAN DEFAULT false;

-- Create quote_items table
CREATE TABLE IF NOT EXISTS quote_items (
    id BIGSERIAL PRIMARY KEY,
    quote_id BIGINT NOT NULL REFERENCES service_quotes(id) ON DELETE CASCADE,
    service_item_id BIGINT REFERENCES provider_service_items(id) ON DELETE SET NULL,
    name VARCHAR(200) NOT NULL,
    description TEXT,
    unit_price DECIMAL(12, 2) NOT NULL,
    quantity INT NOT NULL DEFAULT 1,
    total_price DECIMAL(12, 2) NOT NULL,
    is_custom BOOLEAN DEFAULT false,
    is_from_customer BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ(6) NOT NULL DEFAULT NOW()
);

-- Create index
CREATE INDEX IF NOT EXISTS idx_quote_items_quote_id ON quote_items(quote_id);
