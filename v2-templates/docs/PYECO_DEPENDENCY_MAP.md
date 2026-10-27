# PyEco Examples - Dependency Mapping Analysis

## Overview

This document maps the dependencies required by the 10 PyEco examples to existing build scripts in `build-scripts-v2`. It identifies gaps, high-priority packages, and provides a recommended build order.

**Repository**: https://github.com/ppc64le/pyeco/tree/main/examples
**Analysis Date**: 2026-02-20

---

## Executive Summary

| Metric | Count |
|--------|-------|
| Total PyEco Examples | 10 |
| Unique Direct Dependencies | ~45 |
| Build Scripts Found | 38 |
| Missing Build Scripts | 7 |
| HIGH-PRIORITY Gaps | 3 |
| Critical Native Artifacts | 15 |

---

## PyEco Examples Dependency Analysis

### 1. vllm-example

**Direct Dependencies**: vllm, wrapt

**Transitive Dependency Chain**:
```
vllm (Tier 5)
  |- pytorch (Tier 4)
  |    |- openblas (Tier 0) [NATIVE]
  |    |- protobuf (Tier 1) [NATIVE]
  |    |- abseil-cpp (Tier 0) [NATIVE]
  |    |- numactl (Tier 0) [NATIVE]
  |- torchvision (Tier 4)
  |    |- pytorch
  |    |- pillow
  |    |- ffmpeg (Tier 1) [NATIVE]
  |- torchaudio (Tier 4)
  |    |- pytorch
  |- pyarrow (Tier 4)
  |    |- arrow (Tier 3) [NATIVE]
  |         |- grpc_cpp (Tier 2)
  |         |- orc (Tier 2)
  |         |- boost (Tier 1)
  |         |- thrift (Tier 1)
  |         |- protobuf (Tier 1)
  |         |- snappy (Tier 0)
  |         |- zstd (Tier 0)
  |         |- utf8proc (Tier 0)
  |         |- re2 (Tier 0)
  |         |- c-ares (Tier 0)
wrapt
```

**Build Script Status**:
| Package | Script Path | Status |
|---------|-------------|--------|
| vllm | `v/vllm/vllm.sh` | EXISTS |
| wrapt | `w/wrapt/wrapt.sh` | EXISTS |
| pytorch | `p/pytorch/pytorch.sh` | EXISTS (needs artifacts) |
| torchvision | `t/torchvision/torchvision.sh` | EXISTS |
| torchaudio | `t/torchaudio/torchaudio.sh` | EXISTS |
| pyarrow | `p/pyarrow/pyarrow.sh` | EXISTS (needs arrow artifact) |
| arrow | `a/arrow/arrow.sh` | EXISTS |
| openblas | `o/openblas/openblas.sh` | EXISTS |
| protobuf | `p/protobuf/protobuf.sh` | EXISTS |
| abseil-cpp | `a/abseil-cpp/abseil-cpp.sh` | EXISTS |

---

### 2. pytorch-example

**Direct Dependencies**: torch, scikit-learn, scipy, numpy, pandas, psutil

**Transitive Dependency Chain**:
```
torch (pytorch)
  |- openblas [NATIVE]
  |- protobuf [NATIVE]
  |- abseil-cpp [NATIVE]
scikit-learn
  |- numpy
  |- scipy
  |- openblas [NATIVE]
scipy
  |- numpy
  |- openblas [NATIVE]
numpy
  |- openblas [NATIVE]
pandas
  |- numpy
psutil
```

**Build Script Status**:
| Package | Script Path | Status |
|---------|-------------|--------|
| torch/pytorch | `p/pytorch/pytorch.sh`, `t/torch/torch.sh` | EXISTS (BLOCKED - needs legacy scripts) |
| scikit-learn | `s/scikit-learn/scikit-learn.sh` | EXISTS |
| scipy | `s/scipy/scipy.sh` | EXISTS |
| numpy | `n/numpy/numpy.sh` | EXISTS |
| pandas | `p/pandas/pandas.sh` | EXISTS |
| psutil | `p/psutil/psutil.sh` | EXISTS |

