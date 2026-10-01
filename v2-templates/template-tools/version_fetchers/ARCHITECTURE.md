# Version Fetchers - Architecture

Internal design and implementation details.

---

## System Design

### Three-Layer Architecture

```
┌─────────────────────────────────────┐
│     CLI Scripts (fetch_*.py)        │  Argument parsing, CSV input, progress
├─────────────────────────────────────┤
│  Fetcher Classes (PyPIFetcher, etc)│  Ecosystem APIs, normalization, parsing
├─────────────────────────────────────┤
│  Base Infrastructure (BaseFetcher)  │  HTTP, rate limiting, retry logic
└─────────────────────────────────────┘
```

---

## Core Components

### BaseFetcher (Abstract Base)

Provides common HTTP infrastructure:

- **Session Management**: Connection pooling, persistent sessions
- **Rate Limiting**: Token bucket algorithm
- **Retry Logic**: Exponential backoff for 429, 500, 502, 503, 504
- **Timeout Protection**: 5-minute max per request

```python
class BaseFetcher(ABC):
    def __init__(self, base_url, rate_limit, rate_period, timeout=300):
        self.rate_limiter = RateLimiter(max_calls=rate_limit, period=rate_period)
        self.session = requests.Session()
        # Retry strategy configured
```

### Ecosystem Fetchers

Each inherits from `BaseFetcher` and implements:
- `fetch_versions(package_name)` - Get all versions
- `normalize_name(package_name)` - Ecosystem-specific normalization

---

## Ecosystem-Specific Details

### Python (PyPI)
- **API**: `https://pypi.org/pypi/{package}/json`
- **Rate Limits**: None
- **Special**: Filters versions with no release files

### Node.js (npm)
- **API**: `https://registry.npmjs.org/{package}`
- **Rate Limits**: None
- **Special**: URL-encodes scoped packages (`@scope/package`)

### Go (Go Proxy)
- **API**: `https://proxy.golang.org/{module}/@v/list`
- **Rate Limits**: None (proxy), 60/hr (GitHub fallback)
- **Special**: Uppercase → `!lowercase` encoding, dual-source strategy

### Java (Maven)
- **API**: `https://search.maven.org/solrsearch/select`
- **Rate Limits**: None
- **Special**: Auto-discovers groupId from artifactId

### PHP (Packagist)
- **API**: `https://repo.packagist.org/p2/{vendor}/{package}.json`
- **Rate Limits**: None
- **Special**: Converts `vendor__package` → `vendor/package`

### Ruby (RubyGems)
- **API**: `https://rubygems.org/api/v1/versions/{gem}.json`
- **Rate Limits**: None
- **Special**: Optional GitHub fallback for unpublished gems

---

## Rate Limiting

### Token Bucket Algorithm

```python
class RateLimiter:
    def acquire(self, timeout=300):
        # Remove old calls outside window
        # Check if tokens available
        # Wait if necessary (max 5 min)
```

### Ecosystem Limits

| Ecosystem | Limit | Period | Auth Required |
|-----------|-------|--------|---------------|
| PyPI, npm, Maven, Packagist, RubyGems | None | - | No |
| Go Proxy | None | - | No |
| GitHub | 60/5000 | 3600s | Token recommended |

---

## Error Handling

### Error Hierarchy

```python
FetcherError          # Base exception
├── RateLimitError    # Stop execution
├── APIError          # API returned error
└── ValidationError   # Invalid input
```

### Retry Strategy

**Automatic Retry** (with backoff):
- 429 (Rate Limit)
- 500, 502, 503, 504 (Server errors)
- Network timeouts

**No Retry**:
- 404 (Not Found)
- 401, 403 (Auth)
- 400 (Bad Request)

---

## Security Features

### Input Validation
- Ecosystem-specific rules (regex patterns)
- Blocks path traversal (`../`, `..\\`)
- Blocks injection attempts

### Token Masking
```python
def mask_token(token):
    return f"{token[:4]}...{token[-4:]}"
```

### Safe JSON Parsing
- Size limits (10MB default)
- Error handling
- Type validation

---

## Caching Strategy

### Incremental Caching

```python
# Load existing cache
cache = load_cache(output_file)

# Process packages
for package in packages:
    if package in cache:
        continue  # Skip cached
    
    versions = fetcher.fetch_versions(package)
    cache[package] = versions
    
    # Save every 10 packages
    if len(cache) % 10 == 0:
        save_cache(cache, output_file)
```

**Benefits**:
- Resume interrupted runs
- No duplicate work
- Incremental progress

---

## Data Flow

```
1. CSV Input (build_scripts.csv)
   ↓
2. Language Filtering (grep)
   ↓
3. Version Fetching (fetch_*.py)
   ├─ Check cache
   ├─ Validate input
   ├─ Fetch from API
   ├─ Log if no versions
   └─ Save to cache
   ↓
4. Output
   ├─ {ecosystem}_versions.json
   ├─ {ecosystem}_errors.json
   └─ {ecosystem}_no_versions.csv/json
```

---

## Performance

### Typical Benchmarks

| Operation | Time | Notes |
|-----------|------|-------|
| Single fetch | 50-200ms | Without cache |
| Cached lookup | <1ms | In-memory |
| 100 packages | 10-20s | No rate limits |
| 1000 packages | 5-15 min | Varies by ecosystem |

### Optimizations

1. **Connection Pooling** - Reuse HTTP connections
2. **Incremental Caching** - Save every 10 packages
3. **Minimal Parsing** - Extract only needed fields
4. **Smart Rate Limiting** - Only when necessary

---

## Design Patterns

### Template Method
`BaseFetcher` defines algorithm, subclasses implement steps.

### Strategy
Different rate limiting per ecosystem.

### Adapter
Converts ecosystem-specific responses to standard format.

---

## For Maintainers

### Adding New Ecosystem

1. Create fetcher class in `scripts/fetchers/`:
```python
class NewFetcher(BaseFetcher):
    def __init__(self):
        super().__init__(
            base_url='https://api.new-ecosystem.org',
            rate_limit=100,
            rate_period=60
        )
    
    def fetch_versions(self, package_name):
        # Implement ecosystem-specific logic
        pass
```

2. Add validation to `scripts/utils/validation.py`
3. Create main script following existing pattern
4. Update README.md

### Testing

```bash
# Test with small dataset
python fetch_new_versions.py --count 5

# Verify security
grep -r "token" . --exclude-dir=.git | grep -v "***"

# Check outputs
ls -la ../version_data/new_*
```

---

## Future Enhancements

- **Async/Await**: Use `aiohttp` for concurrent requests
- **Database Integration**: Store in CouchDB
- **Dependency Resolution**: Fetch and analyze dependencies
- **Monitoring**: Prometheus metrics

---

## Summary

The system is built on three principles:

1. **Consistency**: Unified interface across ecosystems
2. **Reliability**: Robust error handling and retry logic
3. **Efficiency**: Smart caching and rate limiting

Each fetcher is tailored to its API while sharing common infrastructure.