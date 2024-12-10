#!/bin/bash -e
# ----------------------------------------------------------------------------- 
#
# Package          : flask
# Version          : 3.0.0
# Source repo      : https://github.com/pallets/flask
# Tested on	: {distro_name} {distro_version}
# Language : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Shubham Garud <>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=flask
PACKAGE_VERSION=${1:-3.0.0}
PACKAGE_URL=https://github.com/pallets/flask
technology_version=${technology_version}
GITHUB_PASSWORD=${GITHUB_PASSWORD}
GITHUB_USERNAME=${GITHUB_USERNAME}

IFS=',' read -r -a python_versions <<< "$technology_version"

result_list=()
cd /home/tester
mkdir -p output

OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

SOURCE=Github

WORKDIR=$(pwd)

TEMP_VER_SCRIPT=$WORKDIR/temp_package_ver_script.sh
TEMP_SCRIPT=$WORKDIR/temp_package_script.sh

function test_via_tox(){
    if ! python -m tox -e "$python_version"; then
        echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME " > $WORKDIR/output/test_fails
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE | Fail | Install_success_but_test_Fails" > $WORKDIR/output/version_tracker
        result_list+=("\"Py$python_version|$PACKAGE_VERSION\"")
        return 2
    else
        echo "------------------$PACKAGE_NAME:install_and_test_both_success-------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME " > $WORKDIR/output/test_success
        echo "$PACKAGE_NAME | $PACKAGE_URL  | $PACKAGE_VERSION | $OS_NAME | $SOURCE  | Pass |  Both_Install_and_Test_Success" >> $WORKDIR/output/version_tracker
        result_list+=("\"Py$python_version|$PACKAGE_VERSION\"")
        return 0
    fi
}

function test_via_pytest(){
    if ! python -m pytest -v; then
        echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME " > $WORKDIR/output/test_fails
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE | Fail | Install_success_but_test_Fails" > $WORKDIR/output/version_tracker
        result_list+=("\"Py$python_version|$PACKAGE_VERSION\"")
        return 2
    else
        echo "------------------$PACKAGE_NAME:install_and_test_both_success-------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME " > $WORKDIR/output/test_success
        echo "$PACKAGE_NAME  |  $PACKAGE_URL  | $PACKAGE_VERSION | $OS_NAME | $SOURCE  | Pass |  Both_Install_and_Test_Success" >> $WORKDIR/output/version_tracker
        result_list+=("\"Py$python_version|$PACKAGE_VERSION\"")
        return 0
    fi
}

function test_via_nox(){
    if ! python -m nox; then
        echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME " > $WORKDIR/output/test_fails
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE | Fail | Install_success_but_test_Fails" > $WORKDIR/output/version_tracker
        result_list+=("\"Py$python_version|$PACKAGE_VERSION\"")
        return 2
    else
        echo "------------------$PACKAGE_NAME:install_and_test_both_success-------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME " > $WORKDIR/output/test_success
        echo "$PACKAGE_NAME  |  $PACKAGE_URL  | $PACKAGE_VERSION | $OS_NAME | $SOURCE  | Pass |  Both_Install_and_Test_Success" >> $WORKDIR/output/version_tracker
        result_list+=("\"Py$python_version|$PACKAGE_VERSION\"")
        return 0
    fi
}

function test_package(){
    if [ -f tox.ini ]; then
        test_via_tox
    elif [ -f noxfile.py ]; then
        test_via_nox
    else
        test_via_pytest
    fi
    cd ..
}

