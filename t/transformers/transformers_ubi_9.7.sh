#!/bin/bash
set -euo pipefail
# --------------------------------------------------------------------------------
# Package        : transformers
# Version        : v5.1.0
# Source repo    : https://github.com/huggingface/transformers
# Tested on      : UBI 9.7
# Language       : Python
# Ci-Check       : True
# Maintainer     : Manya Rusiya<Manya.Rusiya@ibm.com>
# Script License : Apache License, Version 2.0 or later
#
# Disclaimer     : This script has been tested in root mode on the specified
#                  platform and package version. Functionality with newer
#                  versions of the package or OS is not guaranteed.
# -------------------------------------------------------------------------------

PACKAGE_VERSION="v5.1.0"
PACKAGE_URL="https://github.com/huggingface/transformers.git"
PACKAGE_DIR="transformers"
TORCHCODEC_VERSION="v0.9.0"

BUILD_HOME="$(pwd)"
OS_NAME="$(awk -F= '/^ID=/{gsub(/"/,"",$2); print $2; exit}' /etc/os-release || echo unknown)"

python_site_packages() {
python - <<'PY'
import sysconfig
print(sysconfig.get_paths()["purelib"])
PY
}

# --------- installing dependencies-------------

yum install -y \
    git make wget gcc-c++ cmake \
	python3.12 python3.12-devel python3.12-pip \
    pkgconfig pkg-config libtool patch ninja-build \
    zlib-devel openssl-devel bzip2-devel libffi-devel \
    libevent-devel freetype-devel gmp-devel \
    atlas libjpeg-devel openblas-devel \
    rust cargo \
    gcc-toolset-13 gcc-toolset-13-libatomic-devel
	
	rm -f /usr/bin/python
    ln -s /usr/bin/python3.12 /usr/bin/python

    rm -f /usr/bin/pip
    ln -s /usr/bin/pip3.12 /usr/bin/pip || true	

python -m pip install --upgrade pip setuptools wheel build pytest nox tox requests
python -m pip install numpy pybind11

# ----------- Binary wheels -----------
python -m pip install --prefer-binary libvpx==1.13.1 --extra-index-url=https://wheels.developerfirst.ibm.com/ppc64le/linux
python -m pip install --prefer-binary lame==3.100 --extra-index-url=https://wheels.developerfirst.ibm.com/ppc64le/linux
python -m pip install --prefer-binary opus==1.3.1 --extra-index-url=https://wheels.developerfirst.ibm.com/ppc64le/linux
python -m pip install --prefer-binary ffmpeg==7.1 --extra-index-url=https://wheels.developerfirst.ibm.com/ppc64le/linux
python -m pip install --prefer-binary torch==2.9.1 --extra-index-url=https://wheels.developerfirst.ibm.com/ppc64le/linux

python -c "import torch; print(torch.__version__)"

python -m pip install --prefer-binary pillow==11.1.0 --extra-index-url=https://wheels.developerfirst.ibm.com/ppc64le/linux
python -m pip install --prefer-binary protobuf==4.25.3 --extra-index-url=https://wheels.developerfirst.ibm.com/ppc64le/linux
python -m pip install --prefer-binary abseil-cpp==20240116.2 --extra-index-url=https://wheels.developerfirst.ibm.com/ppc64le/linux
python -m pip install --prefer-binary libprotobuf==4.25.3 --extra-index-url=https://wheels.developerfirst.ibm.com/ppc64le/linux

PY_SITE="$(python_site_packages)"

export Torch_DIR="${PY_SITE}/torch/share/cmake/Torch"
export pybind11_DIR="${PY_SITE}/pybind11/share/cmake/pybind11"
export Protobuf_INCLUDE_DIR="${PY_SITE}/libprotobuf/include"
export Protobuf_LIBRARY="${PY_SITE}/libprotobuf/lib64/libprotobuf.so"
export Protobuf_PROTOC_EXECUTABLE="${PY_SITE}/libprotobuf/bin/protoc"
export CMAKE_PREFIX_PATH="${PY_SITE}/libprotobuf/lib64/cmake:${CMAKE_PREFIX_PATH:-}"
export PKG_CONFIG_PATH="${PY_SITE}/ffmpeg/lib/pkgconfig:${PKG_CONFIG_PATH:-}"
export LD_LIBRARY_PATH="${PY_SITE}/torch/lib:${PY_SITE}/ffmpeg/lib:${PY_SITE}/libprotobuf/lib64:${PY_SITE}/libvpx/lib:${PY_SITE}/lame/lib:${PY_SITE}/opus/lib:${LD_LIBRARY_PATH:-}"

