FROM node:10.9.0-stretch

MAINTAINER "Priya Seth <sethp@us.ibm.com>"

RUN apt-get update \
        && apt-get install -y git build-essential \
        && git clone https://github.com/devongovett/pdfkit && cd pdfkit \
        && npm install \
        && apt-get purge -y git build-essential \
        && apt-get -y autoremove

CMD ["/bin/bash"]
