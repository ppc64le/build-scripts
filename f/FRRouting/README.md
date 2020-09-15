## How to create FRR debian package for Ubuntu 18.04 for Power

Since there is no readily avaialable debian package for FRR on Power for Ubuntu 18.04, this README provides instructions on how to build one. Building the FRR debian package depends on other debian packages to be available and installed on the build server. They are libyang, librtr, librtr-dev. And since they are also not readily avaialable they will also need to be built.

### Download and Install libyang
```
$ wget http://ftp.us.debian.org/debian/pool/main/liby/libyang/libyang0.16_0.16.105-1_ppc64el.deb
$ wget http://ftp.us.debian.org/debian/pool/main/liby/libyang/libyang-dev_0.16.105-1_ppc64el.deb
$ wget http://ftp.us.debian.org/debian/pool/main/liby/libyang/libyang-cpp0.16_0.16.105-1_ppc64el.deb
$ sudo dpkg -i libyang0.16_0.16.105-1_ppc64el.deb
$ sudo dpkg -i libyang-dev_0.16.105-1_ppc64el.deb
$ sudo dpkg -i libyang-cpp0.16_0.16.105-1_ppc64el.deb
```

### Or Build libyang
Run the following instructions:
```
$ sudo apt-get install \
   git dpkg-dev bison cmake debhelper libcmocka-dev \
   libpcre3-dev swig python3-all-dev python3-all-dbg pkg-config
$ git clone https://github.com/opensourcerouting/libyang-debian
$ cd libyang-debian
$ dpkg-buildpackage -b -rfakeroot -us -uc
```

The dpkg-buildpackage command will fail with something like :

```
dh_makeshlibs: failing due to earlier errors
debian/rules:34: recipe for target 'override_dh_makeshlibs' failed
make[1]: *** [override_dh_makeshlibs] Error 2
make[1]: Leaving directory '/tmp/libyang-debian'
debian/rules:8: recipe for target 'binary' failed
make: *** [binary] Error 2
dpkg-buildpackage: error: fakeroot debian/rules binary subprocess returned exit status 2
```

If you page up the build output, you will see:
```
dpkg-gensymbols: warning: some new symbols appeared in the symbols file: see diff output below
dpkg-gensymbols: warning: some symbols or patterns disappeared in the symbols file: see diff output below
dpkg-gensymbols: warning: debian/libyang-cpp0.16/DEBIAN/symbols doesn't match completely debian/libyang-cpp0.16.symbols
```

To workaround the build error do the following: 
```
$ cp debian/libyang-cpp0.16/DEBIAN/symbols debian/libyang-cpp0.16.symbols
```

And re-run the dpkg-buildpackage command
```
$ dpkg-buildpackage -b -rfakeroot -us -uc
```

Once the command completes, the debian packages will be available
```
$ cd ..
$ ls *.deb
libyang-cpp-dev_0.16.105-1_ppc64el.deb  libyang0.16_0.16.105-1_ppc64el.deb       yang-tools_0.16.105-1_ppc64el.deb
libyang-cpp0.16_0.16.105-1_ppc64el.deb  python3-yang-dbg_0.16.105-1_ppc64el.deb
libyang-dev_0.16.105-1_ppc64el.deb      python3-yang_0.16.105-1_ppc64el.deb
```

Install the following packages:

```
$ sudo dpkg -i  libyang0.16_0.16.105-1_ppc64el.deb
$ sudo dpkg -i  libyang-cpp0.16_0.16.105-1_ppc64el.deb 
$ sudo dpkg -i  libyang-dev_0.16.105-1_ppc64el.deb
```

### Building librtr
Download 3 files required for building from source. At the time of this writing the latest librtr source can be found at https://launchpad.net/ubuntu/+source/librtr/0.6.3-1.

```
$ wget https://launchpad.net/ubuntu/+archive/primary/+sourcefiles/librtr/0.6.3-1/librtr_0.6.3-1.dsc
$ wget https://launchpad.net/ubuntu/+archive/primary/+sourcefiles/librtr/0.6.3-1/librtr_0.6.3.orig.tar.gz
$ wget https://launchpad.net/ubuntu/+archive/primary/+sourcefiles/librtr/0.6.3-1/librtr_0.6.3-1.debian.tar.xz
```
```
$ dpkg-source -x librtr_0.6.3-1.dsc
$ cd librtr-0.6.3
```

Before building the debian packages , install doxygen
```
$ sudo apt-get install doxygen libssh-dev
$ dpkg-buildpackage -b -rfakeroot -us -uc
$ cd ..
$ ls *.deb
librtr-dev_0.6.3-1_ppc64el.deb  librtr0_0.6.3-1_ppc64el.deb
librtr-doc_0.6.3-1_all.deb      rtr-tools_0.6.3-1_ppc64el.deb
```
```
$ sudo dpkg -i librtr0_0.6.3-1_ppc64el.deb
$ sudo dpkg -i librtr-dev_0.6.3-1_ppc64el.deb
```

### Build frr debian package
There are some required packages for building frr. Please refer to :
http://docs.frrouting.org/projects/dev-guide/en/latest/building-frr-for-ubuntu1804.html

```
$ sudo apt-get install \
   git autoconf automake libtool make gawk libreadline-dev texinfo \
   libpam0g-dev libjson-c-dev flex python-pytest devscripts \
   libc-ares-dev python3-dev libsystemd-dev python-ipaddress \
   python3-sphinx install-info build-essential libsystemd-dev
```

Instructions referenced to build debian package: 
http://docs.frrouting.org/projects/dev-guide/en/latest/packaging-debian.html

```
$ git clone https://github.com/frrouting/frr.git frr
$ cd frr 
$ git checkout frr-7.0
$ sudo mk-build-deps --install debian/control
$ ./tools/tarsource.sh -V
$ dpkg-buildpackage -Ppkg.frr.nortrlib -uc -us 
$ cd ..
$ ls *.deb
frr-doc_7.0-0_all.deb  frr-pythontools_7.0-0_all.deb  frr-snmp_7.0-0_ppc64el.deb  frr_7.0-0_ppc64el.deb
```