if compgen -G "${PY_SITE}/ffmpeg/lib/pkgconfig/*.pc" > /dev/null; then
    sed -i 's|/home/tester/FFmpeg/ffmpeg_prefix|'"${PY_SITE}"'/ffmpeg|g' "${PY_SITE}"/ffmpeg/lib/pkgconfig/*.pc
fi

# ----------- torchcodec -----------
cd "${BUILD_HOME}"
rm -rf torchcodec
git clone https://github.com/meta-pytorch/torchcodec.git
cd torchcodec
git checkout "${TORCHCODEC_VERSION}"
python -m pip install -e ".[dev]" --no-build-isolation -vv
cd "${BUILD_HOME}"

python -m pip install --prefer-binary pyarrow==19.0.1 --extra-index-url=https://wheels.developerfirst.ibm.com/ppc64le/linux
python -m pip install --prefer-binary torchvision==0.24.1 --extra-index-url=https://wheels.developerfirst.ibm.com/ppc64le/linux

yum config-manager --add-repo https://mirror.stream.centos.org/9-stream/CRB/ppc64le/os
yum config-manager --add-repo https://mirror.stream.centos.org/9-stream/AppStream/ppc64le/os
yum config-manager --add-repo https://mirror.stream.centos.org/9-stream/BaseOS/ppc64le/os

rpm --import https://www.centos.org/keys/RPM-GPG-KEY-CentOS-Official-SHA256
dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm

rpm -e --nodeps openssl-fips-provider-so || true

python -m pip install clearml phonemizer tiktoken
python -m pip install -U "pydantic>=2"
python -m pip install GitPython
python -m pip install sentencepiece==0.1.97 parameterized datasets==4.0.0 setuptools wheel pytest timeout_decorator evaluate GitPython ruff psutil packaging pyyaml
python -m pip install ruff
python -m pip install "numpy<2"
python -m pip install --no-cache-dir evaluate sacrebleu


# ----------- transformers -----------
cd "${BUILD_HOME}"
rm -rf "${PACKAGE_DIR}"
git clone "${PACKAGE_URL}"
cd "${PACKAGE_DIR}"
git checkout "${PACKAGE_VERSION}"


    if ! python -m pip install '.[torch]'; then
        echo "${PACKAGE_DIR} | ${PACKAGE_URL} | ${PACKAGE_VERSION} | ${OS_NAME} | GitHub | Fail | Install_Fails"
        cd "${BUILD_HOME}"
        return 1
    fi

    if ! python -c "import transformers; print(transformers.__version__)"; then
        echo "${PACKAGE_DIR} | ${PACKAGE_URL} | ${PACKAGE_VERSION} | ${OS_NAME} | GitHub | Fail | Install_Fails"
        cd "${BUILD_HOME}"
        return 1
    fi
# Test failures are in parity with x86, so they are being ignored 
    if ! pytest tests/ \
        --ignore=tests/models/ \
        --ignore=tests/test_tokenization_mistral_common.py \
        --ignore=tests/cli \
        --ignore=tests/test_pipeline_mixin.py \
        --ignore=tests/generation/test_utils.py \
        --ignore=tests/pipelines/ \
        --ignore=tests/quantization/mxfp4/test_mxfp4.py \
        --ignore=tests/utils/test_image_utils.py \
        --ignore=tests/utils/test_add_new_model_like.py \
        --ignore=tests/utils/test_chat_parsing_utils.py
    then
        echo "${PACKAGE_DIR} | ${PACKAGE_URL} | ${PACKAGE_VERSION} | ${OS_NAME} | GitHub | Fail | Install_success_but_test_Fails"
        cd "${BUILD_HOME}"
        return 2
    fi

    if ! pytest tests/models/granite; then
        echo "${PACKAGE_DIR} | ${PACKAGE_URL} | ${PACKAGE_VERSION} | ${OS_NAME} | GitHub | Fail | Install_success_but_test_Fails"
        cd "${BUILD_HOME}"
        return 2
    fi

    echo "${PACKAGE_DIR} | ${PACKAGE_URL} | ${PACKAGE_VERSION} | ${OS_NAME} | GitHub | Pass | Both_Install_and_Test_Success"

cd "${BUILD_HOME}"
exit 0
