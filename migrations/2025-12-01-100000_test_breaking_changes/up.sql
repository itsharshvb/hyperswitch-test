-- Test migration with breaking changes to trigger the migration-compatibility check

ALTER TABLE api_keys DROP COLUMN description;

DROP TABLE IF EXISTS temp_test_table;

ALTER TABLE api_keys RENAME COLUMN prefix TO api_prefix;

ALTER TABLE api_keys ALTER COLUMN expires_at SET NOT NULL;

DELETE FROM api_keys WHERE last_used IS NULL;

ALTER TABLE api_keys ALTER COLUMN NAME TYPE VARCHAR(128);

DROP INDEX IF EXISTS test_index;
