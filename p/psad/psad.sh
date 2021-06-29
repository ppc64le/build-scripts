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
function Build
{
	./psad_UBI_8.3.sh
}

function Install
{
	yum install -y git wget vim make gcc initscripts chkconfig iptables iproute net-tools ruby-devel gcc make rpm-build rubygems
	yum install -y cpan perl gettext mailx m4
	export PERL_MM_USE_DEFAULT=1; cpan Date::Calc Data::Dumper IPTables::Parse NetAddr::IP Unix::Syslog IPTables::ChainMgr
	git clone https://github.com/rfc1036/whois; cd whois/;  make; make install; cd ..
	#yum install -y sendmail-cf
	# if sendmail-cf is not available then,
	#
	# Sendmail installation  - Start
	#
	wget https://ftp.icm.edu.pl/packages/sendmail/sendmail.8.15.1.tar.gz; tar -xvf sendmail.8.15.1.tar.gz; cd sendmail-8.15.1;

	if [ ! -d /usr/man ]; then mkdir -p /usr/man;fi
	if [ ! -d /usr/man/man1 ]; then mkdir -p /usr/man/man1; fi
	if [ ! -d /usr/man/man5 ]; then mkdir -p /usr/man/man5; fi
	if [ ! -d /usr/man/man8 ]; then mkdir -p /usr/man/man8; fi

	groupadd -f smmsp;
	useradd  smmsp -g smmsp;
	sed  's/ldl/ldl -lresolv/' devtools/OS/Linux > devtools/OS/Linux.new; mv -f devtools/OS/Linux.new devtools/OS/Linux; ./Build -c;
	cd sendmail;  ./Build install; cd ../..
	#
	# Sendmail installation  - End
	#
	mkdir -p /var/log/psad/tmp
	# Install psad rpm
	rpm -ihv psad-3.0-1.ppc64le.rpm
	# Start psad
	psad start
}


while getopts bich value
do
        case "$value" in
                b) echo "Building Psad ..."
			Build
                        ;;
                i) echo "Installing Psad ..."
			Install
                        ;;
                c) echo "Building and installing Psad ..."
			Build
			Install
                        ;;
		h) echo "Usage: "
		   echo "-b    Only builds psad."
		   echo "-i    Only installs psad. Kindly ensure, you will have RPM for psad, before using this option."
		   echo "-c    Build and install psad."
		   echo "-h    Print usage."
		   ;;
        esac
done
