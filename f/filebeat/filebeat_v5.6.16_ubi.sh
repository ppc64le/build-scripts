# -----------------------------------------------------------------------------
# Package       : filebeat
# Version       : v5.6.16
# Tested on     : "Red Hat Enterprise Linux 8.4 (Ootpa)"
# Maintainer    : Saurabh Gore <saurabh_gore@persistent.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
# ----------------------------------------------------------------------------

#! /bin/bash
dnf -y install \
        http://mirror.centos.org/centos/8/BaseOS/ppc64le/os/Packages/centos-linux-repos-8-3.el8.noarch.rpm \
        http://mirror.centos.org/centos/8/BaseOS/ppc64le/os/Packages/centos-gpg-keys-8-3.el8.noarch.rpm

dnf install -y rpmdevtools rpmlint

rpmdev-setuptree

cd ~/rpmbuild/SPECS

rpmdev-newspec filebeat

export GOPATH=~/rpmbuild/BUILD/go
export PATH=$PATH:$GOPATH/bin
export VERSION=v5.6.16

#Extract version from command line
echo "Usage: $0 [-v <VERSION>]"
echo "VERSION is an optional paramater whose default value is 20100527, not all versions are supported."
VERSION="${1:-$VERSION}"


cat << EOF > filebeat.spec
Name:           filebeat
Version:        ${VERSION}
Release:        1%{?dist}
Summary:        filebeat rpm package

License:        GPL
URL:            https://github.com/elastic/beats
BuildArch:      ppc64le

Requires:       bash

%description
filebeat rpm package

%prep
yum install -y wget git make gcc-c++ python3-virtualenv

wget https://golang.org/dl/go1.10.2.linux-ppc64le.tar.gz
tar -zxvf go1.10.2.linux-ppc64le.tar.gz

export GOPATH=~/rpmbuild/BUILD/go
export PATH=$PATH:$GOPATH/bin
mkdir -p ${GOPATH}/src/github.com/elastic
cd ${GOPATH}/src/github.com/elastic
git clone https://github.com/elastic/beats.git
cd beats/filebeat
git checkout ${VERSION}
make


%install
rm -rf %{buildroot}
mkdir -p %{buildroot}%{_bindir}
cp ~/rpmbuild/BUILD/go/src/github.com/elastic/beats/filebeat/filebeat %{buildroot}%{_bindir}

%clean
rm -rf %{buildroot}

%files
%{_bindir}/filebeat
EOF

cat << EOF >> ~/.rpmmacros
%_unpackaged_files_terminate_build      0
%_binaries_in_noarch_packages_terminate_build   0
EOF

rpmlint ~/rpmbuild/SPECS/filebeat.spec

rpmbuild -bs ~/rpmbuild/SPECS/filebeat.spec

rpmbuild -bb ~/rpmbuild/SPECS/filebeat.spec


# TO install filebeat package
# dnf install ~/rpmbuild/RPMS/noarch/filebeat-5.6.16-1.el8.noarch.rpm

# to test installtion
# rpm -qi filebeat
# filebeat version