function generic_instructions(){
    if [[ "$PACKAGE_URL" == *github.com* ]]; then
        # Use git clone if it's a Git repository
        if [ -d "$PACKAGE_NAME" ]; then
            cd "$PACKAGE_NAME" || return 1
        else
            if ! git clone "$PACKAGE_URL" "$PACKAGE_NAME"; then
                echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
                echo "$PACKAGE_URL $PACKAGE_NAME" > "$WORKDIR/output/clone_fails"
                echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE | Fail | Clone_Fails" > "$WORKDIR/output/version_tracker"
                return 1
            fi
            cd "$PACKAGE_NAME"
            git checkout "$PACKAGE_VERSION" || return 1
        fi
    else
        # If it's not a Git repository, download and untar
        if [ -d "$PACKAGE_NAME" ]; then
            cd "$PACKAGE_NAME" || return 1
        else
            # Use download and untar if it's not a Git repository
            if ! curl -L "$PACKAGE_URL" -o "$PACKAGE_NAME.tar.gz"; then
                echo "------------------$PACKAGE_NAME:download_fails---------------------------------------"
                echo "$PACKAGE_URL $PACKAGE_NAME" > "$WORKDIR/output/download_fails"
                echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE | Fail | Download_Fails" > "$WORKDIR/output/version_tracker"
                return 1
            fi
            mkdir "$PACKAGE_NAME"
            # Extract the downloaded tarball
            if ! tar -xzf "$PACKAGE_NAME.tar.gz" -C "$PACKAGE_NAME" --strip-components=1; then
                echo "------------------$PACKAGE_NAME:untar_fails---------------------------------------"
                echo "$PACKAGE_URL $PACKAGE_NAME" > "$WORKDIR/output/untar_fails"
                echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE | Fail | Untar_Fails" > "$WORKDIR/output/version_tracker"
                return 1
            fi

            cd "$PACKAGE_NAME" || return 1
        fi
    fi

    # Install via pip
    if ! python -m pip install .; then
        echo "------------------$PACKAGE_NAME:install_fails------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME" > "$WORKDIR/output/install_fails"
        echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE | Fail | Install_Failed" > "$WORKDIR/output/version_tracker"
        return 1
    fi

    return 0
}

function pull_latest_build_scripts(){
    if ! cd ../build-scripts/ && git checkout master && git pull && cd ../tester/; then
        echo "Cannot pull build-scripts"
    fi
}

# Function to delete unwanted lines from build scripts
function format_build_script() {

    local repo_script_path="$1"
    local temp_script_path="$2"

    # Copy $BUILD_SCRIPT_PATH file and save it as $temp_script_path
    cp "$repo_script_path" "$temp_script_path"

    # Replace "python3 " with "python " and "pip3 " with "pip " in the copied file
    sed -i 's/python3 /python /g' "$temp_script_path"
    sed -i 's/pip3 /pip /g' "$temp_script_path"

    # Replace lines like "pythonX.Y -m pip" with "pip "
    sed -i 's/\bpython[0-9]\+\.[0-9]\+ -m pip /pip /g' "$temp_script_path"

    # Remove lines containing the "-m venv" command
    sed -i '/-m venv/d' "$temp_script_path"

    # Remove lines starting with "source " and ending with "/bin/activate"
    sed -i '/bin\/activate/d' "$temp_script_path"

    # Remove lines containing only the "deactivate" command
    sed -i '/^deactivate$/d' "$temp_script_path"

    # Remove exit status so that script will continue to work
    sed -i '/exit [0-9]/d' "$temp_script_path" 
}

function find_and_format_build_scripts(){
    BUILD_SCRIPT_PATH=`python3 -c "import glob; print(glob.glob('../build-scripts/' + '$PACKAGE_NAME'[0] + '/$PACKAGE_NAME/*ubi*.sh')[0])"`

    BUILD_SCRIPT_VERSION_PATH=`python3 -c "import glob; print(glob.glob('../build-scripts/' + '$PACKAGE_NAME'[0] + '/$PACKAGE_NAME/*$PACKAGE_NAME_$PACKAGE_VERSION*ubi*.sh')[0])"`

    if [[ -n "$BUILD_SCRIPT_VERSION_PATH" ]]; then
        # If only $BUILD_SCRIPT_VERSION_PATH is set, process that script
        format_build_script "$BUILD_SCRIPT_VERSION_PATH" "$TEMP_VER_SCRIPT"
    fi
    
    if [[ -n "$BUILD_SCRIPT_PATH" ]]; then
        # If only $BUILD_SCRIPT_PATH is set, process that script
        format_build_script "$BUILD_SCRIPT_PATH" "$TEMP_SCRIPT"
    fi
    
}

