-- Your SQL goes here
-- BREAKING CHANGE: Drop payment_method_id column which is a critical identifier
ALTER TABLE payment_intent DROP COLUMN IF EXISTS payment_method_id;

-- BREAKING CHANGE: Drop customer_id column
ALTER TABLE payment_intent DROP COLUMN IF EXISTS customer_id;