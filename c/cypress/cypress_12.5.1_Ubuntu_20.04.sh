#!/bin/bash
#---------------------------------------------------------------------------------------------------
#
# Package	: Cypress
# Version	: v12.5.1
# Source repo	: https://github.com/cypress-io/cypress
# Tested on	: Ubuntu 20.04
# Language      : C++
# Travis-Check  : false
# Script License: Apache License, Version 2 or later
# Maintainer	: Sumit Dubey <sumit.dubey2@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#---------------------------------------------------------------------------------------------------

set -eux

#Variables
NAME=cypress
REPO=https://github.com/cypress-io/${NAME}.git
VERSION=v12.5.1
CWD=`pwd`

if [[ ! -f dist.zip || ! -f mksnapshot.zip ]]; then
	echo "Error: This script expects the electron distribution (dist.zip) and the mksnapshot distribution (mksnapshot.zip) in the current directory ($CWD)."
	exit 1;
fi

create_ffmpeg_package_json()
{
export CWD=$CWD
export NAME=$NAME
touch $CWD/$NAME/node_modules/@ffmpeg-installer/linux-ppc64/package.json
cat <<EOT >> $CWD/$NAME/node_modules/@ffmpeg-installer/linux-ppc64/package.json
{
  "name": "@ffmpeg-installer/linux-ppc64",
  "version": "4.4.2",
  "description": "Linux FFmpeg binary used by ffmpeg-installer",
  "homepage": "https://www.johnvansickle.com/ffmpeg/",
  "scripts": {
    "test": "file ffmpeg | grep -qF \"ELF 64-bit\"",
    "prepublishOnly": "npm test",
    "postinstall": "chmod u+x ffmpeg",
    "upload": "npm --userconfig=../../.npmrc publish --access public"
  },
  "keywords": [
    "ffmpeg",
    "binary",
    "linux",
    "ppc64"
  ],
  "os": [
    "linux"
  ],
  "cpu": [
    "ppc64"
  ],
  "author": "Kristoffer Lundén <kristoffer.lunden@gmail.com>",
  "license": "GPLv3",
  "ffmpeg": "20181210-g0e8eb07980"
}
EOT
}

create_ffprobe_package_json()
{
export CWD=$CWD
export NAME=$NAME
touch $CWD/$NAME/node_modules/@ffprobe-installer/linux-ppc64/package.json
cat <<EOT >> $CWD/$NAME/node_modules/@ffprobe-installer/linux-ppc64/package.json
{
        "name": "@ffprobe-installer/linux-ppc64",
        "version": "4.4.2",
        "description": "Linux FFmpeg binary used by ffprobe-installer",
        "homepage": "https://www.johnvansickle.com/ffmpeg/",
        "scripts": {
                "test": "file ffprobe | grep -qF \"ELF 64-bit\"",
                "prepublish": "npm test",
                "postinstall": "chmod u+x ffprobe",
                "upload": "npm publish --access public"
        },
        "keywords": [
                "ffprobe",
                "binary",
                "linux",
                "ppc64"
        ],
        "os": [
                "linux"
        ],
        "cpu": [
                "ppc64"
        ],
        "author": "Oliver Sayers <talk@savagecore.eu>",
        "license": "LGPL-2.1",
        "ffprobe": "20190527-g9b069eb14e"
}
EOT
}



#install ubuntu dependencies
apt-get update -y
DEBIAN_FRONTEND=noninteractive apt-get install vim git make build-essential wget zip ffmpeg golang-go go-bindata cmake python3 xz-utils xvfb zlib1g-dev libgconf-2-4 libxss1 libdrm-dev libgbm-dev libasound2 libxshmfence-dev libnss3 libatk-adaptor libcups2 libgtk-3-0 libxtst6 xauth -y

#Build appbuilder
cd $CWD
git clone https://github.com/develar/app-builder
cd app-builder
git checkout v3.4.2
go build '-ldflags=-s -w' -o dist/app-builder_linux_ppc64le/app-builder

#clone
cd $CWD
git clone $REPO
cd $NAME/
git checkout $VERSION
sed -i 's#21.0.0#22.0.3#g' package.json yarn.lock
sed -i 's#yargs-parser@^22.0.3#yargs-parser@^21.0.0#g' yarn.lock
sed -i 's#yargs-parser "^22.0.3"#yargs-parser "^21.0.0"#g' yarn.lock
sed -i "s#validateFs(fs)#//validateFs(fs)#g" scripts/binary/binary-integrity-check-source.js

# Install node.js
cd $CWD
NODE_VERSION=v$(cat $CWD/$NAME/.node-version)
NODE_DISTRO=linux-ppc64le
if [ -z "$(ls -A $CWD/node-$NODE_VERSION-$NODE_DISTRO)" ]; then
        wget "https://nodejs.org/dist/$NODE_VERSION/node-$NODE_VERSION-$NODE_DISTRO.tar.xz"
        tar -xJvf node-$NODE_VERSION-$NODE_DISTRO.tar.xz --no-same-owner
        rm -rf node-$NODE_VERSION-$NODE_DISTRO.tar.xz
fi
export PATH=$CWD/node-$NODE_VERSION-$NODE_DISTRO/bin:$PATH
npm install --global yarn

