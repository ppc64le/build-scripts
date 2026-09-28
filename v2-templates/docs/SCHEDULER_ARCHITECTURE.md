# Weighted Critical Path (WCP) Scheduler Architecture

## Executive Summary

This document describes the architecture for an optimized build scheduler that minimizes total build time (makespan) for complex dependency graphs like the vllm build chain. The scheduler uses **Weighted Critical Path (WCP) List Scheduling** to prioritize tasks that would otherwise bottleneck the build pipeline.

---

## 1. Problem Definition

### 1.1 The Challenge

Building packages like vllm requires ~36 dependent packages across 6 tiers. A naive approach (alphabetical, FIFO) can leave critical long-running builds (pytorch: 3 hours, llvm: 45 min) waiting behind trivial packages, extending total build time significantly.

### 1.2 Objectives

1. **Minimize makespan** - Total wall-clock time from first task start to last task completion
2. **Maximize parallelism** - Keep all N workers busy when possible
3. **Respect dependencies** - Never start a task before its dependencies complete
4. **Handle cold start** - Work reasonably without historical build time data
5. **Improve over time** - Incorporate actual build times as they become available

### 1.3 Constraints

- Dependency relationships defined in `build_info.json` files
- Parallelism factor N is user/environment configurable
- Build times vary by architecture (ppc64le, s390x, x86_64)
- Build times vary by Python version
- Some packages are "providers" (produce artifacts), others are "consumers"

---

## 2. Algorithm: Weighted Critical Path List Scheduling

### 2.1 Algorithm Family

This scheduler belongs to the family of **Priority-based List Scheduling** algorithms for **DAG (Directed Acyclic Graph) task scheduling on parallel processors**.

Related algorithms:
- **HEFT** (Heterogeneous Earliest Finish Time) - Similar priority function
- **CPOP** (Critical Path on a Processor) - Alternative critical path approach
- **ETF** (Earliest Task First) - Simpler, less optimal

### 2.2 Core Concepts

| Term | Definition |
|------|------------|
| **DAG** | Directed Acyclic Graph - the dependency structure |
| **b-level** | Bottom level - longest path from a node to any exit node |
| **t-level** | Top level - longest path from any entry node to this node |
| **Ready task** | All dependencies satisfied, can be dispatched |
| **Makespan** | Total time from start to completion of all tasks |
| **Priority** | Score determining dispatch order among ready tasks |

### 2.3 Priority Function

```
Priority(task) = b_level(task) × estimated_duration(task)
```

Where:
- **b_level(task)** = Length of longest dependency chain from this task to any terminal node
- **estimated_duration(task)** = Expected build time from historical data or defaults

This priority represents the **"cost of delay"** - how much total pipeline time is wasted if this task starts late.

### 2.4 Why This Works

| Package | b_level | Duration | Priority | Reasoning |
|---------|---------|----------|----------|-----------|
| pytorch | 2 | 180 min | 360 | Long build, blocks torchvision/torchaudio/vllm |
| rapidjson | 3 | 1 min | 3 | Header-only, trivial to build anytime |
| abseil-cpp | 5 | 5 min | 25 | Short build but unlocks longest chains |

Without duration weighting, rapidjson (b_level=3) would outprioritize pytorch (b_level=2), causing a 3-hour delay on the critical path.

---

## 3. Data Structures

### 3.1 Dependency Graph

Built from `build_info.json` files:

```python
@dataclass
class Package:
    name: str
    version: str
    provides_artifact: Optional[str]  # What artifact this builds
    build_deps: List[str]             # Required artifacts (name or name:version)

@dataclass
class DependencyGraph:
    packages: Dict[str, Package]
    artifact_providers: Dict[str, str]  # artifact_name -> package_name
    forward_deps: Dict[str, Set[str]]   # package -> packages it depends on
    reverse_deps: Dict[str, Set[str]]   # package -> packages that depend on it
```

### 3.2 Priority Queue

Ready tasks sorted by priority:

```python
@dataclass
class ScheduledTask:
    package: Package
    priority: float
    b_level: int
    estimated_duration: float

class ReadyQueue:
    """Priority queue of tasks ready for dispatch."""
    tasks: SortedList[ScheduledTask]  # Sorted by priority descending

    def push(self, task: ScheduledTask) -> None: ...
    def pop(self) -> ScheduledTask: ...
    def is_empty(self) -> bool: ...
```

