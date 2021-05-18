#!/bin/bash
# ----------------------------------------------------------------------------
#
# Tested on     : UBI 8.3
# Maintainer    : Nishikant Thorat <nishikant_thorat@ibm.com>
# NOTE          : This script helps to install psad on UBI 8.3, with psad.conf 
#                 with additional parameters by test suite, which may or may not
#                 be needed.
#
# ----------------------------------------------------------------------------
./psad_rhel_8.3.sh
yum install -y mailx m4
#yum install -y sendmail-cf
# if sendmail-cf is not available then,
# Sendmail installation  - Start
wget https://ftp.icm.edu.pl/packages/sendmail/sendmail.8.15.1.tar.gz; tar -xvf sendmail.8.15.1.tar.gz; cd sendmail-8.15.1;

if [ ! -d /usr/man ]; then mkdir -p /usr/man;fi
if [ ! -d /usr/man/man1 ]; then mkdir -p /usr/man/man1; fi
if [ ! -d /usr/man/man5 ]; then mkdir -p /usr/man/man5; fi
if [ ! -d /usr/man/man8 ]; then mkdir -p /usr/man/man8; fi
 
groupadd -f smmsp;
useradd  smmsp -g smmsp;
sed  's/ldl/ldl -lresolv/' devtools/OS/Linux > devtools/OS/Linux.new; mv -f devtools/OS/Linux.new devtools/OS/Linux; ./Build -c;
cd sendmail;  ./Build install; cd ../..
# Sendmail installation  - End
mkdir -p ./psad/test/psad-install/var/log/psad/tmp
# Install psad rpm
rpm -ihv psad-3.0-1.ppc64le.rpm
# Start psad
psad start
