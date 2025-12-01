-- Test V2 migration with breaking changes to trigger the migration-compatibility check

-- Breaking change: DROP COLUMN from merchant_account
ALTER TABLE merchant_account DROP COLUMN IF EXISTS publishable_key;

-- Breaking change: RENAME TABLE
ALTER TABLE IF EXISTS temp_v2_table RENAME TO renamed_temp_v2_table;

-- Breaking change: TRUNCATE TABLE
TRUNCATE TABLE IF EXISTS temp_cleanup_table;

-- Breaking change: SET NOT NULL
ALTER TABLE business_profile ALTER COLUMN profile_name SET NOT NULL;

-- Breaking change: DROP COLUMN from customers
ALTER TABLE customers DROP COLUMN IF EXISTS phone_country_code;

-- Warning: DROP CONSTRAINT
ALTER TABLE merchant_connector_account DROP CONSTRAINT IF EXISTS some_constraint;

-- Warning: ALTER DEFAULT
ALTER TABLE merchant_account ALTER COLUMN is_recon_enabled SET DEFAULT true;