### 3.3 Execution State

```python
@dataclass
class ExecutionState:
    pending: Set[str]      # Not yet ready (waiting on deps)
    ready: ReadyQueue      # Ready for dispatch
    running: Dict[str, Worker]  # Currently executing
    completed: Set[str]    # Successfully finished
    failed: Set[str]       # Failed (and dependents blocked)

    in_degree: Dict[str, int]  # Remaining dependency count per task
```

---

## 4. Algorithm Pseudocode

### 4.1 Initialization Phase (Static Analysis)

```python
def initialize_scheduler(packages: List[Package],
                         build_times: BuildTimeDB) -> ExecutionState:
    """
    Build dependency graph and calculate static priorities.
    Called once at scheduler start.
    """
    graph = build_dependency_graph(packages)

    # Calculate b_level for each package (longest path to exit)
    b_levels = {}
    for pkg in reverse_topological_order(graph):
        dependents = graph.reverse_deps[pkg.name]
        if not dependents:
            b_levels[pkg.name] = 0
        else:
            b_levels[pkg.name] = 1 + max(b_levels[d] for d in dependents)

    # Calculate priorities
    priorities = {}
    for pkg in packages:
        duration = build_times.get_estimate(
            pkg.name, pkg.version,
            arch=CURRENT_ARCH,
            fallback=DEFAULT_BUILD_TIME
        )
        priorities[pkg.name] = b_levels[pkg.name] * duration

    # Initialize state
    state = ExecutionState()
    for pkg in packages:
        deps = resolve_dependencies(pkg.build_deps, graph.artifact_providers)
        state.in_degree[pkg.name] = len(deps)

        if state.in_degree[pkg.name] == 0:
            state.ready.push(ScheduledTask(
                package=pkg,
                priority=priorities[pkg.name],
                b_level=b_levels[pkg.name],
                estimated_duration=duration
            ))
        else:
            state.pending.add(pkg.name)

    return state
```

### 4.2 Dispatch Loop (Dynamic Execution)

```python
def run_scheduler(state: ExecutionState,
                  workers: WorkerPool,
                  parallelism: int) -> BuildResult:
    """
    Main scheduler loop. Runs until all tasks complete or unrecoverable failure.
    """
    while not is_complete(state):
        # Dispatch ready tasks to free workers
        while workers.free_count() > 0 and not state.ready.is_empty():
            task = state.ready.pop()
            worker = workers.acquire()
            state.running[task.package.name] = worker
            worker.dispatch(task)

        # Wait for any task to complete
        completed_task, result = workers.wait_any()
        state.running.remove(completed_task.name)

        if result.success:
            handle_success(state, completed_task)
        else:
            handle_failure(state, completed_task, result.error)

    return BuildResult(
        completed=state.completed,
        failed=state.failed
    )

def handle_success(state: ExecutionState, task: ScheduledTask) -> None:
    """Task completed successfully. Unlock dependents."""
    state.completed.add(task.package.name)

    # Decrement in_degree for all dependents
    for dependent in graph.reverse_deps[task.package.name]:
        state.in_degree[dependent] -= 1

        if state.in_degree[dependent] == 0:
            # All dependencies satisfied - move to ready queue
            state.pending.remove(dependent)
            state.ready.push(create_task(dependent))

def handle_failure(state: ExecutionState, task: ScheduledTask,
                   error: Error) -> None:
    """Task failed. Mark dependents as blocked."""
    state.failed.add(task.package.name)

    # Recursively mark all dependents as failed
    def mark_blocked(pkg_name: str) -> None:
        for dependent in graph.reverse_deps[pkg_name]:
            if dependent not in state.failed:
                state.failed.add(dependent)
                state.pending.discard(dependent)
                mark_blocked(dependent)

    mark_blocked(task.package.name)
```

### 4.3 Completion Check

```python
def is_complete(state: ExecutionState) -> bool:
    """Check if scheduler should terminate."""
    # Done when nothing left to do
    return (state.ready.is_empty() and
            len(state.running) == 0 and
            len(state.pending) == 0)
```

---

## 5. Integration Points

### 5.1 Dependency Source: build_info.json

