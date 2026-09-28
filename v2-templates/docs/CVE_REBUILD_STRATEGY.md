# CVE Tracking and Rebuild Strategy

## The Log4j Problem

In December 2021, CVE-2021-44228 (Log4Shell) demonstrated the catastrophic impact of vulnerabilities in transitive dependencies:

```
Your Application
└── Framework A
    └── Logging Library B
        └── log4j-core 2.14.1  ← CVE-2021-44228 (CRITICAL)
```

Most organizations:
1. Didn't know they had Log4j (it was 3 levels deep)
2. Had no inventory of which artifacts contained it
3. Couldn't quickly determine what needed rebuilding
4. Had no automated rebuild pipeline

**Our goal**: Never be in this situation for our wheel builds.

## The Wheel Equivalent

For ppc64le Python wheels, the same pattern exists:

```
numpy-1.26.0-cp311-linux_ppc64le.whl
├── numpy/_core/_multiarray_umath.cpython-311-ppc64le-linux-gnu.so
│   └── links to: libopenblas.so.0 (bundled)
│       └── links to: libgfortran.so.5 (bundled)
│           └── links to: libquadmath.so.0 (bundled)
└── numpy.libs/
    ├── libopenblas64_p-abc123.so  ← From OpenBLAS 0.3.24
    ├── libgfortran-def456.so      ← From GCC 11.4.0
    └── libquadmath-ghi789.so      ← From GCC 11.4.0
```

If OpenBLAS 0.3.24 has a CVE, which wheels need rebuilding? How do we know?

## Required Capabilities

### 1. Component Inventory Database

Every wheel we build must be registered with its full component manifest:

```
┌─────────────────────────────────────────────────────────────────────┐
│                    ARTIFACT REGISTRY DATABASE                        │
├─────────────────────────────────────────────────────────────────────┤
│ artifact_id    │ component_purl                    │ version        │
├────────────────┼───────────────────────────────────┼────────────────┤
│ numpy-1.26.0   │ pkg:pypi/numpy                    │ 1.26.0         │
│ numpy-1.26.0   │ pkg:generic/libopenblas           │ 0.3.24         │
│ numpy-1.26.0   │ pkg:rpm/redhat/libgfortran        │ 11.4.1-3.el9   │
│ numpy-1.26.0   │ pkg:rpm/redhat/libquadmath        │ 11.4.1-3.el9   │
│ scipy-1.11.0   │ pkg:pypi/scipy                    │ 1.11.0         │
│ scipy-1.11.0   │ pkg:generic/libopenblas           │ 0.3.24         │  ← Same!
│ scipy-1.11.0   │ pkg:rpm/redhat/libgfortran        │ 11.4.1-3.el9   │
│ ...            │ ...                               │ ...            │
└─────────────────────────────────────────────────────────────────────┘
```

**Query**: "Which artifacts contain libopenblas 0.3.24?"
**Result**: numpy-1.26.0, scipy-1.11.0, ...

### 2. CVE Monitoring Service

Continuously monitor vulnerability databases for components we've shipped:

