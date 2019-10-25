Prerequisite:

1. Before you run the script make sure that the below patch files

https://github.com/ppc64le/build-scripts/blob/master/quarkus/processFix.patch
https://github.com/ppc64le/build-scripts/blob/master/quarkus/mongoFix.patch
https://github.com/ppc64le/build-scripts/blob/master/quarkus/quarkus.patch

have been downloaded and is available in the same directory as the build script..

2. Due to licensing restrictions, we cannot include the mongo db binaries in the build The following has to be done manually.
Download Mongo DB installer(mongodb-linux-ppc64le-enterprise-rhel71-4.0.12.tgz) from below url.
Place the tgz file in /opt/mongodb/linux  folder.

https://www.mongodb.com/download-center/enterprise
Select Options:
Version: 4.0.12
OS: Rhel7.1 64bit Power
Package: TGZ

Running the script:

On RHEL 7.6

$ bash quarkus_v0.8.4_rhel_7.6.sh


