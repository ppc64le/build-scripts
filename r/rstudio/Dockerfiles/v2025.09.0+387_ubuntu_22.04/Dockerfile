# ============================================================
# Stage 1: Builder (Ubuntu 22.04)
# ============================================================
FROM public.ecr.aws/ubuntu/ubuntu:22.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive
WORKDIR /tmp

ARG PACKAGE_VERSION=v2025.09.0+387
ARG NODE_VERSION=20.20.0
ARG PREFIX_DIR=/usr/lib/rstudio-server
ARG RSTUDIO_TOOLS_ROOT=/opt/rstudio-tools/ppc64le

ENV RSTUDIO_VERSION_MAJOR=2025 \
    RSTUDIO_VERSION_MINOR=09 \
    RSTUDIO_VERSION_PATCH=0 \
    RSTUDIO_VERSION_SUFFIX="+387" \
    CFLAGS="-maltivec -mvsx" \
    CXXFLAGS="-maltivec -mvsx" \
    JAVA_HOME=/usr/lib/jvm/java-17-openjdk-ppc64el \
    PATH=/usr/lib/jvm/java-17-openjdk-ppc64el/bin:$PATH

# ---- build dependencies ----
RUN apt-get update -y && apt-get install -y \
  sudo ca-certificates curl wget git git-lfs gnupg \
  build-essential pkg-config cmake ninja-build \
  python3 python3-dev python3-venv python3-pip python3-setuptools python3-wheel \
  ant openjdk-17-jdk \
  rsync unzip xz-utils zip \
  patchelf dpkg-dev lsb-release \
  libssl-dev zlib1g-dev libcurl4-openssl-dev \
  libxml2-dev libxslt1-dev \
  libsqlite3-dev libpq-dev \
  libsecret-1-dev libglib2.0-dev \
  libpam0g-dev libedit-dev uuid-dev \
  r-base r-base-dev \
  pandoc lsof \
  procps \
 && rm -rf /var/lib/apt/lists/*

# ---- NodeJS ----
RUN mkdir -p /opt/nodejs && \
  curl -fsSL https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-ppc64le.tar.xz \
  | tar -xJ -C /opt/nodejs
ENV PATH=/opt/nodejs/node-v${NODE_VERSION}-linux-ppc64le/bin:$PATH

# ---- clone ----
RUN git clone --recursive https://github.com/rstudio/rstudio.git rstudio
WORKDIR /tmp/rstudio

RUN git checkout ${PACKAGE_VERSION} && \
    git lfs install --local || true && \
    git lfs pull || true

RUN PATCH_FILE="rstudio_server_${PACKAGE_VERSION}.patch" && \
    wget -q https://raw.githubusercontent.com/ppc64le/build-scripts/master/r/rstudio/${PATCH_FILE} && \
    git apply ${PATCH_FILE}

# ---- create the i18n-helpers venv where install-dependencies expects it ----
RUN python3 -m venv src/gwt/tools/i18n-helpers/VENV && \
    src/gwt/tools/i18n-helpers/VENV/bin/pip install -U pip setuptools wheel >/dev/null

# ---- patch Copilot language server installer (disable on ppc64le) ----
RUN printf '#!/usr/bin/env bash\necho "Copilot disabled on ppc64le"; exit 0\n' \
    > dependencies/common/install-copilot-language-server && \
    chmod +x dependencies/common/install-copilot-language-server

# ---- run upstream dependency installers (Ubuntu 22.04) ----
RUN ( cd dependencies/linux && bash ./install-dependencies-jammy )

# ---- stage gwt-rstudio SDK ----
RUN mkdir -p src/gwt/lib/gwt && \
    ln -sfn "$(pwd)/dependencies/common/gwtproject/gwt/gwt-rstudio" src/gwt/lib/gwt/gwt-rstudio && \
    test -f src/gwt/lib/gwt/gwt-rstudio/gwt-user.jar

# ---- configure + build + install ----
RUN rm -rf build && mkdir build
WORKDIR /tmp/rstudio/build

RUN cmake .. \
  -DRSTUDIO_TARGET=Server \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=${PREFIX_DIR} \
  -DQUARTO_ENABLED=OFF \
  -DRSTUDIO_ENABLE_COPILOT=OFF \
  -DRSTUDIO_CRASHPAD_ENABLED=OFF \
  -DCMAKE_CXX_FLAGS="-DRSTUDIO_BOOST_NAMESPACE=rstudio_boost" \
  -DRSTUDIO_TOOLS_ROOT=${RSTUDIO_TOOLS_ROOT} \
  -DRSTUDIO_VERSION_MAJOR=${RSTUDIO_VERSION_MAJOR} \
  -DRSTUDIO_VERSION_MINOR=${RSTUDIO_VERSION_MINOR} \
  -DRSTUDIO_VERSION_PATCH=${RSTUDIO_VERSION_PATCH} \
  -DRSTUDIO_VERSION_SUFFIX=${RSTUDIO_VERSION_SUFFIX}

RUN cmake --build . --target install -- -j"$(nproc)"

# ============================================================
# Unit Tests 
# ============================================================
WORKDIR /tmp/rstudio

# GWT unit tests
RUN if [ -d src/gwt ]; then (cd src/gwt && ant unittest); fi

# Ensure rstudio-tests exists
RUN test -x build/src/cpp/rstudio-tests

# Create rstudio user and set ownership 
RUN id -u rstudio >/dev/null 2>&1 || useradd -m -s /bin/bash rstudio && \
    chown -R rstudio:rstudio /tmp/rstudio || true

WORKDIR /tmp/rstudio/build/src/cpp

RUN ./rstudio-tests --scope core
RUN ./rstudio-tests --scope rserver

# R and rsession scopes run as rstudio user
RUN sudo -u rstudio env LANG=C.UTF-8 LC_ALL=C.UTF-8 ./rstudio-tests --scope r
RUN sudo -u rstudio env LANG=C.UTF-8 LC_ALL=C.UTF-8 ./rstudio-tests --scope rsession


# ============================================================
# Stage 2: Runtime (Ubuntu 22.04)
# ============================================================
FROM public.ecr.aws/ubuntu/ubuntu:22.04 AS runtime

ENV DEBIAN_FRONTEND=noninteractive
ARG PREFIX_DIR=/usr/lib/rstudio-server

# ---- runtime deps ----
RUN apt-get update -y && apt-get install -y \
  ca-certificates \
  r-base \
  libcurl4 \
  libedit2 \
  libglib2.0-0 \
  libpam0g \
  libsecret-1-0 \
  libssl3 \
  libuuid1 \
  libxml2 \
  libxslt1.1 \
  sudo \
  zlib1g \
  python3 \
 && rm -rf /var/lib/apt/lists/*

COPY --from=builder ${PREFIX_DIR} ${PREFIX_DIR}

RUN mkdir -p /var/run/rstudio-server \
             /var/lock/rstudio-server \
             /var/log/rstudio-server \
             /var/lib/rstudio-server \
             /etc/rstudio

RUN useradd -m -d /home/rstudio -s /bin/bash -G sudo rstudio && \
    echo "rstudio:rstudio" | chpasswd

RUN ln -sf ${PREFIX_DIR}/bin/rserver /usr/sbin/rserver || true && \
    ln -sf ${PREFIX_DIR}/bin/rstudio-server /usr/sbin/rstudio-server || true

EXPOSE 8787
VOLUME ["/home/rstudio"]

CMD ["/usr/sbin/rserver", "--server-daemonize=0"]