```
┌─────────────────────────────────────────────────────────────────────┐
│                     CVE MONITORING PIPELINE                          │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐          │
│  │     NVD      │    │     OSV      │    │   GitHub     │          │
│  │  (National   │    │  (Open Source│    │  Advisories  │          │
│  │   Vuln DB)   │    │   Vuln DB)   │    │              │          │
│  └──────┬───────┘    └──────┬───────┘    └──────┬───────┘          │
│         │                   │                   │                   │
│         └─────────────┬─────┴───────────────────┘                   │
│                       ▼                                              │
│              ┌────────────────┐                                      │
│              │  CVE Matcher   │                                      │
│              │  (grype, osv-  │                                      │
│              │   scanner)     │                                      │
│              └────────┬───────┘                                      │
│                       │                                              │
│                       ▼                                              │
│         ┌─────────────────────────┐                                  │
│         │  Match against our      │                                  │
│         │  component inventory    │                                  │
│         └─────────────┬───────────┘                                  │
│                       │                                              │
│                       ▼                                              │
│         ┌─────────────────────────┐                                  │
│         │  ALERT: Artifacts       │                                  │
│         │  requiring rebuild      │                                  │
│         └─────────────────────────┘                                  │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### 3. Rebuild Trigger System

When a CVE is detected, automatically determine what needs rebuilding:

```python
def find_affected_artifacts(cve_id: str) -> list[ArtifactRebuild]:
    """
    Given a CVE, find all artifacts that need rebuilding.

    Example: CVE-2024-XXXX affects libopenblas < 0.3.25
    """
    # 1. Get affected component from CVE data
    affected = get_cve_affected_components(cve_id)
    # Returns: [{"purl": "pkg:generic/libopenblas", "version_range": "< 0.3.25"}]

    # 2. Query our artifact registry
    affected_artifacts = []
    for component in affected:
        artifacts = registry.query(
            component_purl=component['purl'],
            version_match=component['version_range']
        )
        affected_artifacts.extend(artifacts)

    # 3. Determine rebuild strategy for each
    rebuilds = []
    for artifact in affected_artifacts:
        rebuilds.append(ArtifactRebuild(
            artifact_id=artifact.id,
            reason=f"CVE fix: {cve_id}",
            component_to_update=component['purl'],
            target_version=get_fixed_version(component),
            priority=get_cve_severity(cve_id),
            rebuild_script=artifact.build_script,
        ))

    return rebuilds
```

### 4. Version Numbering for Security Rebuilds

When rebuilding for CVE fixes without upstream changes, we need a versioning scheme:

#### Option A: Build Number Suffix
```
numpy-1.26.0-cp311-linux_ppc64le.whl           # Original
numpy-1.26.0+ppc64le.1-cp311-linux_ppc64le.whl # Security rebuild 1
numpy-1.26.0+ppc64le.2-cp311-linux_ppc64le.whl # Security rebuild 2
```

**Pros**: Clear lineage, PEP 440 compliant
**Cons**: pip may not upgrade to local version automatically

#### Option B: Date-Based Suffix
```
numpy-1.26.0-cp311-linux_ppc64le.whl              # Original
numpy-1.26.0.post20240115-cp311-linux_ppc64le.whl # Security rebuild
```

**Pros**: PEP 440 compliant, pip will see as newer
**Cons**: Less clear what changed

#### Option C: Security Epoch (Recommended)
```
numpy-1.26.0-cp311-linux_ppc64le.whl           # Original (epoch 0)
numpy-1.26.0.1-cp311-linux_ppc64le.whl         # Security rebuild (epoch 1)
numpy-1.26.0.2-cp311-linux_ppc64le.whl         # Security rebuild (epoch 2)
```

**Pros**: Simple, pip upgrades correctly, clear security lineage
**Cons**: Could conflict with upstream micro versions

#### Recommended Approach: Metadata + Local Version

```python
SECURITY_REBUILD_VERSION = "1.26.0+security.1"

# In wheel METADATA:
Version: 1.26.0+security.1

# Plus custom metadata:
X-Security-Rebuild: 1
X-Security-CVE: CVE-2024-XXXX
X-Security-Date: 2024-01-15
X-Original-Version: 1.26.0
```

### 5. Rebuild Dependency Resolution

The tricky part: rebuilding may cascade.

```
Scenario: OpenSSL CVE requires update from 3.0.12 to 3.0.13

Affected wheels (direct bundling):
├── cryptography-41.0.0  ← bundles libssl.so
├── pyopenssl-23.0.0     ← bundles libssl.so
└── urllib3-2.0.0        ← bundles libssl.so (in some builds)

