#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : pre-commit
# Version       : v2.12.1,v2.17.0
# Source repo   : https://github.com/pre-commit/pre-commit
# Tested on     : UBI: 8.5
# Language      : Python
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Vathsala .<vaths367@in.ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=pre-commit
PACKAGE_VERSION=${1:-v2.17.0}
PACKAGE_URL=https://github.com/pre-commit/pre-commit

yum install -y python36 python36-devel git python2 python2-devel python3 python3-devel ncurses git gcc gcc-c++ libffi libffi-devel sqlite sqlite-devel sqlite-libs python3-pytest make cmake

mkdir -p /home/tester
cd /home/tester

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION


pip3 install -U wheel

pip3 install -U setuptools

pip3 install tox

pip3 install pre-commit
OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

if ! tox -e py36 ; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails"
    exit 1
else
    echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi

#Tests are failing and are in Parity with Intel

#tests/clientlib_test.py .............................................................                                                                 [  8%]
#tests/color_test.py .........                                                                                                                         [  9%]
#tests/envcontext_test.py ............                                                                                                                 [ 11%]
#tests/error_handler_test.py .........F                                                                                                                [ 13%]
#tests/git_test.py .............................                                                                                                       [ 17%]
#tests/logging_handler_test.py ..                                                                                                                      [ 17%]
#tests/main_test.py ......s....................                                                                                                        [ 21%]
#tests/output_test.py .                                                                                                                                [ 21%]
#tests/parse_shebang_test.py .............FF...                                                                                                        [ 23%]
#tests/prefix_test.py .........                                                                                                                        [ 25%]
#tests/repository_test.py FFF.......ssssss....FFFFFFF.sFFFFFFF..............F.FFF................FFFFFFF..FF                                           [ 36%]
#tests/staged_files_only_test.py ...................................                                                                                   [ 41%]
#tests/store_test.py ...................F                                                                                                              [ 44%]
#tests/util_test.py ..............                                                                                                                     [ 46%]
#tests/xargs_test.py ....................xxx                                                                                                           [ 49%]
#tests/commands/autoupdate_test.py ...............................                                                                                     [ 54%]
#tests/commands/clean_test.py ..                                                                                                                       [ 54%]
#tests/commands/gc_test.py ........                                                                                                                    [ 55%]
#tests/commands/hook_impl_test.py ...................................                                                                                  [ 60%]
#tests/commands/init_templatedir_test.py .......                                                                                                       [ 61%]
#tests/commands/install_uninstall_test.py ......................................................                                                       [ 69%]
#tests/commands/migrate_config_test.py .....                                                                                                           [ 69%]
#tests/commands/run_test.py ...........................................................................................                                [ 82%]
#tests/commands/sample_config_test.py .                                                                                                                [ 83%]
#tests/commands/try_repo_test.py .......                                                                                                               [ 83%]
#tests/languages/conda_test.py ...                                                                                                                     [ 84%]
#tests/languages/docker_test.py ..............                                                                                                         [ 86%]
#tests/languages/golang_test.py ........                                                                                                               [ 87%]
#tests/languages/helpers_test.py ................                                                                                                      [ 89%]
#tests/languages/node_test.py ...FFF                                                                                                                   [ 90%]
#tests/languages/pygrep_test.py ................                                                                                                       [ 92%]
#tests/languages/python_test.py ..................

#FAILED tests/languages/node_test.py::test_healthy_system_node - pre_commit.util.CalledProcessError: command: ('/home/tester/pre-commit/.tox/py36/bin/pytho...
#FAILED tests/languages/node_test.py::test_unhealthy_if_system_node_goes_missing - pre_commit.util.CalledProcessError: command: ('/home/tester/pre-commit/....
#FAILED tests/languages/node_test.py::test_installs_without_links_outside_env - pre_commit.util.CalledProcessError: command: ('/home/tester/pre-commit/.tox...
#FAILED tests/languages/ruby_test.py::test_install_ruby_system - pre_commit.util.CalledProcessError: command: ('gem', 'build', 'placeholder_gem.gemspec')
#FAILED tests/languages/ruby_test.py::test_install_ruby_default - pre_commit.util.CalledProcessError: command: ('gem', 'build', 'placeholder_gem.gemspec')
#FAILED tests/languages/ruby_test.py::test_install_ruby_with_version - pre_commit.util.CalledProcessError: cmmand: ('/usr/bin/bash', '/tmp/pytest-of-root/...
#============================================ 40 failed, 655 passed, 8 skipped, 3 xfailed in 680.98s (0:11:20) ==============================================
#ERROR: InvocationError for command /home/tester/pre-commit/.tox/py36/bin/coverage run -m pytest tests (exited with code 1)