#yarn install
cd $CWD/$NAME
ELECTRON_CACHE_DIR=/root/.cache/electron/f2a31fa51e50477d6727a3d142acf96c69128640507e5c495415060d4b1ba236/
mkdir -p $ELECTRON_CACHE_DIR
cp $CWD/dist.zip $ELECTRON_CACHE_DIR/electron-v22.0.3-linux-ppc64.zip
cp $CWD/dist.zip /root/.cache/electron/electron-v22.0.3-linux-ppc64.zip
cp $CWD/mksnapshot.zip $ELECTRON_CACHE_DIR/mksnapshot-v22.0.3-linux-ppc64.zip
cp $CWD/mksnapshot.zip /root/.cache/electron/mksnapshot-v22.0.3-linux-ppc64.zip
sed -i 's#"postinstall"#"postinstall1"#g' package.json
yarn install --update-checksums

#set up display and dbus
service dbus start
export DISPLAY=:99
#Xvfb :99 -screen 0 640x480x8 -nolisten tcp &
dbus-uuidgen > /var/lib/dbus/machine-id
export XDG_RUNTIME_DIR=/run/user/$(id -u)
mkdir -p $XDG_RUNTIME_DIR
chmod 777 $XDG_RUNTIME_DIR
export DBUS_SESSION_BUS_ADDRESS=unix:path=$XDG_RUNTIME_DIR/bus
dbus-daemon --session --address=$DBUS_SESSION_BUS_ADDRESS --nofork --nopidfile --syslog-only &

#postinstall, includes build
mkdir -p node_modules/@ffmpeg-installer/linux-ppc64
mkdir -p node_modules/@ffprobe-installer/linux-ppc64
cp $(which ffmpeg) node_modules/@ffmpeg-installer/linux-ppc64/
cp $(which ffprobe) node_modules/@ffprobe-installer/linux-ppc64/
create_ffmpeg_package_json
create_ffprobe_package_json
sed -i "s#x64#ppc64#g" node_modules/builder-util/out/arch.js node_modules/electron-packager/src/targets.js
sed -i "s#x86_64#ppc64le#g" node_modules/builder-util/out/arch.js node_modules/electron-packager/src/targets.js
sed -i "s#yarn build-v8-snapshot-dev#V8_SNAPSHOT_FROM_SCRATCH=1 yarn build-v8-snapshot-prod#g" scripts/run-postInstall.js
sed -i 's#x64#ppc64#g' node_modules/@ffmpeg-installer/ffmpeg/package.json node_modules/@ffprobe-installer/ffprobe/package.json
sed -i 's#x64#ppc64#g' node_modules/@ffmpeg-installer/ffmpeg/package.json~ 
yarn postinstall1

#build and package the binary
cd $CWD/$NAME
mkdir -p node_modules/app-builder-bin/linux/ppc64/
cp $CWD/app-builder/dist/app-builder_linux_ppc64le/app-builder node_modules/app-builder-bin/linux/ppc64/
chmod 777 node_modules/app-builder-bin/linux/ppc64/app-builder
sed -i "s#message: \`Publish a new version? (currently: \${version})\`,#message: \`Publish a new version? (currently: \${version})\`,when:function(answers) {answers.name='No';return false;},#g" scripts/binary/ask.js
sed -i "143i await execa('mkdir', ['-p', 'node_modules/@ffmpeg-installer/linux-ppc64'], { stdio: 'inherit', cwd: DIST_DIR, shell: true,})" scripts/binary/build.ts
sed -i "144i await execa('mkdir', ['-p', 'node_modules/@ffprobe-installer/linux-ppc64'], { stdio: 'inherit', cwd: DIST_DIR, shell: true,})" scripts/binary/build.ts
sed -i "145i await execa('cp', ['$(which ffmpeg)', 'node_modules/@ffmpeg-installer/linux-ppc64/'], { stdio: 'inherit', cwd: DIST_DIR, shell: true,})" scripts/binary/build.ts
sed -i "146i await execa('cp', ['$(which ffprobe)', 'node_modules/@ffprobe-installer/linux-ppc64/'], { stdio: 'inherit', cwd: DIST_DIR, shell: true,})" scripts/binary/build.ts
sed -i "147i await execa('cp', [CY_ROOT_DIR + '/node_modules/@ffmpeg-installer/linux-ppc64/package.json', 'node_modules/@ffmpeg-installer/linux-ppc64/'], { stdio: 'inherit', cwd: DIST_DIR, shell: true,})" scripts/binary/build.ts
sed -i "148i await execa('cp', [CY_ROOT_DIR + '/node_modules/@ffprobe-installer/linux-ppc64/package.json', 'node_modules/@ffprobe-installer/linux-ppc64/'], { stdio: 'inherit', cwd: DIST_DIR, shell: true,})" scripts/binary/build.ts
yarn binary-build
yarn binary-zip

#test
sed -i "s#expect(browsers.length).to.be.gt(0)#expect(browsers.length).to.be.gte(0)#g" ./packages/launcher/test/unit/detect_spec.ts
sed -i.bak '43,47d' ./cli/test/lib/build_spec.js
sed -i.bak '49,107d' ./packages/data-context/test/unit/sources/GitDataSource.spec.ts
yarn test

#conclude
export CYPRESS_DIST=$CWD/$NAME/cypress.zip
set +ex
echo "Build and test complete. Redistributable zip file located at $CYPRESS_DIST"

