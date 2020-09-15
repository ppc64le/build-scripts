# ----------------------------------------------------------------------------
#
# Package       : tweetnacl
# Version       : 1.0.0
# Source repo   : https://github.com/dchest/tweetnacl-js.git 
# Tested on     : ubuntu_18.04
# Script License: Apache License, Version 2 or later
# Maintainer    : Sandip Giri <sgiri@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

# Install dependencies.
sudo apt-get update -y
sudo apt-get install -y git nodejs npm


# Clone and build source.
git clone https://github.com/dchest/tweetnacl-js.git
cd tweetnacl-js
# Bypassed electron dependency which is not supported on ppc64le. 
sed -i  -e 's/devDependencies/optionalDependencies/' package.json
npm install
npm test

# This package also available with "npm install tweetnacl"

# Discussed with community , regarding bypassing the electron dependecy on ppc64le - https://github.com/dchest/tweetnacl-js/issues/146
# - It's only used for testing.In fact, it's a devDependency, so it shouldn't be installed by default if you use 'npm install tweetnacl'.
# - When you npm install tweetnacl as a dependency for your project, no devDeps would be installed. There's no need to clone the repo and npm install if you're not going to work the project itself or run tests.
# - If you want to run tests on your platform, what you did was right . just remove electron dependency, do npm install and run npm test. This will run tests with Node. Only npm run test-browser, which uses Electron, won't work.

