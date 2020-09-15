# This Dockerfile has been adapted from the Dockerfile
# maintained by the ManageIQ community at
# https://github.com/ManageIQ/container-ruby
# to work on Power on UBI base
FROM registry.access.redhat.com/ubi7/ubi
MAINTAINER "Priya Seth <sethp@us.ibm.com>"

## For ruby
ENV RUBY_GEMS_ROOT=/usr/local/lib/ruby/gems/2.5.0 \
    LANG=en_US.UTF-8

# Install repos
RUN yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm && \
    curl -sL https://copr.fedorainfracloud.org/coprs/manageiq/ManageIQ-Master/repo/epel-7/manageiq-ManageIQ-Master-epel-7.repo -o /etc/yum.repos.d/manageiq.repo

# Install ruby-install and make
RUN yum -y install --setopt=tsflags=nodocs bzip2 make wget

RUN wget -O ruby-install-0.7.0.tar.gz https://github.com/postmodern/ruby-install/archive/v0.7.0.tar.gz && \
        tar -xzvf ruby-install-0.7.0.tar.gz && \
        cd ruby-install-0.7.0/ && \
        make install

RUN ruby-install --system ruby 2.5.7 -- --disable-install-doc --enable-shared && rm -rf /usr/local/src/* && yum clean all
