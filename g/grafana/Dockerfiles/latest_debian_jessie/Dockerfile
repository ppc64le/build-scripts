FROM ppc64le/node:7.5.0

MAINTAINER "Priya Seth <sethp@us.ibm.com>

ENV PATH=/usr/local/go/bin:$PATH
ENV GOPATH=/grafana

RUN wget https://storage.googleapis.com/golang/go1.8.1.linux-ppc64le.tar.gz \
        && tar -C /usr/local -xzf go1.8.1.linux-ppc64le.tar.gz \
        && mkdir /grafana && cd /grafana && go get github.com/grafana/grafana; exit 0

RUN cd $GOPATH/src/github.com/grafana/grafana \
        && go run build.go setup \
        && go run build.go build \
        && apt-get update \
        && apt-get install -y libfontconfig  \
        && wget https://github.com/ibmsoe/phantomjs/releases/download/2.1.1/phantomjs-2.1.1-linux-ppc64.tar.bz2 \
        && tar -xvf phantomjs-2.1.1-linux-ppc64.tar.bz2 \
        && cp phantomjs-2.1.1-linux-ppc64/bin/phantomjs /usr/bin/ \
        && npm install -g yarn && yarn install --pure-lockfile \
        && npm install node-sass \
        && npm install \
        && npm install -g grunt grunt-cli \
        && grunt \
        && apt-get purge -y libfontconfig && apt-get autoremove -y

EXPOSE 3000

WORKDIR /grafana/src/github.com/grafana/grafana
CMD ["./bin/grafana-server"]
