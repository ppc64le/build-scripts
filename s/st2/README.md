# StackStorm/st2 build

The build-script takes care of building st2 and executing the unit tests.

The test execution needs mongodb server and rabbitmq server running. And for
being able to start the two services inside a UBI 8.2 container, please use
the following command to start the container:

```
docker run -d --privileged -e container=docker --tmpfs /run \
	-v /sys/fs/cgroup:/sys/fs/cgroup:ro --name st2_ubi8 \
	registry.access.redhat.com/ubi8/ubi:8.2 /sbin/init
```

Also, the script needs to be executed in non-root mode. So, a non-root user
needs to be created and added to the sudoers i.e. wheel group as (replace 
<USER> with the intended username):

```
yum install -y sudo
useradd \
	--create-home \
	--home-dir /home/<USER> \
	--shell /bin/bash \
	<USER>
usermod -aG wheel <USER>
```

Also, passwordless authentication needs to be enabled for the script to be
executed without prompting the user for password. `/etc/sudoers` file needs
to be updated using `visudo` command:

the following line needs to be disabled:
```
%wheel        ALL=(ALL)       ALL
```

the following line needs to be enabled:
```
# %wheel  ALL=(ALL)       NOPASSWD: ALL
```

