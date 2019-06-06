#!/bin/bash
set -e
OPTIND=1
DOCKER_SERVER="registry-1.docker.io"
SCRIPT_DIR=`dirname $0`
REPO='ibmcom/tensorflow-ppc64le'
DRY_RUN=false
BUILD_ONLY=false
SKIP_PULL=false
DATE=$(date +%s)
IMAGE="all"

usage() {
    cat <<EOM
Usage:
    -h                  Show this message
    -r                  Release type to build. Accepted values are: all, dev, nightly, or release.
    -i                  Image type to build. Accepted values are: all, cpu, or gpu.
    -t                  Image tag
    -d                  Dry run
    -b                  Build only
    -s                  Skip pull of latest image before build
EOM
}

# Get input
while getopts "hi:r:t:dbs" opt; do
    case "$opt" in
    h)
        usage
        exit 0
        ;;
    i)  IMAGE=$OPTARG
        ;;
    r)  RELEASE_FLAG=$OPTARG
        ;;
    t)  TAG=$OPTARG
        ;;
    d)  DRY_RUN=true
        ;;
    b)  BUILD_ONLY=true
        ;;
    s)  SKIP_PULL=true
        ;;
    esac
done

# Validate input
if [ -z $RELEASE_FLAG ]; then
    echo "Missing -r (release) argument"
    exit 1
fi
if [ $RELEASE_FLAG = "nightly" ]; then
    TAG="latest"
fi
if [ -z $TAG ]; then
    echo "Missing -t argument"
    exit 1
fi

if [[ ! "$RELEASE_FLAG" =~ ^(all|nightly|release|dev)$ ]]; then
    echo "Invalid release type. Use all, dev, nightly, or release."
    exit 1
fi

if [ ! $TAG = "latest" ]; then
    SKIP_PULL=true
fi

build_push ()
{
    if [ $TYPE = "gpu" ]; then
        ARG_SUFFIX="-gpu"
        FILE_PREFIX="gpu"
    elif [ $TYPE = "cpu" ]; then
        FILE_PREFIX="cpu"
        ARG_SUFFIX=""
    fi
    if [ $RELEASE = "dev" ]; then
        DEV="-devel"
        TF_PACKAGE=""
    elif [ $RELEASE = "release" ]; then
        TF_PACKAGE="--build-arg TF_PACKAGE=tensorflow${ARG_SUFFIX}"
        CACHE_STOP="--build-arg CACHE_STOP=${DATE}"
        DEV=""
    elif [ $RELEASE = "nightly" ]; then
        TF_PACKAGE="--build-arg TF_PACKAGE=tf-nightly${ARG_SUFFIX}"
        CACHE_STOP="--build-arg CACHE_STOP=${DATE}"
        DEV=""
    fi
    if $PYTHON_3; then
        PYTHON="--build-arg USE_PYTHON_3_NOT_2=True"
        PY3="-py3"
    else
        PYTHON="--build-arg USE_PYTHON_3_NOT_2="
        PY3=""
    fi
    if $JUPYTER_ARG; then
        JUPYTER="-jupyter"
    else
        JUPYTER=""
    fi
    if $SKIP_PULL; then
        CACHE_FROM=""
    else
        CACHE_FROM="--cache-from=${DOCKER_SERVER}/${REPO}:${TAG}${ARG_SUFFIX}${DEV}${PY3}${JUPYTER}"
    fi
    PULL="docker pull ${DOCKER_SERVER}/${REPO}:${TAG}${ARG_SUFFIX}${DEV}${PY3}${JUPYTER}"
    BUILD="docker build $TF_PACKAGE $CACHE_STOP $PYTHON $CACHE_FROM -f ${SCRIPT_DIR}/${FILE_PREFIX}${DEV}-ppc64le${JUPYTER}.Dockerfile -t ${DOCKER_SERVER}/${REPO}:${TAG}${ARG_SUFFIX}${DEV}${PY3}${JUPYTER} ${SCRIPT_DIR}"
    PUSH="docker push ${DOCKER_SERVER}/${REPO}:${TAG}${ARG_SUFFIX}${DEV}${PY3}${JUPYTER}"
    if $DRY_RUN; then
        if ! $SKIP_PULL; then
            echo $PULL
        fi
        echo $BUILD
        if ! $BUILD_ONLY; then
            echo $PUSH
        fi
    else
        if ! $SKIP_PULL; then
            $PULL
        fi
        $BUILD
        if ! $BUILD_ONLY; then
            $PUSH
        fi
    fi
}

if [ $RELEASE_FLAG = "all" ]; then
    RELEASE_LIST=("dev" "release")
else
    RELEASE_LIST=($RELEASE_FLAG)
fi
if [ -z $IMAGE ] || [ $IMAGE = "all" ]; then
    TYPE_LIST=("gpu" "cpu")
else
    TYPE_LIST=($IMAGE)
fi
for TYPE in  ${TYPE_LIST[@]}; do
    for RELEASE in ${RELEASE_LIST[@]}; do
        for PYTHON_3 in {true,false}; do
            for JUPYTER_ARG in {true,false}; do
                build_push
            done
        done
    done
done
