#!/bin/bash

# generate-compatibility-report.sh
# Enhanced compatibility report generation for Hyperswitch API validation
# Creates structured markdown reports with detailed change analysis

set -euo pipefail

# Input files (with defaults)
V1_BREAKING_REPORT="${V1_BREAKING_REPORT:-v1-breaking-report.txt}"
V2_BREAKING_REPORT="${V2_BREAKING_REPORT:-v2-breaking-report.txt}"
V1_DETAILED_DIFF="${V1_DETAILED_DIFF:-v1-detailed-diff.txt}"
V2_DETAILED_DIFF="${V2_DETAILED_DIFF:-v2-detailed-diff.txt}"

# Helper functions
count_file_issues() {
    local file="$1"
    local pattern="${2:-.*}"
    local count
    
    if [[ -f "$file" ]] && [[ -s "$file" ]]; then
        count=$(grep -c "$pattern" "$file" 2>/dev/null)
        # Ensure we return a valid number
        if [[ "$count" =~ ^[0-9]+$ ]]; then
            echo "$count"
        else
            echo "0"
        fi
    else
        echo "0"
    fi
}


# Count different types of issues - count unique error lines starting with "error"
V1_BREAKING_COUNT=$(grep -c "^error " "$V1_BREAKING_REPORT" 2>/dev/null) || V1_BREAKING_COUNT=0
V2_BREAKING_COUNT=$(grep -c "^error " "$V2_BREAKING_REPORT" 2>/dev/null) || V2_BREAKING_COUNT=0

# Ensure variables are numeric
V1_BREAKING_COUNT=${V1_BREAKING_COUNT:-0}
V2_BREAKING_COUNT=${V2_BREAKING_COUNT:-0}
TOTAL_BREAKING=$((V1_BREAKING_COUNT + V2_BREAKING_COUNT))


# Count changes from detailed diffs and breaking reports
# For removed endpoints, check both diff and breaking reports (api-path-removed patterns)
V1_NEW_ENDPOINTS=$(count_file_issues "$V1_DETAILED_DIFF" "added.*path")
V2_NEW_ENDPOINTS=$(count_file_issues "$V2_DETAILED_DIFF" "added.*path")
V1_NEW_ENDPOINTS=${V1_NEW_ENDPOINTS:-0}
V2_NEW_ENDPOINTS=${V2_NEW_ENDPOINTS:-0}
TOTAL_NEW_ENDPOINTS=$((V1_NEW_ENDPOINTS + V2_NEW_ENDPOINTS))

# Check for removed endpoints - use multiple patterns to catch different formats
# Count from each file separately and sum them
V1_REMOVED_ENDPOINTS=0
if [[ -f "$V1_BREAKING_REPORT" ]]; then
    COUNT=$(grep -c "api-path-removed\|deleted.*path\|removed.*endpoint" "$V1_BREAKING_REPORT" 2>/dev/null) || COUNT=0
    V1_REMOVED_ENDPOINTS=$((V1_REMOVED_ENDPOINTS + COUNT))
fi
if [[ -f "$V1_DETAILED_DIFF" ]]; then
    COUNT=$(grep -c "deleted.*path\|removed.*endpoint" "$V1_DETAILED_DIFF" 2>/dev/null) || COUNT=0
    V1_REMOVED_ENDPOINTS=$((V1_REMOVED_ENDPOINTS + COUNT))
fi

V2_REMOVED_ENDPOINTS=0
if [[ -f "$V2_BREAKING_REPORT" ]]; then
    COUNT=$(grep -c "api-path-removed\|deleted.*path\|removed.*endpoint" "$V2_BREAKING_REPORT" 2>/dev/null) || COUNT=0
    V2_REMOVED_ENDPOINTS=$((V2_REMOVED_ENDPOINTS + COUNT))
