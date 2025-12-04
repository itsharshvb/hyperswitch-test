-- Revert V2 breaking changes

-- Revert ALTER DEFAULT
ALTER TABLE merchant_account ALTER COLUMN is_recon_enabled DROP DEFAULT;

-- Revert SET NOT NULL
ALTER TABLE business_profile ALTER COLUMN profile_name DROP NOT NULL;

-- Revert RENAME TABLE
ALTER TABLE IF EXISTS renamed_temp_v2_table RENAME TO temp_v2_table;

-- Revert DROP COLUMN (note: data will be lost)
ALTER TABLE merchant_account ADD COLUMN IF NOT EXISTS publishable_key VARCHAR(128);
ALTER TABLE customers ADD COLUMN IF NOT EXISTS phone_country_code VARCHAR(10);
