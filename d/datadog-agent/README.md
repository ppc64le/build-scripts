# Build datadog-agent on RHEL

In order to build datadog-agent, please copy the contents of current directory to a directory
on the build machine.

Enable execute permissions for the build script and run it as:

```
# chmod +x datadog_rhel8.2.sh
# ./datadog_rhel8.2.sh
```

You can run the datadog-agent with 
```
./bin/agent/agent run -c bin/agent/dist/datadog.yaml
```
# Build datadog-agent on SLES12 SP5

Kindly add following repo, for libffi installation,

```
# cat /etc/zypp/repos.d/devel_gcc.repo
[devel_gcc]
name=GNU Compiler Collection container (SLE-12)
enabled=1
autorefresh=0
baseurl=https://download.opensuse.org/repositories/devel:/gcc/SLE-12/
type=rpm-md
gpgcheck=1
gpgkey=https://download.opensuse.org/repositories/devel:/gcc/SLE-12/repodata/repomd.xml.key
```
Execute build script as

```
# ./datadog_sles12_sp5.sh
```
