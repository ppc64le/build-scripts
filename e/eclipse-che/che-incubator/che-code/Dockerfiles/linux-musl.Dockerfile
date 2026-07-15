# Copyright (c) 2021-2026 Red Hat, Inc.
# This program and the accompanying materials are made
# available under the terms of the Eclipse Public License 2.0
# which is available at https://www.eclipse.org/legal/epl-2.0/
#
# SPDX-License-Identifier: EPL-2.0
#

#Note: This Dockerfile is built only ppc64le and not work for other architectures

# Build assembly for linux ppc64le
FROM docker.io/ppc64le/node:22 as linux-ppc64-builder

RUN apt-get update && apt-get install -y \
    # Download some files
    curl \
    patch \
    # compile some javascript native stuff (node-gyp)
    make gcc g++ python3 python3-pip \
    # git
    git \
    # bash shell
    bash \
    # some lib to compile 'native-keymap' npm module
    libx11-dev libxkbfile-dev \
    # requirements for keytar
    libsecret-1-dev \
    # kerberos authentication
    libkrb5-dev \
    # certificates
    ca-certificates \
    # process utilities
    procps \
    # browser for tests
    chromium \
    && rm -rf /var/lib/apt/lists/*

#########################################################
#
# Copy Che-Code to the container
#
#########################################################
COPY code /checode-compilation
WORKDIR /checode-compilation

ENV ELECTRON_SKIP_BINARY_DOWNLOAD=1
ENV PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1
ENV VSCODE_SKIP_HEADER_INSTALL=1

# workaround for https://github.com/nodejs/node/issues/52229
ENV CXXFLAGS='-DNODE_API_EXPERIMENTAL_NOGC_ENV_OPT_OUT'

# Initialize a git repository for code build tools
RUN git init .

# change network timeout (slow using multi-arch build)
RUN npm config set fetch-retry-mintimeout 100000 \
    && npm config set fetch-retry-maxtimeout 600000

# Grab dependencies (and force to rebuild them)
RUN rm -rf /checode-compilation/node_modules \
    && npm install --force

# Rebuild platform specific dependencies
RUN npm rebuild

RUN NODE_VERSION=$(cat /checode-compilation/remote/.npmrc | grep target | cut -d '=' -f 2 | tr -d '"') \
    # cache node from this image to avoid to grab it from within the build
    && echo "caching /checode-compilation/.build/node/v${NODE_VERSION}/linux-ppc64/node" \
    && mkdir -p /checode-compilation/.build/node/v${NODE_VERSION}/linux-ppc64 \
    && cp /usr/local/bin/node /checode-compilation/.build/node/v${NODE_VERSION}/linux-ppc64/node \
    # workaround to fix build
    && cp -r /checode-compilation/node_modules/tslib /checode-compilation/remote/node_modules/

RUN VSCODE_MANGLE_WORKERS=2 NODE_OPTIONS="--max-old-space-size=8192" \
    ./node_modules/.bin/gulp vscode-reh-web-linux-ppc64-min

RUN cp -r ../vscode-reh-web-linux-ppc64 /checode

RUN chmod a+x /checode/out/server-main.js \
    && chgrp -R 0 /checode && chmod -R g+rwX /checode

# Compile tests
RUN ./node_modules/.bin/gulp compile-extension:vscode-api-tests \
    compile-extension:markdown-language-features \
    compile-extension:typescript-language-features \
    compile-extension:emmet \
    compile-extension:git \
    compile-extension:ipynb \
    compile-extension-media \
    compile-extension:configuration-editing

# Compile test suites
# https://github.com/microsoft/vscode/blob/cdde5bedbf3ed88f93b5090bb3ed9ef2deb7a1b4/test/integration/browser/README.md#compile
RUN if [ "$(uname -m)" = "x86_64" ]; then \
      npm --prefix test/smoke run compile && npm --prefix test/integration/browser run compile; \
    fi

# use of retry and timeout
COPY /build/scripts/helper/retry.sh /usr/bin/retry

RUN chmod u+x /usr/bin/retry

# install test dependencies
ENV PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=0

RUN if [ "$(uname -m)" = "x86_64" ]; then \
      npm run playwright-install; \
    fi

RUN if [ "$(uname -m)" = "x86_64" ]; then \
      PLAYWRIGHT_HEADLESS_PATH=$(echo /root/.cache/ms-playwright/chromium_headless_shell-*/chrome-linux) && \
      echo "Found headless_shell path: $PLAYWRIGHT_HEADLESS_PATH" && \
      rm -f "$PLAYWRIGHT_HEADLESS_PATH/headless_shell" && \
      ln -sf /usr/bin/chromium "$PLAYWRIGHT_HEADLESS_PATH/headless_shell" && \
      ln -sf /usr/bin/chromium "$PLAYWRIGHT_HEADLESS_PATH/chrome" && \
      ls -la "$PLAYWRIGHT_HEADLESS_PATH"; \
    fi

# Run integration tests (Browser)
RUN if [ "$(uname -m)" = "x86_64" ]; then \
      VSCODE_REMOTE_SERVER_PATH="/vscode-reh-web-linux-ppc64" \
      retry -v -t 3 -s 2 -- timeout 5m ./scripts/test-web-integration.sh --browser chromium; \
    fi

# Run smoke tests (Browser)
RUN if [ "$(uname -m)" = "x86_64" ]; then \
      VSCODE_REMOTE_SERVER_PATH="/vscode-reh-web-linux-ppc64" \
      retry -v -t 3 -s 2 -- timeout 5m npm run smoketest-no-compile -- --web --headless --electronArgs="--disable-dev-shm-usage --use-gl=swiftshader"; \
    fi

#########################################################
#
# Copy VS Code launcher to the container
#
#########################################################
COPY launcher /checode-launcher
WORKDIR /checode-launcher

RUN npm install \
    && mkdir /checode/launcher \
    && cp -r out/src/*.js /checode/launcher \
    && chgrp -R 0 /checode && chmod -R g+rwX /checode

FROM scratch as linux-ppc64-content

COPY --from=linux-ppc64-builder /checode /checode-linux-musl
