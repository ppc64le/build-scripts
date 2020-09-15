
Due to licensing restrictions, we cannot include the mongo db binaries in the build
The following has to be done manually

Please download those from :
https://www.mongodb.com/download-center/enterprise

and copy them the the /opt/mongodb/linux/ directory 

the following should be the files :

/opt/mongodb/linux/mongodb-linux-ppc64le-enterprise-rhel71-3.2.22.tgz
/opt/mongodb/linux/mongodb-linux-ppc64le-enterprise-rhel71-3.4.23.tgz
/opt/mongodb/linux/mongodb-linux-ppc64le-enterprise-rhel71-3.6.14.tgz
/opt/mongodb/linux/mongodb-linux-ppc64le-enterprise-rhel71-4.0.12.tgz
/opt/mongodb/linux/mongodb-linux-ppc64le-enterprise-rhel71-4.2.0.tgz

also create the following symlinks to the respective files 

/opt/mongodb/linux/mongodb-linux-ppc64le-3.2.22.tgz
/opt/mongodb/linux/mongodb-linux-ppc64le-3.4.23.tgz
/opt/mongodb/linux/mongodb-linux-ppc64le-3.6.14.tgz
/opt/mongodb/linux/mongodb-linux-ppc64le-4.0.12.tgz
/opt/mongodb/linux/mongodb-linux-ppc64le-4.2.0.tgz

