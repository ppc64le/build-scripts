# Base Image
FROM  registry.access.redhat.com/ubi8/ubi:8.3
# The author
MAINTAINER "nthorat"

ENV PSAD_VERSION 3.0
ENV PSAD_REPOSITORY https://github.com/mrash/psad
ENV PSAD_DIR psad
ENV PERL_MM_USE_DEFAULT 1 

# Install dependent packages
RUN cd $HOME\
    && yum install -y git wget vim make gcc initscripts chkconfig iptables iproute net-tools ruby-devel gcc make rpm-build rubygems perl-ExtUtils-MakeMaker\
    && gem install --no-document fpm\
    && wget http://www.cipherdyne.org/modules/IPTables-ChainMgr-1.6.tar.gz\
    && tar -xzf IPTables-ChainMgr-1.6.tar.gz\
    && cd IPTables-ChainMgr-1.6\
    && perl Makefile.PL\
    && make\
    && make install\
    && cd ..\
    && yum install -y cpan\
    && cpan Date::Calc\
    && git clone $PSAD_REPOSITORY\
    && cd $PSAD_DIR\
    && make all
