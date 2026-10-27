# Security Best Practices

**Version**: 1.0  
**Date**: 2026-01-13  
**Status**: Production

---

## Overview

This document outlines the security measures implemented in the version_fetchers codebase and provides best practices for secure operation.

---

## Security Features Implemented

### ✅ Input Validation

All package names are validated before processing to prevent:
- **Path traversal attacks** (`../../etc/passwd`)
- **Injection attacks** (SQL, command injection)
- **Invalid characters** (null bytes, control characters)

**Implementation**: `scripts/utils/validation.py`

**Example**:
```python
from utils.validation import validate_package_name, ValidationError

try:
    validated = validate_package_name(
        user_input,
        ecosystem='npm',
        max_length=200
    )
except ValidationError as e:
    print(f"Invalid input: {e}")
    # Handle error appropriately
```

### ✅ Token Masking

GitHub tokens and other credentials are masked in all log output.

**Implementation**: `scripts/utils/security.py`

**Example**:
```python
from utils.security import mask_token

token = os.environ.get('GITHUB_TOKEN')
if token:
    masked = mask_token(token)
    print(f"Using token: {masked}")  # Shows: ghp_****...****
```

**Format**: `ghp_****...****` (first 4 + last 4 characters visible)

### ✅ Safe JSON Parsing

All JSON parsing includes size limits and error handling.

**Implementation**: `scripts/utils/parsing.py`

**Features**:
- Maximum size limits (10MB default)
- Timeout protection
- Graceful error handling

### ✅ Rate Limiting

Built-in rate limiting prevents API abuse and respects service limits.

**Implementation**: `scripts/utils/rate_limiter.py`

**Features**:
- Configurable limits per service
- Automatic backoff
- Thread-safe operation

---

## Security Guidelines

### 1. Environment Variables

**DO**:
```bash
# Store tokens in environment variables
export GITHUB_TOKEN="ghp_your_token_here"

# Use .env files (add to .gitignore)
echo "GITHUB_TOKEN=ghp_..." > .env
```

**DON'T**:
```bash
# Never hardcode tokens in scripts
GITHUB_TOKEN = "ghp_actual_token"  # ❌ NEVER DO THIS

# Never commit tokens to git
git add config_with_token.py  # ❌ NEVER DO THIS
```

### 2. Input Handling

**DO**:
```python
# Always validate user input
validated_name = validate_package_name(user_input, ecosystem='npm')

# Use parameterized queries (if using databases)
cursor.execute("SELECT * FROM packages WHERE name = ?", (validated_name,))
```

**DON'T**:
```python
# Never trust user input directly
package_name = user_input  # ❌ Validate first!

# Never use string concatenation for queries
query = f"SELECT * FROM packages WHERE name = '{user_input}'"  # ❌ SQL injection risk
```

### 3. File Operations

**DO**:
```python
# Validate file paths
from utils.validation import validate_file_path

safe_path = validate_file_path(user_provided_path)
with open(safe_path, 'r') as f:
    data = f.read()
```

**DON'T**:
```python
# Never use user input directly in file paths
with open(user_input, 'r') as f:  # ❌ Path traversal risk
    data = f.read()
```

### 4. Logging

**DO**:
```python
# Mask sensitive data in logs
from utils.security import mask_token

logger.info(f"Using token: {mask_token(token)}")
logger.info(f"Processing package: {validated_name}")
```

**DON'T**:
```python
# Never log sensitive data
logger.info(f"Token: {token}")  # ❌ Exposes credentials
logger.debug(f"Password: {password}")  # ❌ Never log passwords
```

---

## Threat Model

### Threats Mitigated

| Threat | Mitigation | Status |
|--------|-----------|--------|
| Path Traversal | Input validation | ✅ Implemented |
| SQL Injection | Parameterized queries | ✅ Implemented |
| Command Injection | Input validation | ✅ Implemented |
| Token Exposure | Token masking | ✅ Implemented |
| DoS (Large Files) | Size limits | ✅ Implemented |
| Rate Limit Abuse | Rate limiting | ✅ Implemented |

### Residual Risks

| Risk | Severity | Mitigation Plan |
|------|----------|----------------|
| API Key Compromise | High | Rotate keys regularly, use short-lived tokens |
| Network MITM | Medium | Use HTTPS only (enforced) |
| Dependency Vulnerabilities | Medium | Regular `pip audit`, keep dependencies updated |

---

## Security Checklist

### Before Running Fetchers

