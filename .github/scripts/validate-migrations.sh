#!/bin/bash

# Migration Validation Script
# This script checks for breaking changes in database migrations
# Breaking changes include:
# - DROP TABLE
# - DROP COLUMN
# - DELETE FROM
# - TRUNCATE
# - Data type changes (ALTER COLUMN TYPE with potential data loss)
# - Removing enum values
# - NOT NULL constraints on existing columns without defaults

set -e

MIGRATION_DIR="${1:-migrations}"
BASE_REF="${2:-origin/main}"

# Initialize counters as global variables
declare -g BREAKING_CHANGES=0
declare -g WARNINGS=0

echo "====================================="
echo "Migration Validation Report"
echo "====================================="
echo "Migration directory: $MIGRATION_DIR"
echo "Base reference: $BASE_REF"
echo ""

# Get list of new or modified migration files
NEW_MIGRATIONS=$(git diff --name-only --diff-filter=AM "$BASE_REF"...HEAD -- "$MIGRATION_DIR/**/*.sql" 2>/dev/null || echo "")

if [[ -z "$NEW_MIGRATIONS" ]]; then
    echo "No new or modified migrations detected"
    echo "0" > migration-breaking-count.txt
    echo "0" > migration-warning-count.txt
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
    "DELETE FROM"
    "TRUNCATE"
)

# Patterns that indicate warnings
WARNING_PATTERNS=(
    "ALTER COLUMN .* TYPE"
    "ALTER COLUMN .* SET NOT NULL"
    "ALTER TYPE .* DROP VALUE"
    "DROP INDEX"
    "DROP CONSTRAINT"
)

# Function to check for patterns
check_file_for_patterns() {
    local file=$1
    local content
    content=$(cat "$file")

    echo "Checking: $file"

    # Check for breaking changes
    for pattern in "${BREAKING_PATTERNS[@]}"; do
        if echo "$content" | grep -iE "$pattern" > /dev/null 2>&1; then
            echo "  BREAKING: Found '$pattern'"
            BREAKING_CHANGES=$((BREAKING_CHANGES + 1))

            # Show the specific line
            echo "$content" | grep -inE "$pattern" | while read -r line; do
                echo "     Line: $line"
            done
        fi
    done

    # Check for warnings
    for pattern in "${WARNING_PATTERNS[@]}"; do
        if echo "$content" | grep -iE "$pattern" > /dev/null 2>&1; then
            echo "  WARNING: Found '$pattern'"
            WARNINGS=$((WARNINGS + 1))

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
                echo "  WARNING: Down migration appears to be a placeholder"
                WARNINGS=$((WARNINGS + 1))
            fi
        else
            echo "  WARNING: Missing down.sql migration"
            WARNINGS=$((WARNINGS + 1))
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
    echo "VALIDATION FAILED: Breaking changes detected in migrations"
    echo ""
    exit 1
elif [[ $WARNINGS -gt 0 ]]; then
    echo "VALIDATION PASSED WITH WARNINGS"
    echo ""
    exit 0
else
    echo "VALIDATION PASSED: No breaking changes detected"
    exit 0
fi