---

### 3. lightgbm-pyarrow-example

**Direct Dependencies**: lightgbm, pyarrow, pillow, scikit-learn

**Transitive Dependency Chain**:
```
lightgbm
  |- openblas [NATIVE]
  |- cmake (build-time)
pyarrow
  |- arrow [NATIVE]
       |- (see full chain in vllm-example)
pillow
  |- libjpeg, libpng, zlib (system)
scikit-learn
  |- numpy, scipy, openblas [NATIVE]
```

**Build Script Status**:
| Package | Script Path | Status |
|---------|-------------|--------|
| lightgbm | `l/lightgbm/lightgbm.sh` | EXISTS |
| pyarrow | `p/pyarrow/pyarrow.sh` | EXISTS |
| pillow | `p/pillow/pillow.sh` | EXISTS |
| scikit-learn | `s/scikit-learn/scikit-learn.sh` | EXISTS |

---

### 4. onnx_example

**Direct Dependencies**: skl2onnx, onnx, onnxruntime, onnxconverter-common, numpy, scikit-learn

**Transitive Dependency Chain**:
```
skl2onnx
  |- onnx
  |- onnxconverter-common
  |- scikit-learn
onnx
  |- protobuf [NATIVE]
  |- abseil-cpp [NATIVE]
  |- numpy
onnxruntime
  |- protobuf [NATIVE]
  |- abseil-cpp [NATIVE]
  |- openblas [NATIVE]
  |- onnx
onnxconverter-common
  |- onnx
  |- numpy
numpy
scikit-learn
```

**Build Script Status**:
| Package | Script Path | Status |
|---------|-------------|--------|
| skl2onnx | `s/skl2onnx/skl2onnx.sh` | EXISTS (complex, needs review) |
| onnx | `o/onnx/onnx.sh` | EXISTS |
| onnxruntime | `o/onnxruntime/onnxruntime.sh` | EXISTS (BLOCKED - custom build.sh) |
| onnxconverter-common | `o/onnxconverter-common/onnxconvertercommon.sh` | EXISTS |
| numpy | `n/numpy/numpy.sh` | EXISTS |
| scikit-learn | `s/scikit-learn/scikit-learn.sh` | EXISTS |

---

### 5. pyav-example

**Direct Dependencies**: pillow, ml_dtypes, av (PyAV), llvmlite, numpy

**Transitive Dependency Chain**:
```
pillow
  |- libjpeg, libpng, zlib (system)
ml_dtypes
  |- numpy
av (PyAV)
  |- ffmpeg [NATIVE]
       |- lame [NATIVE]
       |- libvpx [NATIVE]
       |- opus [NATIVE]
llvmlite
  |- llvm [NATIVE]
numpy
  |- openblas [NATIVE]
```

**Build Script Status**:
| Package | Script Path | Status |
|---------|-------------|--------|
| pillow | `p/pillow/pillow.sh` | EXISTS |
| ml_dtypes | `m/ml-dtypes/ml-dtypes.sh`, `m/ml_dtypes/mldtypes.sh` | EXISTS |
| av (PyAV) | `p/pyav/pyav.sh` | EXISTS |
| llvmlite | `l/llvmlite/llvmlite.sh` | EXISTS |
| numpy | `n/numpy/numpy.sh` | EXISTS |
| ffmpeg | `f/ffmpeg/ffmpeg.sh` | EXISTS |
| llvm | `l/llvm/llvm.sh` | EXISTS |

---

### 6. xgboost-example

**Direct Dependencies**: xgboost, numpy, pandas, scipy, sentencepiece, cryptography

**Transitive Dependency Chain**:
```
xgboost
  |- openblas [NATIVE]
  |- cmake (build-time)
numpy
pandas
  |- numpy
scipy
  |- numpy
  |- openblas [NATIVE]
sentencepiece
  |- protobuf [NATIVE]
cryptography
  |- openssl (system)
  |- rust/cargo (build-time)
```

