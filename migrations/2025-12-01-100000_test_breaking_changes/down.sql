-- Revert the breaking changes

-- Revert column type change
ALTER TABLE api_keys ALTER COLUMN NAME TYPE VARCHAR(64);

-- Revert SET NOT NULL
ALTER TABLE api_keys ALTER COLUMN expires_at DROP NOT NULL;

-- Revert RENAME COLUMN
ALTER TABLE api_keys RENAME COLUMN api_prefix TO prefix;

-- Revert DROP COLUMN (note: data will be lost)
ALTER TABLE api_keys ADD COLUMN description VARCHAR(256) DEFAULT NULL;