function run_build_scripts(){
    echo "Running with formatted build scripts..."
    # Remove the package file if its already cloned
    rm -rf $PACKAGE_NAME
    if ! sh "$TEMP_VER_SCRIPT"; then
        echo "------------------$PACKAGE_NAME:package_cannot_be_with_specific_version---------------------"
        
        if grep -qF "PACKAGE_VERSION=${1:-}" "$TEMP_SCRIPT"; then
            if ! sh "$TEMP_SCRIPT" "$PACKAGE_VERSION"; then
                echo "------------------$PACKAGE_NAME:package_cannot_be_validated_using_version---------------------"
                echo "$PACKAGE_URL $PACKAGE_NAME" > "$WORKDIR/output/test_fails"
                echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE | Fail | Install_failed_test_Fails" > "$WORKDIR/output/version_tracker"
                return 2
            else
                echo "------------------$PACKAGE_NAME:package_can_be_validated_using_version-------------------------"
                echo "$PACKAGE_URL $PACKAGE_NAME" > "$WORKDIR/output/test_success"
                echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE | Pass | Both_Install_and_Test_Success" > "$WORKDIR/output/version_tracker"
                result_list+=("\"Py$python_version|$PACKAGE_VERSION\"")
                return 0
            fi
        else
            echo "------------------$PACKAGE_NAME:build_script_does_not_have_variable_version-------------------------"
            echo "$PACKAGE_URL $PACKAGE_NAME" > "$WORKDIR/output/test_fails"
            echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE | Fail | Install_failed_test_Fails" > "$WORKDIR/output/version_tracker"
            return 2
        fi
    else
        echo "------------------$PACKAGE_NAME:package_ran_with_its_version_script-------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME" > "$WORKDIR/output/test_success"
        echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE | Pass | Both_Install_and_Test_Success" > "$WORKDIR/output/version_tracker"
        result_list+=("\"Py$python_version|$PACKAGE_VERSION\"")
        return 0
    fi

}

function update_remote_url(){
    REMOTE_URL=$(git remote get-url origin)

    BASE_URL=$(echo "$REMOTE_URL" | sed -E 's#https://##' | sed -E 's#^.*@##')

    # Construct the expected URL with the username and password (or token)
    EXPECTED_URL="https://${GITHUB_USERNAME}:${GITHUB_PASSWORD}@${BASE_URL}"

    # Check if the remote URL already includes the correct username and password/token
    if [[ "$REMOTE_URL" == "$EXPECTED_URL" ]]; then
        echo "The remote URL is already set."
    else
        # If not, update the remote URL with the username and password
        git remote set-url origin "$EXPECTED_URL"
        echo "New remote URL is updated."
    fi
}

function raise_auto_pr(){
    cd ../build-scripts
    update_remote_url
    # auto_pr_env already set in dockerfile, activating it to execute node_bs.py
    source ../auto_pr_env/bin/activate
    python3 script/node_bs.py --package_name_arg "$PACKAGE_NAME" --package_version_arg "$PACKAGE_VERSION" --github_url_arg "$PACKAGE_URL" --language_arg "python"  --generate_wheel_arg  --commit_files_arg  --github_username_arg "$GITHUB_USERNAME" --github_token_arg "$GITHUB_PASSWORD" --create_PR_arg
}

cd $WORKDIR

pull_latest_build_scripts

find_and_format_build_scripts

cd $WORKDIR

# Loop through each Python version
for python_version in "${python_versions[@]}"; do
    echo "Processing $PACKAGE_NAME==$PACKAGE_VERSION with Python Version$python_version and Package_URL: $PACKAGE_URL"

    # Python version check
    python$python_version --version
    if command -v "python$python_version" &>/dev/null; then
        echo "$python_version available"
    else
        echo "$python_version not available"
        break
    fi

    # Create a virtual environment directory
    VENV_DIR="venv_$python_version"
    "python$python_version" -m venv --system-site-packages "$WORKDIR/$VENV_DIR"
    source "$WORKDIR/$VENV_DIR/bin/activate"

    # REMOVE
    python -m pip install hypothesis


    if [ -s "$TEMP_VER_SCRIPT" ] || [ -s "$TEMP_SCRIPT" ]; then
        # Run already available build-scripts
        run_build_scripts
    else
        # Install package from source
        generic_instructions
        if [ $? -eq 0 ]; then
            echo "Package installed successfully running test suite..."
            # Test the package
            test_package
        fi
    fi

    deactivate
    echo "Virtual Environment Deactivated"

    # Remove the virtual environment
    rm -rf $VENV_DIR
done

# Store the result in json format
json_output=$(printf '[%s]' "$(IFS=', '; echo "${result_list[*]}")")

# Save the JSON result to a file
echo "$json_output" > "$WORKDIR/output/result.json"
echo "Result saved in $WORKDIR/output/result.json"

all_versions_matched=true

# Loop through each version in the array
for python_version in "${python_versions[@]}"; do
    # Construct the string for "Py3.x" (e.g., "Py3.9")
    py_string="Py$python_version"

    # Check if "Py3.x" is present in the result.json file
    if grep -q "$py_string" "$WORKDIR/output/result.json"; then
        all_versions_matched=true
    else
        # If any version fails to match, set all_versions_matched to false
        all_versions_matched=false
        break
    fi
done

if [ "$all_versions_matched" = true ]; then
    raise_auto_pr
else
    echo "Automatic PR was not raised"
fi