**Build Script Status**:
| Package | Script Path | Status |
|---------|-------------|--------|
| xgboost | `x/xgboost/xgboost.sh` | EXISTS |
| numpy | `n/numpy/numpy.sh` | EXISTS |
| pandas | `p/pandas/pandas.sh` | EXISTS |
| scipy | `s/scipy/scipy.sh` | EXISTS |
| sentencepiece | `s/sentencepiece/sentencepiece.sh` | EXISTS |
| cryptography | `c/cryptography/cryptography.sh` | EXISTS |

---

### 7. Granite-pytorch

**Direct Dependencies**: torch, transformers, bitsandbytes (optional)

**Transitive Dependency Chain**:
```
torch (pytorch)
  |- (see pytorch-example)
transformers
  |- torch
  |- numpy
  |- tokenizers (Rust)
  |- safetensors (Rust)
  |- sentencepiece
bitsandbytes (optional)
  |- cuda-toolkit (NOT available on ppc64le)
```

**Build Script Status**:
| Package | Script Path | Status |
|---------|-------------|--------|
| torch | `p/pytorch/pytorch.sh` | EXISTS (BLOCKED) |
| transformers | N/A | **MISSING** |
| bitsandbytes | N/A | **MISSING** (CUDA-only, N/A for ppc64le) |
| tokenizers | `t/tokenizers/tokenizers.sh` | EXISTS |

---

### 8. sklearn-ibmcos-jwt

**Direct Dependencies**: scikit-learn, msgpack, pillow, ibm-cos-sdk, PyJWT, cryptography, skl2onnx, onnxruntime

**Transitive Dependency Chain**:
```
scikit-learn
  |- numpy, scipy, openblas [NATIVE]
msgpack
pillow
ibm-cos-sdk
  |- ibm-cos-sdk-core
  |- ibm-cos-sdk-s3transfer
PyJWT
  |- cryptography
cryptography
  |- openssl, rust
skl2onnx
  |- onnx, onnxconverter-common
onnxruntime
  |- protobuf, abseil-cpp, openblas [NATIVE]
```

**Build Script Status**:
| Package | Script Path | Status |
|---------|-------------|--------|
| scikit-learn | `s/scikit-learn/scikit-learn.sh` | EXISTS |
| msgpack | `m/msgpack-python/msgpack-python.sh` | EXISTS |
| pillow | `p/pillow/pillow.sh` | EXISTS |
| ibm-cos-sdk | `i/ibm-cos-sdk/ibm-cos-sdk-python.sh` | EXISTS |
| PyJWT | N/A | **MISSING** (pure Python, pip installable) |
| cryptography | `c/cryptography/cryptography.sh` | EXISTS |
| skl2onnx | `s/skl2onnx/skl2onnx.sh` | EXISTS |
| onnxruntime | `o/onnxruntime/onnxruntime.sh` | EXISTS (BLOCKED) |

---

### 9. nbformat-nbconvert

**Direct Dependencies**: nbformat, nbconvert, ipykernel, jupyter-core, matplotlib, numpy

**Transitive Dependency Chain**:
```
nbformat
  |- jsonschema
  |- jupyter-core
nbconvert
  |- nbformat
  |- jupyter-core
  |- pandoc (system)
ipykernel
  |- jupyter-core
  |- pyzmq
jupyter-core
matplotlib
  |- numpy
  |- pillow
  |- kiwisolver
  |- contourpy
numpy
  |- openblas [NATIVE]
```

**Build Script Status**:
| Package | Script Path | Status |
|---------|-------------|--------|
| nbformat | N/A (build_info.json exists) | **MISSING** (script not found) |
| nbconvert | `n/nbconvert/nbconvert.sh` | EXISTS |
| ipykernel | `i/ipykernel/ipykernel.sh` | EXISTS |
| jupyter-core | `j/jupyter_core/jupyter_core.sh` | EXISTS |
| matplotlib | `m/matplotlib/matplotlib.sh` | EXISTS |
| numpy | `n/numpy/numpy.sh` | EXISTS |

