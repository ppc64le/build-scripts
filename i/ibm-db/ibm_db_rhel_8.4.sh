# -----------------------------------------------------------------------------
#
# Package       : ibm_db
# Version       : 3.0.2
# Source repo   : https://github.com/ibmdb/python-ibmdb.git
# Tested on     : RHEL 8.4
# Language      : Python
# Travis-Check  : True
# Script License: Apache License Version 2.0
# Maintainer    : sachin.kakatkar@ibm.com
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#Run the script:./ibm_db_rhel_8.4.sh
#!/usr/bin/env bash

#pull and create db2 instance
docker pull ibmcom/db2
docker run --name db2 -itd --privileged=true -p 50000:50000 -e LICENSE=accept -e DB2INST1_PASSWORD=password -e DBNAME=sample -v $HOME/database:/database ibmcom/db2
docker ps -as
docker exec -it db2 useradd -ms /bin/bash auth_user -p auth_pass

while true
do
  if (docker logs db2 | grep 'Setup has completed')
  then
      break
  fi

  sleep 20
done
#Run db2 and ibm python-db
docker exec -i db2 bash <ibm-db.sh