Location: `{letter}/{package}/build_info.json`

```json
{
  "package_name": "pytorch",
  "provides_artifact": "pytorch",
  "build_deps": ["openblas:v0.3.29", "protobuf:v25.3"],
  "version": "v2.6.0"
}
```

Parsing rules:
- `provides_artifact`: Optional. If present, this package produces an artifact others can depend on
- `build_deps`: List of artifact names, optionally with version specifiers
- Version specifiers (`name:version`) are hints for compatibility, not strict requirements

### 5.2 Build Time Source: Cloudant Database

Schema for historical build times:

```json
{
  "_id": "pytorch:v2.6.0:ppc64le:python3.12",
  "package_name": "pytorch",
  "version": "v2.6.0",
  "arch": "ppc64le",
  "python_version": "3.12",
  "build_times": [
    {
      "timestamp": "2024-02-19T10:30:00Z",
      "build_time_seconds": 10834,
      "test_time_seconds": 1823,
      "success": true,
      "worker_type": "large"
    }
  ],
  "avg_build_time_seconds": 10500,
  "avg_test_time_seconds": 1750,
  "sample_count": 5
}
```

Query strategy:
```python
def get_estimate(pkg_name: str, version: str, arch: str,
                 python_version: str, fallback: float) -> float:
    """Get build time estimate, falling back gracefully."""

    # Try exact match
    key = f"{pkg_name}:{version}:{arch}:{python_version}"
    if doc := cloudant.get(key):
        return doc["avg_build_time_seconds"]

    # Try without Python version (native libraries)
    key = f"{pkg_name}:{version}:{arch}:*"
    if doc := cloudant.get(key):
        return doc["avg_build_time_seconds"]

    # Try any version on this arch
    if docs := cloudant.query(package_name=pkg_name, arch=arch):
        return average(d["avg_build_time_seconds"] for d in docs)

    # No data - use fallback
    return fallback
```

### 5.3 Build Time Collection

After each build, record timing:

```python
def record_build_result(task: ScheduledTask, result: BuildResult) -> None:
    """Record build timing for future scheduling optimization."""
    doc_id = f"{task.package.name}:{task.package.version}:{ARCH}:{PYTHON_VERSION}"

    timing = {
        "timestamp": datetime.utcnow().isoformat(),
        "build_time_seconds": result.build_duration,
        "test_time_seconds": result.test_duration,
        "success": result.success,
        "worker_type": result.worker.type
    }

    cloudant.update(doc_id, {
        "$push": {"build_times": timing},
        "$inc": {"sample_count": 1}
    })

    # Recompute average (could also do rolling average)
    recalculate_averages(doc_id)
```

---

## 6. Parallelism Handling

### 6.1 Configuration

Parallelism is specified by user/environment:

```bash
# Environment variable
export BUILD_PARALLELISM=8

# Or command-line
./build-scheduler --parallelism 8 --target vllm
```

### 6.2 Worker Pool

```python
class WorkerPool:
    def __init__(self, parallelism: int):
        self.max_workers = parallelism
        self.available = parallelism
        self.workers: List[Worker] = []

    def free_count(self) -> int:
        return self.available

    def acquire(self) -> Worker:
        assert self.available > 0
        self.available -= 1
        worker = Worker()
        self.workers.append(worker)
        return worker

    def release(self, worker: Worker) -> None:
        self.workers.remove(worker)
        self.available += 1

    def wait_any(self) -> Tuple[ScheduledTask, BuildResult]:
        """Block until any running task completes."""
        return wait_first(self.workers)
```

### 6.3 Behavior at Different Parallelism Levels

| Parallelism | Behavior |
|-------------|----------|
| N=1 | Sequential execution, pure priority order |
| N < ready_tasks | Workers stay fully utilized, optimal |
| N = ready_tasks | All ready tasks run immediately |
| N > ready_tasks | Some workers idle until deps unlock more tasks |
| N = infinity | Maximum parallelism, limited only by dependencies |

---

## 7. Failure Modes & Recovery

### 7.1 Design Philosophy: Swarm Around Failures

Sequential failure discovery is expensive. If the build has 5 independent failures, a naive fail-fast approach requires 5 separate runs to discover them all. Instead, we **swarm around failures** - continuing independent work to discover all failures in a single run.

