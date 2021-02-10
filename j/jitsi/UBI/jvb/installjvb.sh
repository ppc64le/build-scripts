#!/bin/bash
pwd
ls
 IFS="
"; for  line in `grep -v "^#" debian/install  | grep -v "^$"`; do echo $line | sed "s/\(\S*\)\s*\(.*\)/mkdir -p \/\2; cp -v \1 \/\2;/g"; done > /tmp/run
chmod +x /tmp/run
cat /tmp/run
pwd
ls -R
sh /tmp/run
cp -v `find -name *.service` /lib/systemd/system/

