# OASDiff Configuration Reference

This document provides a comprehensive guide to configuring oasdiff for API breaking change detection in Hyperswitch.

## Configuration Files

OASDiff supports several configuration files to customize breaking change detection:

### 1. Severity Levels Configuration (`--severity-levels`)

File: `.oasdiff-severity-levels.yaml`

Defines custom severity levels for different types of changes.

**Format:**
```yaml
rule-id: SEVERITY_LEVEL
```

**Severity Levels:**
- `ERR` - Error (breaking change)
- `WARN` - Warning (potentially problematic)
- `INFO` - Information (safe change)

**Example:**
```yaml
request-property-became-required: ERR
response-property-added: INFO
endpoint-deprecated: WARN
```

### 2. Error Ignore Configuration (`--err-ignore`)

File: `.oasdiff-err-ignore.yaml`

Specifies which breaking change errors should be ignored.

**Format:**
```yaml
- rule-id
- rule-id:path-pattern
```

**Example:**
```yaml
- api-path-removed-without-deprecation
- request-property-removed:/internal/
- response-property-type-changed:/.*/v1/.*/
```

### 3. Warning Ignore Configuration (`--warn-ignore`)

File: `.oasdiff-warn-ignore.yaml`

Specifies which warnings should be suppressed from output.

**Format:** Same as error ignore configuration.

**Example:**
```yaml
- api-operation-description-changed
- response-property-example-changed
- endpoint-deprecated:/beta/
```

## Command Line Options

### Core Options

| Option | Description | Example |
|--------|-------------|---------|
| `--severity-levels` | Path to severity levels config | `--severity-levels .oasdiff-severity-levels.yaml` |
| `--err-ignore` | Path to error ignore config | `--err-ignore .oasdiff-err-ignore.yaml` |
| `--warn-ignore` | Path to warning ignore config | `--warn-ignore .oasdiff-warn-ignore.yaml` |
| `--fail-on` | Exit with error on this severity level or higher | `--fail-on ERR` |
| `--format` | Output format | `--format json` |

### Filtering Options

| Option | Description | Example |
|--------|-------------|---------|
| `--match-path` | Include only paths matching regex | `--match-path "^/api/v1"` |
| `--unmatch-path` | Exclude paths matching regex | `--unmatch-path "/internal"` |
| `--filter-extension` | Exclude paths with OpenAPI extension | `--filter-extension "x-internal"` |

### Path Manipulation

| Option | Description | Example |
|--------|-------------|---------|
| `--prefix-base` | Add prefix to base spec paths | `--prefix-base "/v1"` |
| `--prefix-revision` | Add prefix to revision spec paths | `--prefix-revision "/v2"` |
| `--strip-prefix-base` | Remove prefix from base spec paths | `--strip-prefix-base "/api"` |
| `--strip-prefix-revision` | Remove prefix from revision spec paths | `--strip-prefix-revision "/api"` |

### Processing Options

| Option | Description | Default |
|--------|-------------|---------|
| `--flatten-allof` | Merge allOf subschemas | false |
| `--flatten-params` | Merge path and operation parameters | false |
| `--include-path-params` | Include path parameter names in matching | false |
| `--case-insensitive-headers` | Case-insensitive header comparison | false |

### Output Options

| Option | Description | Values |
|--------|-------------|--------|
| `--format` | Output format | `text`, `json`, `yaml`, `html`, `markdown`, `githubactions`, `junit`, `singleline`, `markup` |
| `--lang` | Language for output | `en`, `ru`, `pt-br`, `es` |
| `--color` | Colorize output | `auto`, `always`, `never` |
| `--template` | Custom template file | Path to template |

### Deprecation Options

| Option | Description | Default |
|--------|-------------|---------|
| `--deprecation-days-stable` | Min days before removing stable resources | 0 |
| `--deprecation-days-beta` | Min days before removing beta resources | 0 |

## Common Breaking Change Rules

### API Structure Changes
- `api-path-removed-without-deprecation`
- `api-removed-without-deprecation` 
- `api-operation-id-removed`
- `api-security-removed`

### Request Changes
- `request-property-became-required`
- `request-property-removed`
- `request-property-type-changed`
- `request-property-enum-value-removed`
- `request-parameter-became-required`
- `request-parameter-removed`