**Key insight:** When a task fails, its dependents are **blocked**, not **failed**. They haven't been attempted yet. This distinction enables several strategies:

1. **Continue independent chains** - Maximize useful work
2. **De-prioritize blocked tasks** - Optimize for all successes first
3. **Optionally attempt blocked tasks** - Surface additional errors at lowest priority
4. **Clear exit point** - Signal when all viable work is complete

### 7.2 Task States

```python
class TaskState(Enum):
    PENDING = "pending"       # Waiting for dependencies
    READY = "ready"           # Dependencies met, can dispatch
    RUNNING = "running"       # Currently executing
    COMPLETED = "completed"   # Successfully finished
    FAILED = "failed"         # Attempted and failed
    BLOCKED = "blocked"       # Dependency failed, cannot succeed
```

**State transitions:**
```
PENDING → READY        (all deps complete)
PENDING → BLOCKED      (any dep failed)
READY → RUNNING        (dispatched to worker)
RUNNING → COMPLETED    (success)
RUNNING → FAILED       (error)
```

### 7.3 Failure Handling Algorithm

```python
def handle_failure(state: ExecutionState, task: ScheduledTask,
                   error: Error) -> None:
    """
    Task failed. Mark dependents as blocked, continue independent work.
    """
    state.failed.add(task.package.name)

    # Mark dependents as BLOCKED (not failed - they weren't attempted)
    def mark_blocked(pkg_name: str) -> None:
        for dependent in graph.reverse_deps[pkg_name]:
            if dependent not in state.blocked and dependent not in state.failed:
                state.blocked.add(dependent)
                state.pending.discard(dependent)
                # Remove from ready queue if present
                state.ready.remove_if_present(dependent)
                # Recursively block dependents of this dependent
                mark_blocked(dependent)

    mark_blocked(task.package.name)

    # Log but continue
    log.warning(f"{task.package.name} failed: {error}")
    log.info(f"Blocked {len(state.blocked)} dependent packages, continuing...")
```

### 7.4 Priority Adjustment for Blocked Chains

When operating in discovery mode, blocked tasks can optionally be attempted at **lowest priority** to surface additional errors:

```python
def calculate_effective_priority(task: ScheduledTask,
                                 state: ExecutionState) -> float:
    """
    Adjust priority based on blocked status.
    Blocked tasks get negative priority (run last, if at all).
    """
    base_priority = task.priority

    if task.package.name in state.blocked:
        # Will fail due to missing dep, but might reveal additional errors
        # Run at lowest priority, after all viable work
        return -1000 + base_priority  # Negative = last

    return base_priority
```

### 7.5 Execution Phases

The scheduler naturally separates into phases:

```
PHASE 1: Viable Work
├── All tasks with satisfied dependencies
├── Prioritized by WCP (highest impact first)
└── Failures mark dependents as BLOCKED

PHASE 2: Exit Point Decision
├── "All viable work complete"
├── Report: X succeeded, Y failed, Z blocked
└── User option: stop here or continue to Phase 3

PHASE 3: Blocked Chain Exploration (optional)
├── Attempt blocked tasks at lowest priority
├── Will fail (missing deps) but may reveal additional errors
└── Useful for: "what else would break?"
```

### 7.6 Exit Point Notification

```python
def check_viable_work_complete(state: ExecutionState) -> bool:
    """Check if all non-blocked work is done."""
    viable_remaining = (
        state.pending - state.blocked |
        state.ready.tasks |
        set(state.running.keys())
    )
    return len(viable_remaining) == 0

# In main loop:
if check_viable_work_complete(state) and state.blocked:
    log.warning("=" * 60)
    log.warning("ALL VIABLE WORK COMPLETE")
    log.warning(f"  Succeeded: {len(state.completed)}")
    log.warning(f"  Failed: {len(state.failed)}")
    log.warning(f"  Blocked: {len(state.blocked)}")
    log.warning("")
    log.warning("Continuing will attempt blocked tasks to discover")
    log.warning("additional errors, but cannot improve final outcome.")
    log.warning("=" * 60)

    if not config.explore_blocked:
        return  # Stop here
    # Otherwise continue with blocked tasks at lowest priority
```

### 7.7 Example: Protobuf Failure

