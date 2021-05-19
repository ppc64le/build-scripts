FROM registry.access.redhat.com/ubi8/ubi:latest

MAINTAINER Abhijit Mane <abhijman@in.ibm.com>

RUN dnf update -y \
 && dnf install -y make gcc wget git gem ruby ruby-devel redhat-rpm-config \
    shared-mime-info.ppc64le zlib.ppc64le zlib-devel.ppc64le \
 && gem install bundler

RUN dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-8-ppc64le/pgdg-redhat-repo-latest.noarch.rpm \
 && dnf install -y postgresql13-server \
 && dnf install -y libpq5 libpq5-devel

USER postgres

CMD [bash]
