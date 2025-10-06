-- Your SQL goes here
-- BREAKING CHANGE: Drop organization_name column from organization table
ALTER TABLE organization DROP COLUMN IF EXISTS organization_name;

-- BREAKING CHANGE: Drop a required column from business_profile
ALTER TABLE business_profile DROP COLUMN IF EXISTS profile_name;