```
Initial state: 34 packages for vllm build

protobuf FAILS at 12:45

Immediately blocked (direct dependents):
  - grpc_cpp, orc, pytorch, arrow

Transitively blocked:
  - pyarrow (blocked by arrow)
  - torchvision, torchaudio (blocked by pytorch)
  - grpcio (blocked by grpc_cpp)
  - vllm (blocked by pytorch, pyarrow)

Still viable (independent chains):
  - ffmpeg chain: ffmpeg ✓
  - hdf5 chain: hdf5 → h5py ✓
  - llvm chain: llvm → llvmlite → numba ✓
  - All Tier 0 without dependents: numactl, etc. ✓

Result after Phase 1:
  Succeeded: 20
  Failed: 1 (protobuf)
  Blocked: 13

Phase 2 decision point reached at 14:30
User chose --explore-blocked

Phase 3 attempts blocked tasks:
  - pytorch fails: "cannot import protobuf" (expected)
  - arrow fails: "protobuf headers not found" (expected)
  - grpc_cpp fails: "missing libprotobuf.so" (expected)

Final report:
  Root cause: protobuf
  Blocked packages: 13 (all due to protobuf)
  No additional independent failures discovered
```

### 7.8 Worker Failure

If a worker crashes/disconnects:
1. Mark task as `FAILED` (or `PENDING` if retries enabled)
2. Return worker slot to pool
3. If retries enabled, re-queue with retry count incremented
4. After max retries, treat as normal failure

```python
MAX_RETRIES = 2

def handle_worker_failure(task: ScheduledTask, worker: Worker) -> None:
    task.retry_count += 1
    workers.release(worker)

    if task.retry_count <= MAX_RETRIES:
        log.warning(f"{task.package.name} worker failed, retry {task.retry_count}")
        state.ready.push(task)  # Re-queue
    else:
        log.error(f"{task.package.name} exceeded max retries")
        handle_failure(state, task, "worker failure after retries")
```

### 7.9 Timeout Handling

```python
def calculate_timeout(task: ScheduledTask) -> float:
    """Calculate timeout with safety margin."""
    estimate = build_times.get_estimate(task.package.name)

    # 2x estimate for normal tasks
    # 3x for first-time builds (no historical data)
    multiplier = 3.0 if estimate.is_default else 2.0

    return estimate.seconds * multiplier

# Minimum 10 minutes, maximum 8 hours
timeout = max(600, min(timeout, 28800))
```

### 7.10 Summary: Failure Handling Modes

| Mode | Behavior | Use Case |
|------|----------|----------|
| `--fail-fast` | Stop on first failure | Quick validation |
| `--continue` | Swarm around failures, stop at exit point | Default CI behavior |
| `--explore-blocked` | Also attempt blocked tasks | Discover all possible errors |

**Recommendation:** Default to `--continue`. It maximizes information per run while not wasting cycles on doomed tasks.

---

## 8. Cold Start Strategy

When no historical build time data exists:

### 8.1 Default Estimates

Tier-based defaults (conservative):

```python
DEFAULT_BUILD_TIMES = {
    # Based on typical patterns
    "tier_0_header_only": 60,      # 1 minute (rapidjson, xsimd)
    "tier_0_small_c": 180,         # 3 minutes (snappy, c-ares)
    "tier_0_medium_c": 600,        # 10 minutes (hdf5, openblas)
    "tier_0_large_cpp": 2700,      # 45 minutes (llvm, boost)
    "tier_1_cpp": 600,             # 10 minutes
    "tier_2_complex": 1800,        # 30 minutes
    "pytorch": 10800,              # 3 hours (known outlier)
    "default": 600,                # 10 minutes
}
```

### 8.2 Learning Period

During initial runs:
1. Use conservative defaults
2. Record actual times
3. After N samples (e.g., 3), switch to data-driven estimates
4. Continue refining with exponential moving average

### 8.3 Architecture-Specific Considerations

**The Real Problem: Pre-built Binary Availability**

Build times differ dramatically between architectures, but NOT because of CPU performance:

| Architecture | pytorch "install" | Why |
|--------------|-------------------|-----|
| x86_64 | ~30 seconds | Download pre-built wheel from PyPI |
| ppc64le | ~3 hours | No wheel available → build from source |
| s390x | ~3 hours | No wheel available → build from source |

