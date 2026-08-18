#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : gensim
# Version          : 4.3.3
# Source repo      : https://github.com/RaRe-Technologies/gensim
# Tested on        : UBI:10.1
# Language         : Python
# Ci-Check         : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Shivansh Sharma <shivansh.s1@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# -----------------------------------------------------------------------------

set -e

PACKAGE_NAME=gensim
PACKAGE_VERSION=${1:-4.4.0}
PACKAGE_URL=https://github.com/RaRe-Technologies/gensim
PACKAGE_DIR=gensim
CURRENT_DIR=$(pwd)

# ---------------------------------------------------------------------------
# System dependencies
# Python packages MUST be listed first — create_wheel_wrapper.sh strips them.
# ---------------------------------------------------------------------------
yum install -y python3.12 python3.12-devel python3.12-pip \
    git gcc-toolset-15 gcc-toolset-15-gcc gcc-toolset-15-gcc-c++ \
    make openblas-devel

# ---------------------------------------------------------------------------
# Activate GCC Toolset 15 (SCL removed in UBI 10 — use PATH export)
# ---------------------------------------------------------------------------
if [[ -f /opt/rh/gcc-toolset-15/enable ]]; then
    source /opt/rh/gcc-toolset-15/enable
elif [[ -d /opt/rh/gcc-toolset-15/root/usr/bin ]]; then
    export PATH="/opt/rh/gcc-toolset-15/root/usr/bin:$PATH"
    export LD_LIBRARY_PATH="/opt/rh/gcc-toolset-15/root/usr/lib64:$LD_LIBRARY_PATH"
else
    echo "ERROR: gcc-toolset-15 not found"
    exit 1
fi

echo "Using gcc: $(gcc --version | head -1)"

# ---------------------------------------------------------------------------
# Python build tools (always via pip, never via yum)
# ---------------------------------------------------------------------------
pip install --upgrade pip setuptools wheel build

# ---------------------------------------------------------------------------
# Build-time dependencies
# numpy and scipy must be installed before building gensim (Cython extensions
# use numpy headers; scipy is a runtime dep resolved at build time).
# ---------------------------------------------------------------------------
# UBI 10.1 pinned versions (§24 of SKILL.md)
# oldest-supported-numpy and Cython<3 are required by gensim's setup.py
# before --no-isolation build can proceed.
pip install "numpy==2.2.6" "scipy>=1.17.0,<1.18.0" \
    "Cython>=0.29.32,<3.0.0" oldest-supported-numpy

# ---------------------------------------------------------------------------
# Clone & checkout
# ---------------------------------------------------------------------------
cd "$CURRENT_DIR"
git clone "$PACKAGE_URL" "$PACKAGE_DIR"
cd "$PACKAGE_DIR"

if git rev-parse "v${PACKAGE_VERSION}" &>/dev/null; then
    git checkout "v${PACKAGE_VERSION}"
elif git rev-parse "${PACKAGE_VERSION}" &>/dev/null; then
    git checkout "${PACKAGE_VERSION}"
else
    echo "ERROR: No git tag found for version '${PACKAGE_VERSION}'"
    exit 1
fi

# ---------------------------------------------------------------------------
# Build wheel
# ---------------------------------------------------------------------------
if ! python3.12 -m build --wheel --no-isolation; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi
cp dist/*.whl "$CURRENT_DIR/"

# ---------------------------------------------------------------------------
# Install runtime dependencies and the built wheel
# ---------------------------------------------------------------------------
pip install smart_open
pip install "$CURRENT_DIR"/gensim-*.whl

# ---------------------------------------------------------------------------
# Test
# ---------------------------------------------------------------------------
cd "$CURRENT_DIR"

if ! python3.12 - <<'PYEOF'
import gensim
print(f"gensim version: {gensim.__version__}")
assert gensim.__version__ == "4.3.3", f"Unexpected version: {gensim.__version__}"
print("PASS  version check")

from gensim.models import Word2Vec
sentences = [["cat", "say", "meow"], ["dog", "say", "woof"], ["cat", "run", "fast"], ["dog", "run", "fast"]]
model = Word2Vec(sentences, vector_size=16, window=3, min_count=1, workers=1, epochs=5, seed=42)
assert "cat" in model.wv, "cat not in vocabulary"
assert "dog" in model.wv, "dog not in vocabulary"
sim = model.wv.similarity("cat", "dog")
print(f"PASS  Word2Vec smoke test (cat/dog similarity={sim:.4f})")

from gensim.models import FastText
ft_model = FastText(sentences, vector_size=16, window=3, min_count=1, workers=1, epochs=5, seed=42)
assert ft_model.wv.vectors is not None
print("PASS  FastText smoke test")

from gensim.corpora import Dictionary
from gensim.models import LdaModel
texts = [["human", "interface", "computer"],
         ["survey", "user", "computer", "system"],
         ["graph", "trees", "minors"]]
dictionary = Dictionary(texts)
corpus = [dictionary.doc2bow(text) for text in texts]
lda = LdaModel(corpus, num_topics=2, id2word=dictionary, passes=5, random_state=42)
topics = lda.print_topics(num_words=3)
assert len(topics) == 2
print(f"PASS  LDA smoke test (topics={len(topics)})")

print("\nAll gensim tests passed.")
PYEOF
then
    echo "------------------$PACKAGE_NAME:Install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:Install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi

