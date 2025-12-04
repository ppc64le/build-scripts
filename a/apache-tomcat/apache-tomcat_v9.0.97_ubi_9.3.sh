#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : tomcat
# Version       : 9.0.97
# Source repo   : https://github.com/apache/tomcat.git
# Tested on     : UBI 9.3 (ppc64le)
# Language      : Java
# Ci-Check  : false
# Script License: Apache License, Version 2 or later
# Maintainer    : Amit Kumar <amit.kumar282@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=tomcat
TOMCAT_VERSION=${1:-9.0.97}
TOMCAT_TAR="apache-${PACKAGE_NAME}-${TOMCAT_VERSION}.tar.gz"
TOMCAT_URL="https://archive.apache.org/dist/$PACKAGE_NAME/$PACKAGE_NAME-9/v${TOMCAT_VERSION}/bin/${TOMCAT_TAR}"
TOMCAT_DIR="/opt/tomcat"
TOMCAT_USER="tomcat"
TOMCAT_GROUP="tomcat"
TOMCAT_PORT=8080
TOMCAT_SERVICE="/etc/systemd/system/tomcat.service"

# Install required system dependencies
yum install -y unzip git wget java-17-openjdk java-17-openjdk-devel

export JAVA_HOME=/usr/lib/jvm/java-17-openjdk
export PATH=$PATH:$JAVA_HOME/bin

# Create tomcat group and user if not exist
groupadd -f $TOMCAT_GROUP
id -u "$TOMCAT_USER" &>/dev/null || useradd -g "$TOMCAT_GROUP" -m "$TOMCAT_USER"

# Download and extract Apache Tomcat to the target directory
cd /tmp
wget $TOMCAT_URL
mkdir -p $TOMCAT_DIR
tar -xvzf $TOMCAT_TAR -C $TOMCAT_DIR --strip-components=1
rm -f $TOMCAT_TAR

# Set ownership and executable permissions for Tomcat scripts
chown -R $TOMCAT_USER:$TOMCAT_GROUP $TOMCAT_DIR
chmod +x $TOMCAT_DIR/bin/*.sh

# Create a systemd service file for Tomcat and enable it to start on boot
cat > $TOMCAT_SERVICE <<EOF
[Unit]
Description=Apache Tomcat Web Application Container
After=network.target

[Service]
Type=forking
User=$TOMCAT_USER
Group=$TOMCAT_GROUP
Environment="JAVA_HOME=/usr/lib/jvm/java-17-openjdk"
Environment="CATALINA_PID=$TOMCAT_DIR/temp/tomcat.pid"
Environment="CATALINA_HOME=$TOMCAT_DIR"
Environment="CATALINA_BASE=$TOMCAT_DIR"
Environment="CATALINA_OPTS=-Xms512M -Xmx1024M -server -XX:+UseParallelGC"
Environment="JAVA_OPTS=-Djava.awt.headless=true -Djava.security.egd=file:/dev/./urandom"
ExecStart=$TOMCAT_DIR/bin/startup.sh
ExecStop=$TOMCAT_DIR/bin/shutdown.sh
PIDFile=$TOMCAT_DIR/temp/tomcat.pid
RestartSec=10
Restart=always
UMask=0007

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd, enable and start the Tomcat service
systemctl daemon-reload
systemctl enable tomcat.service
systemctl start tomcat.service

# Verify if the Tomcat service is running
if systemctl status tomcat.service | grep -q "active (running)"; then
    echo "[Pass]: Tomcat $TOMCAT_VERSION is installed and running successfully!"
else
    echo "[Error]: Tomcat installation failed or is not running."
fi

# Smoke Test - HTTP check on specified port
if curl -s http://localhost:$TOMCAT_PORT | grep -q "Apache Tomcat"; then
    echo "[Pass]: Tomcat $TOMCAT_VERSION web interface is reachable on port $TOMCAT_PORT."
else
    echo "[Error]: Tomcat is not responding on port $TOMCAT_PORT"
fi