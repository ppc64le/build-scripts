FROM ppc64le/ubuntu:16.04

ENV ACE_ROOT /ATCD/ACE
ENV LD_LIBRARY_PATH $ACE_ROOT/lib:$LD_LIBRARY_PATH

RUN apt-get update -y && \
        apt-get install -y git build-essential && \
        git clone http://github.com/DOCGroup/ATCD.git && cd ATCD/ACE && \
        git clone https://github.com/DOCGroup/MPC.git MPC && \
        $ACE_ROOT/bin/mwc.pl -type gnuace ACE.mwc && \
        # These changes are required to build ACE correctly.
        echo "#include \"ace/config-linux.h\"" > $ACE_ROOT/ace/config.h && \
        echo "include \$(ACE_ROOT)/include/makeinclude/platform_linux.GNU" > $ACE_ROOT/include/makeinclude/platform_macros.GNU && \
        # Build and run tests.
        make && \
        perl bin/auto_run_tests.pl -a -Config FIXED_BUGS_ONLY -Config FACE_SAFETY

CMD ["/bin/bash"]