The apparent "slowness" of ppc64le/s390x is an artifact of ecosystem maturity, not hardware capability. POWER10 with SMT8, MMA, and optimized compilers often *outperforms* x86_64 for actual workloads - but only after the software is built.

**This is exactly why we're building the artifact system:**
- Build native dependencies ONCE per (version, arch) tuple
- Cache artifacts for reuse across all subsequent builds
- Eliminate the "build the world every time" tax
- Bring ppc64le/s390x build times closer to x86_64's "download and go" experience

**Bootstrap strategy:**

Since ppc64le builds compile more packages from source, we can't simply multiply x86_64 times. Instead:

```python
if no_data_for_arch(pkg, target_arch):
    # Check if this package typically needs source build on this arch
    if requires_source_build(pkg, target_arch):
        # Use tier-based defaults for source builds
        return DEFAULT_BUILD_TIMES[pkg.tier]
    else:
        # Pre-built wheel likely available, fast install
        return DEFAULT_INSTALL_TIME  # ~60 seconds
```

**Artifact cache impact:**

With a warm artifact cache, ppc64le build times approach x86_64:

```
Cold cache (first build):
  x86_64:  pytorch wheel download    →  30 sec
  ppc64le: pytorch source build      →  3 hours

Warm cache (subsequent builds):
  x86_64:  pytorch wheel download    →  30 sec
  ppc64le: pytorch artifact install  →  60 sec  ← artifact system benefit
```

This transforms the build economics for ppc64le/s390x from "rebuild everything every time" to "build once, reuse forever."

---

## 9. Visualization & Debugging

### 9.1 Pre-execution Plan

Before starting, output the plan:

```
=== BUILD PLAN: vllm ===
Target: vllm v0.8.4
Packages: 34
Parallelism: 8
Estimated makespan: 4h 23m

Critical path:
  abseil-cpp (5m) → protobuf (10m) → grpc_cpp (20m) → arrow (30m) → pyarrow (15m) → vllm (30m)
  Total: 1h 50m

Wave 0 (17 packages, can parallelize):
  [360] pytorch          - START IMMEDIATELY (3h build, blocks vllm)
  [140] boost            - START IMMEDIATELY (35m build, blocks arrow)
  [ 90] llvm             - START IMMEDIATELY (45m build, blocks numba)
  ...
```

### 9.2 Execution Monitoring

Real-time status:

```
[12:34:56] RUNNING: pytorch (1h 23m / ~3h), boost (34m / ~35m), llvm (44m / ~45m)
[12:34:56] READY: protobuf (waiting for worker), re2 (waiting for worker)
[12:34:56] PENDING: grpc_cpp (waiting: protobuf, re2), arrow (waiting: 8 deps)
[12:34:56] COMPLETED: 12/34, FAILED: 0
```

### 9.3 Post-execution Report

```
=== BUILD COMPLETE ===
Total time: 4h 18m (estimated: 4h 23m)
Packages: 34 completed, 0 failed

Longest builds:
  pytorch     3h 01m (estimated: 3h 00m) ✓
  llvm          47m (estimated: 45m)     ✓
  boost         33m (estimated: 35m)     ✓

Build times recorded to database for future optimization.
```

---

## 10. API Summary

### 10.1 Scheduler Interface

```python
class WCPScheduler:
    def __init__(self,
                 packages: List[Package],
                 build_time_db: BuildTimeDB,
                 parallelism: int = 4,
                 fail_fast: bool = True):
        ...

    def plan(self) -> BuildPlan:
        """Generate execution plan without running."""
        ...

    def run(self, workers: WorkerPool) -> BuildResult:
        """Execute the build."""
        ...

    def get_ready_tasks(self) -> List[ScheduledTask]:
        """Get currently ready tasks (for external dispatch)."""
        ...

    def mark_complete(self, task_name: str, result: TaskResult) -> None:
        """Mark a task as complete (for external dispatch)."""
        ...
```

### 10.2 Integration Example