---

### 10. lib-packages (Native Dependencies Test)

**Direct Dependencies**: abseil-cpp, c-ares, ffmpeg, grpc-cpp, h5py, lame, protobuf, libvpx, openblas, opus, orc, re2, snappy, thrift, utf8proc

**All Native Artifacts**:
```
Tier 0 (Foundation):
  |- abseil-cpp
  |- c-ares
  |- lame
  |- libvpx
  |- opus
  |- re2
  |- snappy
  |- utf8proc
  |- numactl
  |- zstd

Tier 1 (Core Libraries):
  |- protobuf (requires abseil-cpp)
  |- ffmpeg (requires lame, libvpx, opus)
  |- boost
  |- thrift
  |- onetbb

Tier 2 (Complex Libraries):
  |- grpc_cpp (requires protobuf, c-ares, re2, abseil-cpp)
  |- orc (requires protobuf, snappy, zstd)
  |- hdf5

Tier 3 (Framework Libraries):
  |- openblas
  |- arrow (requires many Tier 0-2 deps)
```

**Build Script Status**:
| Package | Script Path | Status |
|---------|-------------|--------|
| abseil-cpp | `a/abseil-cpp/abseil-cpp.sh` | EXISTS |
| c-ares | `c/c-ares/c-ares.sh` | EXISTS |
| ffmpeg | `f/ffmpeg/ffmpeg.sh` | EXISTS |
| grpc-cpp | `g/grpc_cpp/grpc_cpp.sh` | EXISTS |
| h5py | `h/h5py/h5py.sh` | EXISTS |
| lame | `l/lame/lame.sh` | EXISTS |
| protobuf | `p/protobuf/protobuf.sh` | EXISTS |
| libvpx | `l/libvpx/libvpx.sh` | EXISTS |
| openblas | `o/openblas/openblas.sh` | EXISTS |
| opus | `o/opus/opus.sh` | EXISTS |
| orc | `o/orc/orc.sh` | EXISTS |
| re2 | `r/re2/re2.sh` | EXISTS |
| snappy | `s/snappy/snappy.sh` | EXISTS |
| thrift | `t/thrift/thrift.sh` | EXISTS |
| utf8proc | `u/utf8proc/utf8proc.sh` | EXISTS |

---

## Complete Build Script Inventory

### Python Packages

