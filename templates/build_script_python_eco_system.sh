#!/bin/bash

PACKAGE_NAME=$1
PACKAGE_VERSION=${2:-$1}
PACKAGE_URL=$3

# Function to run tox
run_tox(){
    tox
    return $?
}

# Function to run pytest
run_pytest() {
    pytest
    return $?
}
 
# Function to run nox
run_nox() {
    nox
    return $?
}
 
# Function to handle git repository
clone_and_build_from_git() {
    if [ -d "$PACKAGE_NAME" ]; then
        cd $PACKAGE_NAME || exit
    else
        if ! git clone $PACKAGE_URL $PACKAGE_NAME; then
            echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
            exit 1
        fi
        cd $PACKAGE_NAME || exit
    fi
 
    git checkout $PACKAGE_VERSION
    build_and_test
}

# Function to handle tarball
download_and_build_from_tar() {
    if [ -d "$PACKAGE_NAME" ]; then
        cd $PACKAGE_NAME || exit
    else
        if ! curl -L $PACKAGE_URL -o $PACKAGE_NAME.tar.gz; then
            echo "------------------$PACKAGE_NAME:download_fails---------------------------------------"
            exit 1
        fi
            mkdir $PACKAGE_NAME
            tar -xzf $PACKAGE_NAME.tar.gz -C $PACKAGE_NAME --strip-components=1
            cd $PACKAGE_NAME
        fi
 
        build_and_test
}
 
# Function to build and test the package
build_and_test() {
    REQUIREMENTS_FILE=$(find . -type f -name '*requirement*.txt' -print -quit)
    if [ -f "$REQUIREMENTS_FILE" ]; then
        echo "============= Installing dependencies ================"
        pip install -r "$REQUIREMENTS_FILE"
        echo "============= Installed dependencies ==============="
    else
        echo "No requirements file found."
    fi
    
    #To install dependencies from setup.py or pyproject.toml
    pip install .

    # Flag to track if any test command passes without errors
    success=false
    test_found=false
    wheel_built=true
    echo "=============== Starting Tests =================="
    # Check for tox.ini and run tox 
    if [ -f "tox.ini" ]; then
        test_found=true
        if run_tox; then
            echo "tox succeeded"
            success=true
        else
            echo "tox failed"
        fi

    # check for noxfile.py and run nox
    elif [ -f "noxfile.py" ]; then
        test_found=true
        if run_nox; then
            echo "nox succeeded"
            success=true
        else
            echo "nox failed"
        fi

    #check for tests inside package folder
    elif [ -d "$PACKAGE_NAME/tests" ]; then
        cd $PACKAGE_NAME
        test_found=true
        if run_pytest; then
            echo "pytest succeeded"
            success=true
        else
            echo "pytest failed"
        fi

    #check for pytest.ini and run pytest
    elif [ -f "pytest.ini" ] || [ -d "tests" ] || [ -d "test"]; then
        test_found=true
        if run_pytest; then
            echo "pytest succeeded"
            success=true
        else
            echo "pytest failed"
        fi
    fi
    echo " ============== Tests Done ================"
}
 
{
# Determine URL type and process accordingly
if [[ $PACKAGE_URL == *.git ]]; then
    clone_and_build_from_git
else
    download_and_build_from_tar
fi

if ! python -m build --wheel --outdir=../wheels/; then
    echo "============ $PACKAGE_NAME : Wheel Creation Failed  ================="
    exit 1
else
    exit 0
fi
}