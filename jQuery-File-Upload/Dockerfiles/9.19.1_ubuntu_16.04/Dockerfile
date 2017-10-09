FROM ppc64le/node:7.5.0

MAINTAINER "Priya Seth <sethp@us.ibm.com>
ENV JQUERY_FILE_UPLOAD_VERSION v9.19.1

RUN apt-get update \
        && apt-get install -y git build-essential \
        && git clone https://github.com/blueimp/jQuery-File-Upload --branch=${JQUERY_FILE_UPLOAD_VERSION} \
        && cd jQuery-File-Upload && npm install && npm test \
        && apt-get purge -y git build-essential \
        && apt-get -y autoremove

CMD ["/bin/bash"]