| Package | Script Path | Status | Used By Examples |
|---------|-------------|--------|------------------|
| numpy | `n/numpy/numpy.sh` | EXISTS | 1,2,3,4,5,6,8,9 |
| scipy | `s/scipy/scipy.sh` | EXISTS | 2,4,6 |
| pandas | `p/pandas/pandas.sh` | EXISTS | 2,6 |
| scikit-learn | `s/scikit-learn/scikit-learn.sh` | EXISTS | 2,3,4,8 |
| pytorch | `p/pytorch/pytorch.sh` | EXISTS (BLOCKED) | 1,2,7 |
| pillow | `p/pillow/pillow.sh` | EXISTS | 3,5,8,9 |
| pyarrow | `p/pyarrow/pyarrow.sh` | EXISTS | 1,3 |
| vllm | `v/vllm/vllm.sh` | EXISTS | 1 |
| wrapt | `w/wrapt/wrapt.sh` | EXISTS | 1 |
| psutil | `p/psutil/psutil.sh` | EXISTS | 2 |
| lightgbm | `l/lightgbm/lightgbm.sh` | EXISTS | 3 |
| onnx | `o/onnx/onnx.sh` | EXISTS | 4 |
| onnxruntime | `o/onnxruntime/onnxruntime.sh` | EXISTS (BLOCKED) | 4,8 |
| skl2onnx | `s/skl2onnx/skl2onnx.sh` | EXISTS (complex) | 4,8 |
| onnxconverter-common | `o/onnxconverter-common/onnxconvertercommon.sh` | EXISTS | 4 |
| ml_dtypes | `m/ml-dtypes/ml-dtypes.sh` | EXISTS | 5 |
| pyav (av) | `p/pyav/pyav.sh` | EXISTS | 5 |
| llvmlite | `l/llvmlite/llvmlite.sh` | EXISTS | 5 |
| xgboost | `x/xgboost/xgboost.sh` | EXISTS | 6 |
| sentencepiece | `s/sentencepiece/sentencepiece.sh` | EXISTS | 6,7 |
| cryptography | `c/cryptography/cryptography.sh` | EXISTS | 6,8 |
| msgpack | `m/msgpack-python/msgpack-python.sh` | EXISTS | 8 |
| ibm-cos-sdk | `i/ibm-cos-sdk/ibm-cos-sdk-python.sh` | EXISTS | 8 |
| nbconvert | `n/nbconvert/nbconvert.sh` | EXISTS | 9 |
| ipykernel | `i/ipykernel/ipykernel.sh` | EXISTS | 9 |
| jupyter-core | `j/jupyter_core/jupyter_core.sh` | EXISTS | 9 |
| matplotlib | `m/matplotlib/matplotlib.sh` | EXISTS | 9 |
| torchvision | `t/torchvision/torchvision.sh` | EXISTS | 1 |
| torchaudio | `t/torchaudio/torchaudio.sh` | EXISTS | 1 |
| tokenizers | `t/tokenizers/tokenizers.sh` | EXISTS | 7 |
| h5py | `h/h5py/h5py.sh` | EXISTS | 10 |
| numba | `n/numba/numba.sh` | EXISTS | (indirect) |
| transformers | N/A | **MISSING** | 7 |
| PyJWT | N/A | **MISSING** | 8 |
| nbformat | N/A | **MISSING** | 9 |
| bitsandbytes | N/A | **MISSING** (CUDA-only) | 7 (optional) |

### Native Artifact Libraries

| Package | Script Path | Status | Consumers |
|---------|-------------|--------|-----------|
| abseil-cpp | `a/abseil-cpp/abseil-cpp.sh` | EXISTS | protobuf, grpc_cpp, onnx, onnxruntime |
| c-ares | `c/c-ares/c-ares.sh` | EXISTS | grpc_cpp |
| ffmpeg | `f/ffmpeg/ffmpeg.sh` | EXISTS | pyav, torchaudio |
| grpc_cpp | `g/grpc_cpp/grpc_cpp.sh` | EXISTS | arrow |
| lame | `l/lame/lame.sh` | EXISTS | ffmpeg |
| libvpx | `l/libvpx/libvpx.sh` | EXISTS | ffmpeg |
| llvm | `l/llvm/llvm.sh` | EXISTS | llvmlite |
| numactl | `n/numactl/numactl.sh` | EXISTS | pytorch, vllm |
| onetbb | `o/onetbb/onetbb.sh` | EXISTS | scipy, scikit-learn |
| openblas | `o/openblas/openblas.sh` | EXISTS | numpy, scipy, scikit-learn, pytorch, xgboost, lightgbm |
| opus | `o/opus/opus.sh` | EXISTS | ffmpeg |
| orc | `o/orc/orc.sh` | EXISTS | arrow |
| protobuf | `p/protobuf/protobuf.sh` | EXISTS | onnx, onnxruntime, sentencepiece, grpc_cpp |
| re2 | `r/re2/re2.sh` | EXISTS | grpc_cpp |
| snappy | `s/snappy/snappy.sh` | EXISTS | arrow, orc |
| thrift | `t/thrift/thrift.sh` | EXISTS | arrow |
| utf8proc | `u/utf8proc/utf8proc.sh` | EXISTS | arrow |
| zstd | `z/zstd/zstd.sh` | EXISTS | arrow |
| arrow | `a/arrow/arrow.sh` | EXISTS | pyarrow |
| hdf5 | `h/hdf5/hdf5.sh` | EXISTS | h5py |
| boost | `b/boost/` | EXISTS (dir) | arrow, thrift |

