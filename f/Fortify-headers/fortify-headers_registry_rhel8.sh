# ----------------------------------------------------------------------------
#
# Package       : fortify-headers
# Version       : 1.1
# Source repo   : https://github.com/libertine-linux-mirrors/fortify-headers.git
# Tested on     : RHEL8
# Script License: Apache License, Version 2 or later
# Maintainer    : Amit Shirodkar <amit.shirodkar@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#!/bin/bash
cat > fgets.c <<EOF
#include <stdio.h>
int
main(void)
{
        char buf[BUFSIZ];
        fgets(buf, sizeof(buf) + 1, stdin);
        return 0;
}
EOF
cc -I /include/ -D_FORTIFY_SOURCE=1 -O1 fgets.c
./a.out
