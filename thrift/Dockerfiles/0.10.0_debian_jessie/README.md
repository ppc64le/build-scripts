The docker image can be obtained using following command:
docker pull thrift

This is image is intended to run as an executable. Files are provided by
mounting a directory. Here's an example of compiling service.thrift to ruby to
the current directory.

$ docker run -v "$PWD:/data" thrift thrift -o /data --gen rb /data/service.thrift

Note, that you may want to include -u $(id -u) to set the UID on generated
files. The thrift process runs as root by default which will generate root
owned files depending on your docker setup.