---

## Gap Analysis

### Missing Build Scripts

| Package | Priority | Used By | Notes |
|---------|----------|---------|-------|
| **transformers** | HIGH | Granite-pytorch | HuggingFace transformers library |
| **nbformat** | MEDIUM | nbformat-nbconvert | build_info.json exists, script missing |
| **PyJWT** | LOW | sklearn-ibmcos-jwt | Pure Python, pip installable |
| **bitsandbytes** | N/A | Granite-pytorch | CUDA-only, not supported on ppc64le |

### Blocked/Complex Builds

| Package | Issue | Recommendation |
|---------|-------|----------------|
| pytorch/torch | Requires extensive external deps (OpenBLAS, protobuf built from source), custom build system | Use legacy scripts; consider pre-built artifacts |
| onnxruntime | Uses custom `./build.sh` not `python -m build` | Use legacy scripts |
| skl2onnx | Complex environment setup, builds OpenBLAS, protobuf, onnx from source | Needs cleanup/refactoring |

---

## HIGH-PRIORITY Gaps

### 1. transformers (HuggingFace)
- **Used by**: Granite-pytorch example
- **Dependencies**: torch, tokenizers (Rust), safetensors (Rust), sentencepiece
- **Effort**: Medium - pure Python with Rust extensions
- **Priority**: HIGH - critical for LLM workloads

### 2. nbformat
- **Used by**: nbformat-nbconvert example
- **Dependencies**: jsonschema, jupyter-core
- **Effort**: Low - pure Python
- **Priority**: MEDIUM - build_info.json exists, just needs script

### 3. PyJWT
- **Used by**: sklearn-ibmcos-jwt example
- **Dependencies**: cryptography
- **Effort**: Very Low - pure Python
- **Priority**: LOW - can be pip installed directly

---

## Package Overlap Analysis

### Most Frequently Used Packages

| Package | Example Count | Examples |
|---------|--------------|----------|
| numpy | 8 | 1,2,3,4,5,6,8,9 |
| scikit-learn | 4 | 2,3,4,8 |
| pillow | 4 | 3,5,8,9 |
| scipy | 3 | 2,4,6 |
| pytorch/torch | 3 | 1,2,7 |
| cryptography | 2 | 6,8 |
| pandas | 2 | 2,6 |
| pyarrow | 2 | 1,3 |
| onnxruntime | 2 | 4,8 |

### Native Artifacts with Multiple Consumers

| Artifact | Consumer Count | Consumers |
|----------|----------------|-----------|
| openblas | 6+ | numpy, scipy, scikit-learn, pytorch, xgboost, lightgbm |
| protobuf | 5+ | onnx, onnxruntime, sentencepiece, grpc_cpp, arrow |
| abseil-cpp | 4+ | protobuf, grpc_cpp, onnx, onnxruntime |
| ffmpeg | 2 | pyav, torchaudio |
| arrow | 2 | pyarrow, spark |

---

## Recommended Build Order

### Tier 0: Foundation (No dependencies)
```
1. abseil-cpp
2. c-ares
3. lame
4. libvpx
5. opus
6. re2
7. snappy
8. utf8proc
9. numactl
10. zstd
11. xsimd (header-only)
12. rapidjson (header-only)
13. gflags
```

### Tier 1: Core Libraries
```
14. protobuf (requires abseil-cpp)
15. ffmpeg (requires lame, libvpx, opus)
16. boost
17. thrift
18. onetbb
19. hdf5
```

### Tier 2: Complex Libraries
```
20. grpc_cpp (requires protobuf, c-ares, re2, abseil-cpp)
21. orc (requires protobuf, snappy, zstd)
22. llvm
```

### Tier 3: Framework Libraries
```
23. openblas
24. arrow (requires many Tier 0-2 deps)
```

