-- This file should undo anything in `up.sql`
ALTER TABLE payment_intent ADD COLUMN IF NOT EXISTS payment_method_id VARCHAR(64);

ALTER TABLE payment_intent ADD COLUMN IF NOT EXISTS customer_id VARCHAR(64);