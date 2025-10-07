-- This file should undo anything in `up.sql`
ALTER TABLE organization ADD COLUMN IF NOT EXISTS organization_name VARCHAR(255);

ALTER TABLE business_profile ADD COLUMN IF NOT EXISTS profile_name VARCHAR(255);
