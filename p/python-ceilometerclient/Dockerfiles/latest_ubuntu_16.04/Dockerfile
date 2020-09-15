FROM ppc64le/ubuntu:16.04

# The author for this new image
MAINTAINER "Priya Seth <sethp@us.ibm.com>"

RUN apt-get update && apt-get install -y python-ceilometerclient

ENTRYPOINT ["ceilometer"]