- [ ] Environment variables set (no hardcoded tokens)
- [ ] `.gitignore` includes `.env` and credential files
- [ ] Input files from trusted sources only
- [ ] Network access restricted (if possible)
- [ ] Logs reviewed for sensitive data

### During Development

- [ ] All user input validated
- [ ] No credentials in code
- [ ] Error messages don't expose internals
- [ ] Dependencies up to date
- [ ] Security utilities used (`validation.py`, `security.py`)

### Before Deployment

- [ ] Security review completed
- [ ] Credentials rotated
- [ ] Logs sanitized
- [ ] Access controls configured
- [ ] Monitoring enabled

---

## Incident Response

### If Credentials Are Exposed

1. **Immediately revoke** the exposed token/key
2. **Generate new** credentials
3. **Update** environment variables
4. **Review** git history for exposure
5. **Rotate** all related credentials
6. **Document** the incident

### If Vulnerability Discovered

1. **Assess** severity and impact
2. **Patch** immediately if critical
3. **Test** the fix thoroughly
4. **Deploy** to all environments
5. **Document** the fix
6. **Review** similar code for same issue

---

## Security Testing

### Manual Testing

```bash
# Test path traversal protection
echo "test,../../etc/passwd,1.0,Python" > test_malicious.csv
python fetch_pypi_versions.py --input test_malicious.csv
# Expected: Validation error, no fetch attempted

# Test token masking
export GITHUB_TOKEN="ghp_test123456789"
python fetch_go_versions_enhanced.py --count 1 2>&1 | grep ghp_
# Expected: Only masked tokens visible (ghp_****...****)

# Test input validation
python -c "
from scripts.utils.validation import validate_package_name, ValidationError
try:
    validate_package_name('../../../etc/passwd', 'npm')
    print('FAIL: Should have raised ValidationError')
except ValidationError:
    print('PASS: Validation blocked malicious input')
"
```

### Automated Testing

```bash
# Run security tests
cd 02-DatabaseAPI/scripts/version_fetchers
python -m pytest tests/security/ -v

# Check for hardcoded secrets
grep -r "ghp_" . --exclude-dir=.git --exclude="*.md"
grep -r "password\s*=" . --exclude-dir=.git --exclude="*.md"

# Dependency vulnerability scan
pip install safety
safety check --file requirements.txt
```

---

## Compliance

### Data Protection

- **No PII collected**: Package names and versions only
- **Audit logs**: Track all no-version packages for review
- **Data retention**: Logs rotated/archived per policy

### Access Control

- **Principle of least privilege**: Minimal permissions required
- **Token scoping**: Use read-only tokens where possible
- **Network isolation**: Restrict outbound connections if possible

---

## Security Contacts

### Reporting Security Issues

**DO NOT** open public GitHub issues for security vulnerabilities.

**Instead**:
1. Email security contact (if configured)
2. Use private vulnerability reporting
3. Provide detailed description and reproduction steps

### Security Updates

- Monitor dependency advisories
- Subscribe to security mailing lists
- Review CVE databases regularly

---

## Security Utilities Reference

### validation.py

```python
# Package name validation
validate_package_name(name, ecosystem, max_length)

# File path validation
validate_file_path(path, max_length)

# URL validation
validate_url(url, allowed_schemes)
```

### security.py

```python
# Token masking
mask_token(token, visible_chars=4)

# Sanitize log messages
sanitize_log_message(message)
```

### parsing.py

```python
# Safe JSON parsing
safe_json_parse(data, max_size_mb=10)

# Safe file reading
safe_read_file(path, max_size_mb=10)
```

---

## Best Practices Summary

### ✅ DO

- Validate all input
- Mask all credentials
- Use environment variables
- Log security events
- Keep dependencies updated
- Use HTTPS only
- Implement rate limiting
- Handle errors gracefully

### ❌ DON'T

- Trust user input
- Hardcode credentials
- Log sensitive data
- Ignore validation errors
- Use outdated dependencies
- Allow unlimited requests
- Expose internal errors
- Skip security reviews

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-01-13 | Initial security documentation |

---

## Additional Resources

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [CWE Top 25](https://cwe.mitre.org/top25/)
- [Python Security Best Practices](https://python.readthedocs.io/en/stable/library/security_warnings.html)
- [GitHub Token Security](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure)

---

## Conclusion

Security is an ongoing process. This document provides the foundation, but regular reviews, updates, and vigilance are essential for maintaining a secure codebase.

**Remember**: Security is everyone's responsibility.