### Response Changes
- `response-property-removed`
- `response-property-type-changed`
- `response-property-became-optional`
- `response-status-removed`
- `response-header-removed`

### Schema Changes
- `request-body-became-required`
- `response-body-became-optional`
- `api-schema-removed`

## Usage Examples

### Basic Usage
```bash
# Basic breaking change detection
oasdiff breaking base.yaml revision.yaml

# With custom severity levels
oasdiff breaking --severity-levels .oasdiff-severity-levels.yaml base.yaml revision.yaml

# With error ignoring
oasdiff breaking --err-ignore .oasdiff-err-ignore.yaml base.yaml revision.yaml

# Fail on errors only
oasdiff breaking --fail-on ERR base.yaml revision.yaml
```

### Advanced Usage
```bash
# JSON output with custom config
oasdiff breaking \
  --format json \
  --severity-levels .oasdiff-severity-levels.yaml \
  --err-ignore .oasdiff-err-ignore.yaml \
  --warn-ignore .oasdiff-warn-ignore.yaml \
  --fail-on ERR \
  base.yaml revision.yaml

# Filter specific paths
oasdiff breaking \
  --match-path "^/api/v1" \
  --unmatch-path "/internal" \
  base.yaml revision.yaml

# With deprecation rules
oasdiff breaking \
  --deprecation-days-stable 30 \
  --deprecation-days-beta 7 \
  base.yaml revision.yaml
```

### CI/CD Integration
```bash
# For GitHub Actions
oasdiff breaking \
  --format githubactions \
  --fail-on ERR \
  --severity-levels .oasdiff-severity-levels.yaml \
  --err-ignore .oasdiff-err-ignore.yaml \
  base.yaml revision.yaml

# For JUnit reports
oasdiff breaking \
  --format junit \
  --fail-on WARN \
  base.yaml revision.yaml > breaking-changes.xml
```

## Best Practices

### 1. Start Conservative
Begin with strict rules and gradually relax them:
```yaml
# Start with all breaking changes as errors
request-property-became-required: ERR
response-property-removed: ERR
api-path-removed-without-deprecation: ERR
```

### 2. Use Path-Based Rules
Apply different rules to different API sections:
```yaml
# Strict rules for public API
request-property-removed: ERR

# Relaxed rules for internal API  
- request-property-removed:/internal/
```

### 3. Environment-Specific Configs
Use different configs for different environments:
```bash
# Production: strict
oasdiff breaking --err-ignore .oasdiff-err-ignore-prod.yaml

# Development: relaxed  
oasdiff breaking --err-ignore .oasdiff-err-ignore-dev.yaml
```

### 4. Document Suppressions
Always document why rules are ignored:
```yaml
# Temporarily ignore during client library updates
# Remove by: 2024-12-31
# Tracking: HYPER-1234
- request-property-became-required:customer_id
```

### 5. Regular Review
Regularly review and update ignore lists to avoid accumulating technical debt.

## Integration with Hyperswitch Workflow

The current workflow uses these configurations:

```bash
# In .github/workflows/api-compatibility.yml
oasdiff breaking \
  --fail-on ERR \
  --severity-levels .oasdiff-severity-levels.yaml \
  --err-ignore .oasdiff-err-ignore.yaml \
  --warn-ignore .oasdiff-warn-ignore.yaml \
  base-v1-schema.json pr-v1-schema.json
```

This ensures:
- Breaking changes cause the workflow to fail
- Custom severity levels are applied
- Known safe changes are ignored
- Noisy warnings are suppressed

## Troubleshooting

### Common Issues

1. **Config file not found**: Ensure file paths are correct relative to working directory
2. **Rules not applying**: Check rule names match exactly (case-sensitive)
3. **Path patterns not working**: Use proper regex syntax for path matching
4. **Too many warnings**: Use warn-ignore to suppress noise

### Debug Tips

```bash
# Test config with verbose output
oasdiff breaking --format json base.yaml revision.yaml | jq .

# Test path filtering
oasdiff breaking --match-path "/test" base.yaml revision.yaml

# Check rule names
oasdiff breaking --format yaml base.yaml revision.yaml
```