Affected wheels (transitive):
├── requests-2.31.0      ← depends on urllib3
├── httpx-0.25.0         ← depends on httpcore → h11 → ...
└── aiohttp-3.9.0        ← depends on cryptography
```

**Resolution Strategy**:

```python
def plan_cascade_rebuild(initial_artifacts: list[str]) -> RebuildPlan:
    """
    Given initially affected artifacts, compute full rebuild order.
    """
    graph = DependencyGraph.load()

    # Find all artifacts that depend on affected ones
    cascade = set(initial_artifacts)
    frontier = set(initial_artifacts)

    while frontier:
        next_frontier = set()
        for artifact in frontier:
            dependents = graph.get_dependents(artifact)
            for dep in dependents:
                if dep not in cascade:
                    cascade.add(dep)
                    next_frontier.add(dep)
        frontier = next_frontier

    # Topological sort for correct build order
    build_order = graph.topological_sort(cascade)

    return RebuildPlan(
        total_artifacts=len(cascade),
        build_order=build_order,
        estimated_time=estimate_build_time(build_order),
    )
```

## Implementation Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                     CVE REBUILD SYSTEM                               │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌────────────────┐                                                  │
│  │  Build Script  │──────┐                                          │
│  │  (python.sh)   │      │                                          │
│  └────────────────┘      │                                          │
│                          ▼                                          │
│                 ┌─────────────────┐                                  │
│                 │  SBOM Generator │                                  │
│                 │  (wheel_sbom.py)│                                  │
│                 └────────┬────────┘                                  │
│                          │                                          │
│                          ▼                                          │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │                 ARTIFACT REGISTRY                            │   │
│  │  ┌──────────────┬──────────────┬──────────────────────────┐ │   │
│  │  │ artifact_id  │ sbom_path    │ components (jsonb)       │ │   │
│  │  ├──────────────┼──────────────┼──────────────────────────┤ │   │
│  │  │ numpy-1.26.0 │ /sbom/np.json│ [libopenblas, libgfort.] │ │   │
│  │  └──────────────┴──────────────┴──────────────────────────┘ │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                          │                                          │
│                          │ Query                                    │
│                          ▼                                          │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │                 CVE MONITOR (cron job)                       │   │
│  │                                                              │   │
│  │  1. Fetch new CVEs from NVD/OSV/GitHub                      │   │
│  │  2. Match against component inventory                        │   │
│  │  3. Generate rebuild tickets                                 │   │
│  │  4. (Optional) Auto-trigger rebuilds                        │   │
│  └──────────────────────────┬──────────────────────────────────┘   │
│                             │                                       │
│                             ▼                                       │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │                 REBUILD QUEUE                                │   │
│  │                                                              │   │
│  │  ┌────────────┬──────────┬─────────┬───────────────────┐   │   │
│  │  │ artifact   │ cve      │priority │ status            │   │   │
│  │  ├────────────┼──────────┼─────────┼───────────────────┤   │   │
│  │  │numpy-1.26.0│CVE-2024-X│CRITICAL │ rebuilding        │   │   │
│  │  │scipy-1.11.0│CVE-2024-X│CRITICAL │ queued            │   │   │
│  │  └────────────┴──────────┴─────────┴───────────────────┘   │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

## Database Schema

```sql
-- Core artifact registry
CREATE TABLE artifacts (
    id SERIAL PRIMARY KEY,
    artifact_name VARCHAR(255) NOT NULL,       -- e.g., "numpy"
    artifact_version VARCHAR(64) NOT NULL,     -- e.g., "1.26.0"
    wheel_filename VARCHAR(512) NOT NULL,
    sbom_path VARCHAR(512),
    build_date TIMESTAMP DEFAULT NOW(),
    build_script VARCHAR(255),
    security_rebuild_number INTEGER DEFAULT 0,
    UNIQUE(artifact_name, artifact_version, security_rebuild_number)
);

-- Components bundled in each artifact
CREATE TABLE artifact_components (
    id SERIAL PRIMARY KEY,
    artifact_id INTEGER REFERENCES artifacts(id),
    component_purl VARCHAR(512) NOT NULL,      -- pkg:generic/libopenblas
    component_name VARCHAR(255) NOT NULL,
    component_version VARCHAR(64),
    source VARCHAR(32),                        -- 'rpm', 'source', 'unknown'
    license VARCHAR(255),
    sha256 VARCHAR(64)
);

