# ----------------------------------------------------------------------------
#
# Package       : caarlos0/env [caarlos0-env] 
# Version       : v6.7.2
# Tested on     : UBI 8.3
# Script License: Apache-2.0 License    
# Maintainer    : Varsha Aaynure <Varsha.Aaynure@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#!/bin/bash

yum update -y 

#Install required files
yum install -y golang

#Cloning Repo
go get github.com/caarlos0/env/v6
cd /root/go/pkg/mod/github.com/caarlos0/env/v6\@v6.7.2/

#Build test package
go build -v ./...
go test -v ./...

echo "Complete!"
