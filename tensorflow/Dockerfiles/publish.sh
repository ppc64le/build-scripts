#!/bin/bash
set -e
OPTIND=1
DOCKER_SERVER="registry-1.docker.io"
SCRIPT_DIR=`dirname $0`
REPO='ibmcom/tensorflow-ppc64le'
DRY_RUN=false
BUILD_ONLY=false
DATE=$(date +%s)

usage() {
    cat <<EOM
Usage:
    -h                  Show this message
    -i                  Images type to build. Accepted values are: all, dev, nightly, or release.
    -t                  Image tag
    -d                  Dry run
    -b                  Build only
EOM
}

# Get input
while getopts "hi:t:df:b" opt; do
    case "$opt" in
    h)
        usage
        exit 0
        ;;
    i)  IMAGE=$OPTARG
        ;;
    t)  TAG=$OPTARG
        ;;
    d)  DRY_RUN=true
        ;;
    b)  BUILD_ONLY=true
        ;;
    esac
done

# Validate input
if [ -z $IMAGE ]; then
    echo "Missing -i (image) argument"
    exit 1
fi
if [ $IMAGE = "nightly" ]; then
    TAG="latest"
fi
if [ -z $TAG ]; then
    echo "Missing -t argument"
    exit 1
fi

if [[ ! "$IMAGE" =~ ^(all|nightly|release|dev)$ ]]; then
    echo "Invalid image type. Use all, dev, nightly, or release."
    exit 1
fi

build_push ()
{
    if $GPU; then
        ARG_SUFFIX="-gpu"
        FILE_PREFIX="gpu"
    else
        FILE_PREFIX="cpu"
        ARG_SUFFIX=""
    fi
    if [ $TYPE = "dev" ]; then
        DEV="-devel"
        TF_PACKAGE=""
    elif [ $TYPE = "release" ]; then
        TF_PACKAGE="--build-arg TF_PACKAGE=tensorflow${ARG_SUFFIX}"
        DATETIME="--build-arg DATETIME=${DATE}"
        DEV=""
    elif [ $TYPE = "nightly" ]; then
        TF_PACKAGE="--build-arg TF_PACKAGE=tf-nightly${ARG_SUFFIX}"
        DATETIME="--build-arg DATETIME=${DATE}"
        DEV=""
    fi
    if $PYTHON_3; then
        PYTHON="--build-arg USE_PYTHON_3_NOT_2=True"
        PY3="-py3"
    else
        PYTHON="--build-arg USE_PYTHON_3_NOT_2=False"
        PY3=""
    fi
    if $JUPYTER_ARG; then
        JUPYTER="-jupyter"
    else
        JUPYTER=""
    fi
    BUILD="docker build $TF_PACKAGE $DATETIME $PYTHON -f ${SCRIPT_DIR}/${FILE_PREFIX}${DEV}-ppc64le${JUPYTER}.Dockerfile -t ${DOCKER_SERVER}/${REPO}:${TAG}${ARG_SUFFIX}${DEV}${PY3}${JUPYTER} ${SCRIPT_DIR}"
    PUSH="docker push ${DOCKER_SERVER}/${REPO}:${TAG}${ARG_SUFFIX}${DEV}${PY3}${JUPYTER}"
    if $DRY_RUN; then
        echo $BUILD
        if ! $BUILD_ONLY; then
            echo $PUSH
        fi
    else
        $BUILD
        if ! $BUILD_ONLY; then
            $PUSH
        fi
    fi
}

if [ $IMAGE = "all" ]; then
    TYPE_LIST=("dev" "release")
else
    TYPE_LIST=($IMAGE)
fi
for GPU in {true,false}; do
    for TYPE in ${TYPE_LIST[@]}; do
        for PYTHON_3 in {true,false}; do
            for JUPYTER_ARG in {true,false}; do
                build_push
            done
        done
    done
done