-- Index for fast CVE lookups
CREATE INDEX idx_component_purl ON artifact_components(component_purl);
CREATE INDEX idx_component_name_version ON artifact_components(component_name, component_version);

-- CVE tracking
CREATE TABLE cve_alerts (
    id SERIAL PRIMARY KEY,
    cve_id VARCHAR(32) NOT NULL,
    severity VARCHAR(16),
    affected_purl_pattern VARCHAR(512),
    affected_version_range VARCHAR(128),
    fixed_version VARCHAR(64),
    discovered_date TIMESTAMP DEFAULT NOW(),
    status VARCHAR(32) DEFAULT 'new'           -- new, analyzing, rebuilding, resolved
);

-- Rebuild history
CREATE TABLE rebuilds (
    id SERIAL PRIMARY KEY,
    artifact_id INTEGER REFERENCES artifacts(id),
    cve_id VARCHAR(32),
    trigger_reason TEXT,
    old_version VARCHAR(64),
    new_version VARCHAR(64),
    rebuild_date TIMESTAMP DEFAULT NOW(),
    status VARCHAR(32),
    build_log_path VARCHAR(512)
);
```

## CVE Matching Algorithm

```python
from packaging.specifiers import SpecifierSet
from packageurl import PackageURL

def match_cve_to_artifacts(cve: CVERecord) -> list[AffectedArtifact]:
    """
    Given a CVE record, find all affected artifacts in our registry.

    CVE record contains:
    - affected_products: list of CPEs or PURLs
    - version_ranges: version specifiers for affected versions
    """
    affected = []

    for product in cve.affected_products:
        # Normalize to PURL if CPE
        purl = normalize_to_purl(product)

        # Query our component database
        components = db.query("""
            SELECT ac.*, a.artifact_name, a.artifact_version
            FROM artifact_components ac
            JOIN artifacts a ON ac.artifact_id = a.id
            WHERE ac.component_purl LIKE %s
              AND ac.component_version IS NOT NULL
        """, (f"{purl}%",))

        # Check version ranges
        for comp in components:
            if version_in_range(comp.component_version, cve.version_ranges):
                affected.append(AffectedArtifact(
                    artifact_name=comp.artifact_name,
                    artifact_version=comp.artifact_version,
                    component_name=comp.component_name,
                    component_version=comp.component_version,
                    cve_id=cve.id,
                    severity=cve.severity,
                    fixed_version=cve.fixed_version,
                ))

    return affected

def version_in_range(version: str, ranges: list[str]) -> bool:
    """
    Check if version matches any vulnerability range.

    Ranges can be:
    - "< 3.0.13"
    - ">= 2.0.0, < 2.1.5"
    - "== 1.2.3"
    """
    from packaging.version import Version

    try:
        v = Version(version)
        for range_spec in ranges:
            specifier = SpecifierSet(range_spec)
            if v in specifier:
                return True
    except Exception:
        # Version parsing failed, assume affected to be safe
        return True

    return False
```

## Rebuild Workflow

```yaml
# .github/workflows/cve-rebuild.yml
name: CVE Security Rebuild

on:
  workflow_dispatch:
    inputs:
      cve_id:
        description: 'CVE ID to address'
        required: true
      artifact_pattern:
        description: 'Artifact pattern to rebuild (e.g., numpy-*)'
        required: false
  schedule:
    # Check for new CVEs daily
    - cron: '0 6 * * *'