fi
if [[ -f "$V2_DETAILED_DIFF" ]]; then
    COUNT=$(grep -c "deleted.*path\|removed.*endpoint" "$V2_DETAILED_DIFF" 2>/dev/null) || COUNT=0
    V2_REMOVED_ENDPOINTS=$((V2_REMOVED_ENDPOINTS + COUNT))
fi

TOTAL_REMOVED_ENDPOINTS=$((V1_REMOVED_ENDPOINTS + V2_REMOVED_ENDPOINTS))

V1_MODIFIED_ENDPOINTS=$(count_file_issues "$V1_DETAILED_DIFF" "modified.*path")
V2_MODIFIED_ENDPOINTS=$(count_file_issues "$V2_DETAILED_DIFF" "modified.*path")
V1_MODIFIED_ENDPOINTS=${V1_MODIFIED_ENDPOINTS:-0}
V2_MODIFIED_ENDPOINTS=${V2_MODIFIED_ENDPOINTS:-0}
TOTAL_MODIFIED_ENDPOINTS=$((V1_MODIFIED_ENDPOINTS + V2_MODIFIED_ENDPOINTS))

# Start generating the report
cat << EOF
## Summary

| Metric | V1 API | V2 API | Total |
|--------|--------|--------|-------|
| Breaking Changes | $V1_BREAKING_COUNT | $V2_BREAKING_COUNT | $TOTAL_BREAKING |
| New Endpoints | $V1_NEW_ENDPOINTS | $V2_NEW_ENDPOINTS | $TOTAL_NEW_ENDPOINTS |
| Removed Endpoints | $V1_REMOVED_ENDPOINTS | $V2_REMOVED_ENDPOINTS | $TOTAL_REMOVED_ENDPOINTS |
| Modified Endpoints | $V1_MODIFIED_ENDPOINTS | $V2_MODIFIED_ENDPOINTS | $TOTAL_MODIFIED_ENDPOINTS |

> **Note**: Breaking changes are endpoint removals or incompatible modifications. New endpoints and compatible modifications are not breaking.

EOF

# Overall status
if [[ $TOTAL_BREAKING -gt 0 ]]; then
    cat << EOF
### Status: BREAKING CHANGES DETECTED

This change introduces breaking changes that will affect existing API clients.

EOF
else
    cat << EOF
### Status: ALL CHECKS PASSED

This change is backward compatible.

EOF
fi

# Breaking Changes Section
if [[ $TOTAL_BREAKING -gt 0 ]]; then
    cat << EOF
---

## Breaking Changes Detected

EOF
    
    if [[ $V1_BREAKING_COUNT -gt 0 ]]; then
        cat << EOF
### V1 API Breaking Changes ($V1_BREAKING_COUNT issues)

EOF
        if [[ -f "$V1_BREAKING_REPORT" ]] && [[ -s "$V1_BREAKING_REPORT" ]]; then
            # Show breaking changes with proper formatting
            cat "$V1_BREAKING_REPORT"
        fi
        echo ""
    fi
    
    if [[ $V2_BREAKING_COUNT -gt 0 ]]; then
        cat << EOF
### V2 API Breaking Changes ($V2_BREAKING_COUNT issues)

EOF
        if [[ -f "$V2_BREAKING_REPORT" ]] && [[ -s "$V2_BREAKING_REPORT" ]]; then
            # Show breaking changes with proper formatting
            cat "$V2_BREAKING_REPORT"
        fi
        echo ""
    fi
fi

# API Changes Section
if [[ $TOTAL_NEW_ENDPOINTS -gt 0 ]] || [[ $TOTAL_REMOVED_ENDPOINTS -gt 0 ]] || [[ $TOTAL_MODIFIED_ENDPOINTS -gt 0 ]]; then
    cat << EOF
---

## API Changes

EOF
    
    if [[ $TOTAL_NEW_ENDPOINTS -gt 0 ]]; then
        cat << EOF
### New Endpoints ($TOTAL_NEW_ENDPOINTS)

These are safe, backward-compatible additions:

EOF
        
        # Extract new endpoints from diff reports
        for version in "V1" "V2"; do
            local diff_file="$([[ $version == "V1" ]] && echo "$V1_DETAILED_DIFF" || echo "$V2_DETAILED_DIFF")"
            local count="$([[ $version == "V1" ]] && echo "$V1_NEW_ENDPOINTS" || echo "$V2_NEW_ENDPOINTS")"
            
            if [[ $count -gt 0 ]] && [[ -f "$diff_file" ]]; then
                echo "**$version API:**"
                grep "added.*path" "$diff_file" 2>/dev/null | head -5 | while IFS= read -r line; do
                    # Extract method and path from oasdiff output
                    if [[ $line =~ method\ \'([^\']+)\'.*path\ \'([^\']+)\' ]]; then
                        method="${BASH_REMATCH[1]}"
                        path="${BASH_REMATCH[2]}"
                        echo "- **$method** \`$path\`"
                    else
                        echo "- $line"
                    fi
                done
                
                if [[ $count -gt 5 ]]; then
                    echo "- *... and $((count - 5)) more endpoints*"
                fi
                echo ""
            fi
        done
    fi
    
    if [[ $TOTAL_REMOVED_ENDPOINTS -gt 0 ]]; then
        cat << EOF
### Removed Endpoints ($TOTAL_REMOVED_ENDPOINTS) - BREAKING

These endpoint removals will break existing clients:

EOF
        
        for version in "V1" "V2"; do
            local diff_file="$([[ $version == "V1" ]] && echo "$V1_DETAILED_DIFF" || echo "$V2_DETAILED_DIFF")"
            local count="$([[ $version == "V1" ]] && echo "$V1_REMOVED_ENDPOINTS" || echo "$V2_REMOVED_ENDPOINTS")"
            
            if [[ $count -gt 0 ]] && [[ -f "$diff_file" ]]; then
                echo "**$version API:**"
                grep "deleted.*path" "$diff_file" 2>/dev/null | head -5 | while IFS= read -r line; do
                    if [[ $line =~ method\ \'([^\']+)\'.*path\ \'([^\']+)\' ]]; then
                        method="${BASH_REMATCH[1]}"
                        path="${BASH_REMATCH[2]}"
                        echo "- **$method** \`$path\` (BREAKING)"
                    else
                        echo "- $line (BREAKING)"
                    fi
                done
                
                if [[ $count -gt 5 ]]; then
                    echo "- *... and $((count - 5)) more endpoints*"
                fi
                echo ""
            fi
        done
    fi
    
    if [[ $TOTAL_MODIFIED_ENDPOINTS -gt 0 ]]; then
        cat << EOF
### Modified Endpoints ($TOTAL_MODIFIED_ENDPOINTS)

These endpoints have been changed (review for breaking changes):

EOF
        
        for version in "V1" "V2"; do
            local diff_file="$([[ $version == "V1" ]] && echo "$V1_DETAILED_DIFF" || echo "$V2_DETAILED_DIFF")"
            local count="$([[ $version == "V1" ]] && echo "$V1_MODIFIED_ENDPOINTS" || echo "$V2_MODIFIED_ENDPOINTS")"
            
            if [[ $count -gt 0 ]] && [[ -f "$diff_file" ]]; then
                echo "**$version API:**"
                grep "modified.*path" "$diff_file" 2>/dev/null | head -5 | while IFS= read -r line; do
                    if [[ $line =~ method\ \'([^\']+)\'.*path\ \'([^\']+)\' ]]; then
                        method="${BASH_REMATCH[1]}"
                        path="${BASH_REMATCH[2]}"
                        echo "- **$method** \`$path\`"
                    else
                        echo "- $line"
                    fi
                done
                
                if [[ $count -gt 5 ]]; then
                    echo "- *... and $((count - 5)) more endpoints*"
                fi
                echo ""
            fi
        done
    fi
fi



# Footer
cat << EOF

Generated at: $(date)
EOF