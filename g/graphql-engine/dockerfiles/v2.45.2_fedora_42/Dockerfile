ARG wdir=/tmp

FROM fedora:42 as build

ENV PACKAGE_NAME=graphql-engine
ENV PACKAGE_VERSION=v2.45.2
ENV PACKAGE_PATCH=https://raw.githubusercontent.com/ppc64le/build-scripts/master/g/${PACKAGE_NAME}/${PACKAGE_NAME}-${PACKAGE_VERSION}.patch
ENV PACKAGE_ORG=hasura
ENV PACKAGE_URL=https://github.com/${PACKAGE_ORG}/${PACKAGE_NAME}/
ENV CABAL_VERSION=3.12.1.0

ARG wdir

#Install dependencies
RUN yum install git g++ cabal-install libpq-devel unixODBC-devel zlib-devel -y
RUN yum config-manager addrepo --set=baseurl=https://rpmfind.net/linux/fedora-secondary/releases/42/Everything/ppc64le/os
RUN yum install https://www.rpmfind.net/linux/fedora-secondary/releases/42/Everything/ppc64le/os/Packages/g/ghc9.10-devel-9.10.1-7.fc42.ppc64le.rpm \
                https://www.rpmfind.net/linux/fedora-secondary/releases/42/Everything/ppc64le/os/Packages/g/ghc9.10-9.10.1-7.fc42.ppc64le.rpm \
                -y

#Install required version of cabal-install
RUN cabal update && \
    cabal install cabal-install-$CABAL_VERSION --overwrite-policy=always && \
    PATH="$HOME/.local/bin/:$PATH" && \
    cabal -V && \
    cabal update && \
    yum -y remove ghc cabal-install

#Copy patch
RUN wget $PACKAGE_PATCH
RUN cp ${PACKAGE_NAME}-${PACKAGE_VERSION}.patch $wdir/
#COPY ${PACKAGE_NAME}-${PACKAGE_VERSION}.patch $wdir/

#Run build
RUN cd $wdir && \
    git clone ${PACKAGE_URL} && \
    cd ${PACKAGE_NAME} && git checkout ${PACKAGE_VERSION} && \
    git apply $wdir/${PACKAGE_NAME}-${PACKAGE_VERSION}.patch && \
    echo $PACKAGE_VERSION > "$(git rev-parse --show-toplevel)/server/CURRENT_VERSION" && \
    PATH="$HOME/.local/bin/:$PATH" && \
    cabal build exe:graphql-engine

FROM fedora:42

ARG wdir

#Install runtime deps
RUN yum install unixODBC libpq numactl-libs -y

#Copy from build stage
COPY --from=build $wdir/graphql-engine/dist-newstyle/build/ppc64le-linux/*/graphql-engine-1.0.0/x/graphql-engine/opt/build/graphql-engine/graphql-engine /usr/local/bin/graphql-engine

#Entry point
ENTRYPOINT ["/usr/local/bin/graphql-engine"]

