#!/bin/bash

# Migration Validation Script
# This script checks for breaking changes in database migrations
# Breaking changes include:
# - DROP TABLE
# - DROP COLUMN
# - Data type changes (ALTER COLUMN TYPE with potential data loss)
# - Removing enum values
# - NOT NULL constraints on existing columns without defaults

set -e

MIGRATION_DIR="${1:-migrations}"
BASE_REF="${2:-origin/main}"
BREAKING_CHANGES=0
WARNINGS=0

echo "====================================="
echo "Migration Validation Report"
echo "====================================="
echo "Migration directory: $MIGRATION_DIR"
echo "Base reference: $BASE_REF"
echo ""

# Get list of new or modified migration files
NEW_MIGRATIONS=$(git diff --name-only --diff-filter=AM "$BASE_REF"...HEAD -- "$MIGRATION_DIR/**/*.sql" 2>/dev/null || echo "")

if [[ -z "$NEW_MIGRATIONS" ]]; then
    echo "✅ No new or modified migrations detected"
    exit 0
fi

echo "Analyzing migrations for breaking changes..."
echo ""

# Patterns that indicate breaking changes
BREAKING_PATTERNS=(
    "DROP TABLE"
    "DROP COLUMN"
    "ALTER COLUMN .* DROP DEFAULT"
    "ALTER TYPE .* RENAME VALUE"
)

# Patterns that indicate warnings
WARNING_PATTERNS=(
    "ALTER COLUMN .* TYPE"
    "ALTER COLUMN .* SET NOT NULL"
    "ALTER TYPE .* DROP VALUE"
    "DELETE FROM"
    "TRUNCATE"
    "DROP INDEX"
    "DROP CONSTRAINT"
)

# Function to check for patterns
check_file_for_patterns() {
    local file=$1
    local content
    content=$(cat "$file")

    echo "📄 Checking: $file"

    # Check for breaking changes
    for pattern in "${BREAKING_PATTERNS[@]}"; do
        if echo "$content" | grep -iE "$pattern" > /dev/null 2>&1; then
            echo "  ❌ BREAKING: Found '$pattern'"
            ((BREAKING_CHANGES++))

            # Show the specific line
            echo "$content" | grep -inE "$pattern" | while read -r line; do
                echo "     Line: $line"
            done
        fi
    done

    # Check for warnings
    for pattern in "${WARNING_PATTERNS[@]}"; do
        if echo "$content" | grep -iE "$pattern" > /dev/null 2>&1; then
            echo "  ⚠️  WARNING: Found '$pattern'"
            ((WARNINGS++))

            # Show the specific line
            echo "$content" | grep -inE "$pattern" | while read -r line; do
                echo "     Line: $line"
            done
        fi
    done

    # Check for missing down migration
    if [[ "$file" == *"/up.sql" ]]; then
        down_file="${file%up.sql}down.sql"
        if [[ -f "$down_file" ]]; then
            down_content=$(cat "$down_file")
            # Check if down migration is just a placeholder
            if echo "$down_content" | grep -iE "^[[:space:]]*(--|/\*).*undo|^[[:space:]]*SELECT[[:space:]]+1[[:space:]]*;" > /dev/null; then
                echo "  ⚠️  WARNING: Down migration appears to be a placeholder"
                ((WARNINGS++))
            fi
        else
            echo "  ⚠️  WARNING: Missing down.sql migration"
            ((WARNINGS++))
        fi
    fi

    echo ""
}

# Process each migration file
while IFS= read -r file; do
    if [[ -n "$file" ]]; then
        check_file_for_patterns "$file"
    fi
done <<< "$NEW_MIGRATIONS"

# Generate summary
echo "====================================="
echo "Validation Summary"
echo "====================================="
echo "Files analyzed: $(echo "$NEW_MIGRATIONS" | wc -l | tr -d ' ')"
echo "Breaking changes: $BREAKING_CHANGES"
echo "Warnings: $WARNINGS"
echo ""

# Export results
echo "$BREAKING_CHANGES" > migration-breaking-count.txt
echo "$WARNINGS" > migration-warning-count.txt

if [[ $BREAKING_CHANGES -gt 0 ]]; then
    echo "❌ VALIDATION FAILED: Breaking changes detected in migrations"
    echo ""
    echo "Breaking changes can cause:"
    echo "  - Data loss in production databases"
    echo "  - Application downtime during deployment"
    echo "  - Failed rollbacks"
    echo ""
    echo "Please consider:"
    echo "  - Using backward-compatible changes (ADD COLUMN, CREATE TABLE)"
    echo "  - Creating a data migration plan before structural changes"
    echo "  - Coordinating with DevOps for blue-green deployment"
    echo "  - Adding proper down migrations for rollback support"
    exit 1
elif [[ $WARNINGS -gt 0 ]]; then
    echo "⚠️  VALIDATION PASSED WITH WARNINGS"
    echo ""
    echo "Please review the warnings and ensure:"
    echo "  - Type changes are backward compatible"
    echo "  - NOT NULL constraints have appropriate defaults"
    echo "  - Data migrations are properly tested"
    echo "  - Down migrations are complete and tested"
    exit 0
else
    echo "✅ VALIDATION PASSED: No breaking changes detected"
    exit 0
fi