### Tier 4: Python ML Foundations
```
25. numpy (requires openblas)
26. scipy (requires numpy, openblas, onetbb)
27. llvmlite (requires llvm)
28. numba (requires llvmlite, numpy)
29. pillow
30. cryptography
```

### Tier 5: Python ML Core
```
31. pytorch (requires openblas, protobuf, etc.) [BLOCKED]
32. pandas (requires numpy)
33. scikit-learn (requires numpy, scipy)
34. pyarrow (requires arrow)
35. h5py (requires hdf5)
36. sentencepiece (requires protobuf)
37. msgpack
```

### Tier 6: Python ML Extensions
```
38. onnx (requires protobuf, numpy)
39. onnxruntime (requires protobuf, abseil, openblas) [BLOCKED]
40. torchvision (requires pytorch, pillow)
41. torchaudio (requires pytorch, ffmpeg)
42. lightgbm (requires openblas)
43. xgboost (requires openblas)
44. matplotlib (requires numpy, pillow)
```

### Tier 7: Python ML Applications
```
45. skl2onnx (requires onnx, scikit-learn)
46. onnxconverter-common (requires onnx)
47. ml_dtypes (requires numpy)
48. pyav (requires ffmpeg)
49. transformers (requires pytorch, tokenizers) [MISSING]
50. vllm (requires pytorch, pyarrow, etc.)
```

### Tier 8: Jupyter/Notebook Stack
```
51. jupyter-core
52. nbformat [MISSING SCRIPT]
53. nbconvert (requires nbformat)
54. ipykernel
```

---

## Effort Estimation

### To Complete All 10 PyEco Examples

| Task | Effort | Notes |
|------|--------|-------|
| Create transformers script | 2-4 hours | Pure Python + Rust extensions |
| Create nbformat script | 1 hour | Pure Python |
| Create PyJWT script | 30 min | Pure Python |
| Unblock pytorch | 8-16 hours | Requires artifact system completion |
| Unblock onnxruntime | 4-8 hours | Custom build system integration |
| Refactor skl2onnx | 2-4 hours | Cleanup existing complex script |
| **Total Minimum** | **~20 hours** | Assuming artifact system works |

### Quick Wins (< 2 hours each)
1. nbformat - build_info.json exists
2. PyJWT - pure Python
3. transformers - if tokenizers works

### Complex/Blocked (> 8 hours)
1. pytorch - requires full artifact pipeline
2. onnxruntime - custom build system
3. vllm - depends on pytorch

---

## Example Completion Status

| Example | Status | Blockers |
|---------|--------|----------|
| lib-packages | READY | None - all native deps exist |
| lightgbm-pyarrow-example | READY | None - all scripts exist |
| xgboost-example | READY | None - all scripts exist |
| pyav-example | READY | None - all scripts exist |
| nbformat-nbconvert | PARTIAL | Missing nbformat script |
| sklearn-ibmcos-jwt | PARTIAL | Missing PyJWT (can pip install) |
| pytorch-example | BLOCKED | pytorch needs artifact system |
| onnx_example | BLOCKED | onnxruntime uses custom build |
| vllm-example | BLOCKED | Depends on pytorch |
| Granite-pytorch | BLOCKED | Missing transformers, pytorch blocked |

---

## Recommendations

### Immediate Actions
1. Create `nbformat.sh` - build_info.json already exists
2. Create `PyJWT.sh` or note as pip-installable
3. Create `transformers.sh` - critical for LLM examples

### Short-term (1-2 weeks)
1. Complete artifact system integration for Tier 0-2 native libs
2. Test full build chain: openblas -> numpy -> scipy -> scikit-learn
3. Verify pyarrow with arrow artifact

### Medium-term (2-4 weeks)
1. Investigate pytorch artifact-based build
2. Explore onnxruntime template integration
3. Complete all PyEco example dependencies

### Long-term
1. Pre-build artifacts in CI for common native deps
2. Consider conda-forge or wheel caching for common packages
3. Create specialized templates for ML frameworks (pytorch, tensorflow)