```python
# Load packages from build_info.json files
packages = load_packages_from_directory("build-scripts-v2/")

# Connect to build time database
build_times = CloudantBuildTimeDB(url=CLOUDANT_URL)

# Create scheduler
scheduler = WCPScheduler(
    packages=filter_for_target(packages, "vllm"),
    build_time_db=build_times,
    parallelism=int(os.environ.get("BUILD_PARALLELISM", 4))
)

# Preview the plan
plan = scheduler.plan()
print(plan.summary())

# Execute
result = scheduler.run(workers=ContainerWorkerPool())

# Record timings for future runs
for task, timing in result.timings.items():
    build_times.record(task, timing)
```

---

## 11. Future Enhancements

### 11.1 Goal-Oriented User Modes

**Food for thought:** Rather than exposing scheduler internals (fail-fast, continue, explore-blocked, priority weights, timeouts), provide a single **goal-oriented mode** that captures the user's intent:

```bash
./build-scheduler --mode=deliver vllm    # GET IT DONE
./build-scheduler --mode=explore vllm    # LEARN EVERYTHING
```

| Mode | User Goal | Scheduler Behavior |
|------|-----------|-------------------|
| `deliver` | "Get me a working build ASAP" | Fail-fast on errors, aggressive caching, skip flaky tests, optimize for speed |
| `explore` | "Tell me everything that's broken" | Swarm around failures, explore blocked chains, lenient timeouts, run all tests |

**Implementation:** A single mode parameter configures multiple internal settings:

```python
MODE_CONFIGS = {
    "deliver": {
        "failure_handling": "fail_fast",
        "explore_blocked": False,
        "timeout_multiplier": 1.5,
        "use_cached_artifacts": True,
        "test_level": "quick",
        "priority_boost_critical_path": True,
    },
    "explore": {
        "failure_handling": "continue",
        "explore_blocked": True,
        "timeout_multiplier": 3.0,
        "use_cached_artifacts": False,  # Rebuild to verify
        "test_level": "full",
        "priority_boost_critical_path": False,  # Even coverage
    }
}

def apply_mode(config: SchedulerConfig, mode: str) -> None:
    config.update(MODE_CONFIGS[mode])
```

**Why this matters:**

For builds with thousands or tens of thousands of packages, the user shouldn't need to understand scheduler internals. They have a goal:

- **"I need vllm working by tomorrow"** → `--mode=deliver`
- **"We're validating a new Python version, find all breakages"** → `--mode=explore`

This transforms a complex multi-parameter configuration into a single intent-driven choice.

**Extensible:** Additional modes could include:

| Mode | Use Case |
|------|----------|
| `validate` | CI validation - fast feedback, fail on any issue |
| `release` | Release prep - full tests, strict checks, no shortcuts |
| `debug` | Developer mode - verbose output, keep intermediates |
| `benchmark` | Performance testing - record all timings, no caching |

### 11.2 Resource-Aware Scheduling

Some builds need more resources (RAM, CPU):
```python
@dataclass
class ResourceRequirements:
    cpu_cores: int = 4
    memory_gb: int = 8

# pytorch needs 32GB RAM
# Don't schedule it on a small worker
```

### 11.3 Heterogeneous Workers

Different worker types (small, medium, large):
```python
# Assign pytorch to large worker
# Assign rapidjson to small worker
# Maximize throughput by matching task to worker
```

### 11.4 Speculative Execution

If build times are highly variable:
```python
# Start backup task on different worker if primary is taking too long
# Use first completion, cancel the other
```

### 11.5 Incremental Builds

Skip unchanged packages:
```python
if artifact_cache.exists(pkg, version) and not force_rebuild:
    mark_complete(pkg)  # Skip to unlock dependents immediately
```

---

## 12. References

1. **HEFT Algorithm**: Topcuoglu, H., Hariri, S., & Wu, M. Y. (2002). Performance-effective and low-complexity task scheduling for heterogeneous computing. IEEE Transactions on Parallel and Distributed Systems.

2. **Critical Path Method**: Kelley, J. E., & Walker, M. R. (1959). Critical-path planning and scheduling. Eastern Joint IRE-AIEE-ACM Computer Conference.

3. **DAG Scheduling Survey**: Kwok, Y. K., & Ahmad, I. (1999). Static scheduling algorithms for allocating directed task graphs to multiprocessors. ACM Computing Surveys.

4. **List Scheduling**: Graham, R. L. (1969). Bounds on multiprocessing timing anomalies. SIAM Journal on Applied Mathematics.
