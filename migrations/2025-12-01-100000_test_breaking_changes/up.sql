-- Test migration with breaking changes to trigger the migration-compatibility check

-- Breaking change: DROP COLUMN
ALTER TABLE api_keys DROP COLUMN description;

-- Breaking change: DROP TABLE
DROP TABLE IF EXISTS temp_test_table;

-- Breaking change: RENAME COLUMN
ALTER TABLE api_keys RENAME COLUMN prefix TO api_prefix;

-- Breaking change: SET NOT NULL on existing column
ALTER TABLE api_keys ALTER COLUMN expires_at SET NOT NULL;

-- Breaking change: DELETE DATA
DELETE FROM api_keys WHERE last_used IS NULL;

-- Warning: ALTER COLUMN TYPE
ALTER TABLE api_keys ALTER COLUMN NAME TYPE VARCHAR(128);

-- Warning: DROP INDEX
DROP INDEX IF EXISTS test_index;
