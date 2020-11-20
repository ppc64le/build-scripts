FROM ubuntu:16.04
MAINTAINER "Atul Sowani <sowania@us.ibm.com>"

ENV SWIFT_SOURCE_ROOT=/root/swift-source
ENV SWIFT_BUILD_ROOT=/root/swift-source
ENV SWIFT_PATH_TO_LLVM_SOURCE=/root/swift-source/llvm
ENV PATH=$PATH:$SWIFT_BUILD_ROOT/Ninja-ReleaseAssert+stdlib-Release/llvm-linux-powerpc64le/bin:$SWIFT_BUILD_ROOT/Ninja-ReleaseAssert+stdlib-Release/swift-linux-powerpc64le/bin
ENV LD_LIBRARY_PATH=$SWIFT_BUILD_ROOT/Ninja-ReleaseAssert+stdlib-Release/swift-linux-powerpc64le/lib/swift/linux/powerpc64le:$LD_LIBRARY_PATH

RUN cd && apt-get update -y && \
    apt-get install -y git cmake ninja-build clang python uuid-dev \
        libpython-dev libncurses5-dev pkg-config libblocksruntime-dev ocaml \
        libcurl4-openssl-dev autoconf libtool systemtap-sdt-dev tzdata rsync \
        ca-certificates libobjc-5-dev swig g++ \
        libicu-dev icu-devtools libbsd-dev libedit-dev libxml2-dev \
        libsqlite3-dev libatomic-ops-dev libstdc++-5-dev && \

    mkdir swift-source && \
    cd swift-source && \
    git clone https://github.com/apple/swift.git && \
    ./swift/utils/update-checkout --clone --scheme "swift-4.1-branch" && \

    git config --global user.name "asowani" && \
    git config --global user.email "sowania@us.ibm.com" && \

    cd swift-corelibs-foundation && \
    git cherry-pick -m 1 0027637db85fd804b55ede3cfff26c913d2a90d0 && \

    cd ../swiftpm && \
    git cherry-pick b78f787ff7c407d89fe41822fd6af7c23d1c4764 && \

    cd ../clang && \
    git remote add jonpspri https://github.com/jonpspri/swift-clang.git && \
    git fetch --quiet jonpspri && \
    git cherry-pick 9bfd531a07e6259f3d8d101ca26543e0ed064cbe && \
    git cherry-pick 8a46bf51827649642ee6c33ade6d1571554dae4c && \

    cd ../swift && \
    #git remote add asowani https://github.com/asowani/swift.git && \
    #git fetch --quiet asowani && \
    #git cherry-pick c75887d4b18ca4cef351ea89cd54f3a8e0b5d784 && \
    #git cherry-pick 5c5ccefe9844566cb1d328e3a68c6dfdc934db5b && \

    mv test/IRGen/c_functions.swift test/IRGen/c_functions.swift.org && \
    mv test/IRGen/errors.sil test/IRGen/errors.sil.oef && \
    mv test/IRGen/errors.sil.oef test/IRGen/errors.sil.org && \
    mv test/IRGen/objc_simd.sil test/IRGen/objc_simd.sil.org && \
    #mv test/Sanitizers/witness_table_lookup.swift test/Sanitizers/witness_table_lookup.swift.org && \
    mv test/Sanitizers/tsan.swift test/Sanitizers/tsan.swift.org && \
    mv test/Driver/linker-args-order-linux.swift test/Driver/linker-args-order-linux.swift.org && \
    mv test/IRGen/big_types_corner_cases.swift test/IRGen/big_types_corner_cases.swift.org && \
    mv test/IRGen/clang_inline_opt.swift test/IRGen/clang_inline_opt.swift.org && \
    mkdir /swift-build && \

    utils/build-script \
        --release --assertions \
        --llbuild \
        --swiftpm \
        --xctest \
        --no-swift-stdlib-assertions \
        --test --validation-test --long-test \
        --foundation \
        --libdispatch \
        --lit-args=-v \
        -- \
        --build-ninja \
        --install-swift \
        --install-swiftpm \
        --install-xctest \
        --install-prefix=/usr \
        --swift-enable-ast-verifier=0 \
        --build-swift-static-stdlib \
        --build-swift-static-sdk-overlay \
        --build-swift-stdlib-unittest-extra \
        --test-installable-package \
        --install-destdir=/swift-build \
        --install-libdispatch \
        --reconfigure \
        --skip-test-cmark \
        --skip-test-lldb \
        --skip-test-swift \
        --skip-test-llbuild \
        --skip-test-swiftpm \
        --skip-test-xctest \
        --skip-test-foundation \
        --skip-test-libdispatch \
        --skip-test-playgroundsupport \
        --skip-test-libicu && \

    apt-get remove --purge -y git cmake ninja-build clang python uuid-dev \
        libpython-dev libncurses5-dev pkg-config libblocksruntime-dev ocaml \
        libcurl4-openssl-dev autoconf libtool systemtap-sdt-dev tzdata rsync \
        libobjc-5-dev ca-certificates swig g++ && \
    apt-get autoremove -y

CMD [ "/bin/bash" ]
