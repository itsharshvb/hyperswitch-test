-- Test V2 migration with breaking changes to trigger the migration-compatibility check

ALTER TABLE merchant_account DROP COLUMN IF EXISTS publishable_key;

ALTER TABLE IF EXISTS temp_v2_table RENAME TO renamed_temp_v2_table;

TRUNCATE TABLE IF EXISTS temp_cleanup_table;

ALTER TABLE business_profile ALTER COLUMN profile_name SET NOT NULL;

ALTER TABLE customers DROP COLUMN IF EXISTS phone_country_code;

ALTER TABLE merchant_connector_account DROP CONSTRAINT IF EXISTS some_constraint;

ALTER TABLE merchant_account ALTER COLUMN is_recon_enabled SET DEFAULT true;