jobs:
  scan-for-cves:
    runs-on: ubuntu-latest
    outputs:
      affected_artifacts: ${{ steps.scan.outputs.artifacts }}
    steps:
      - name: Scan CVE databases
        id: scan
        run: |
          # Query NVD/OSV for CVEs affecting our components
          python scripts/cve_scanner.py --output affected.json
          echo "artifacts=$(cat affected.json)" >> $GITHUB_OUTPUT

  rebuild-affected:
    needs: scan-for-cves
    if: needs.scan-for-cves.outputs.affected_artifacts != '[]'
    runs-on: [self-hosted, ppc64le]
    strategy:
      matrix:
        artifact: ${{ fromJson(needs.scan-for-cves.outputs.affected_artifacts) }}
    steps:
      - name: Rebuild ${{ matrix.artifact.name }}
        run: |
          # Increment security rebuild number
          export SECURITY_REBUILD=${{ matrix.artifact.rebuild_number }}

          # Run build with updated dependencies
          ./scripts/rebuild.sh \
            --package ${{ matrix.artifact.name }} \
            --version ${{ matrix.artifact.version }} \
            --fix-cve ${{ matrix.artifact.cve_id }} \
            --update-component ${{ matrix.artifact.component }}

      - name: Register rebuilt artifact
        run: |
          python scripts/register_rebuild.py \
            --artifact ${{ matrix.artifact.name }} \
            --cve ${{ matrix.artifact.cve_id }} \
            --sbom output/*.sbom.json
```

## Notification and Reporting

```python
def generate_cve_report(cve_id: str) -> CVEReport:
    """
    Generate a full report for a CVE affecting our artifacts.
    """
    affected = find_affected_artifacts(cve_id)

    return CVEReport(
        cve_id=cve_id,
        severity=get_cve_severity(cve_id),
        description=get_cve_description(cve_id),

        # What's affected
        affected_artifacts=[{
            'name': a.artifact_name,
            'version': a.artifact_version,
            'component': a.component_name,
            'component_version': a.component_version,
        } for a in affected],

        # What to do
        remediation={
            'action': 'rebuild',
            'target_component_version': get_fixed_version(cve_id),
            'estimated_effort': estimate_rebuild_effort(affected),
            'rebuild_command': generate_rebuild_commands(affected),
        },

        # Customer impact
        customer_impact={
            'downstream_packages': count_dependents(affected),
            'known_deployments': query_deployment_registry(affected),
        },

        # Timeline
        timeline={
            'cve_published': get_cve_publish_date(cve_id),
            'detected_in_inventory': datetime.now(),
            'target_rebuild_date': calculate_target_date(cve_id),
        }
    )

# Example output:
"""
CVE-2024-XXXX Security Report
=============================

Severity: CRITICAL
Description: Buffer overflow in libopenblas < 0.3.25

Affected Artifacts (3):
  - numpy-1.26.0 (bundles libopenblas 0.3.24)
  - scipy-1.11.0 (bundles libopenblas 0.3.24)
  - pandas-2.1.0 (depends on numpy-1.26.0)

Remediation:
  Action: Rebuild with libopenblas >= 0.3.25

  Commands:
    ./build.sh numpy 1.26.0 --security-rebuild --update-openblas=0.3.25
    ./build.sh scipy 1.11.0 --security-rebuild --update-openblas=0.3.25
    # pandas will get new numpy via dependency resolution

Customer Impact:
  - 47 downstream packages depend on affected artifacts
  - 3 known production deployments

Timeline:
  CVE Published:     2024-01-10
  Detected in Inv:   2024-01-11 06:00 UTC
  Target Rebuild:    2024-01-11 18:00 UTC (within 12h for CRITICAL)
"""
```

## Open Questions

1. **Automatic vs. Manual Rebuilds**: Should CRITICAL CVEs trigger automatic rebuilds, or require human approval?

2. **Version Pinning**: When we rebuild numpy with new OpenBLAS, do we need to rebuild scipy too even if it could use the same binary? (Answer: yes, for SBOM accuracy)

3. **Customer Notification**: How do customers know they need to update? Registry advisory? Email? Both?

4. **Rollback Strategy**: If a security rebuild breaks something, how do we rollback while still addressing the CVE?

5. **Air-Gapped Environments**: How do we handle CVE databases for customers who can't reach the internet?

---
*Document created: 2024 | Status: DRAFT for discussion*
