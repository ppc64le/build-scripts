# Docker installation on RHEL/power 

## Option 1: Using binaries 

- To install higher docker version, please download the required version from https://download.docker.com/linux/static/stable/ppc64le/ and copy binaries in /usr/bin as below. 
```
$ wget https://download.docker.com/linux/static/stable/ppc64le/docker-18.06.3-ce.tgz 
$ tar xzvf docker-18.06.3-ce.tgz 
$ sudo cp docker/* /usr/bin/ 
```

- You will need to create the service files manually to enable docker as a systemd service. ( non-root user ) 
```
$ wget https://raw.githubusercontent.com/moby/moby/master/contrib/init/systemd/docker.service 
$ wget https://raw.githubusercontent.com/moby/moby/master/contrib/init/systemd/docker.socket 
$ sudo cp docker.* /etc/systemd/system/ 
```

- sudo chmod 644 /etc/systemd/system/docker.* ( not required ) 
- Create the docker group:  
$ sudo groupadd docker 

- Add the users that should have Docker access to the docker group:  
```
$ sudo usermod -a -G docker <user> 
$ sudo systemctl enable docker 
$ sudo systemctl start docker 
$ sudo systemctl status docker 
```

## Option 2: Using rpm on RHEL 7/8 ( using centos rpms) 
```
$ dnf install https://dl.fedoraproject.org/pub/epel/7/ppc64le/Packages/c/containerd-1.2.14-1.el7.ppc64le.rpm
$ dnf install https://oplab9.parqtec.unicamp.br/pub/ppc64el/docker/version-19.03.8/centos/docker-ce-cli-19.03.8-3.el7.ppc64le.rpm 
$ dnf install https://oplab9.parqtec.unicamp.br/pub/ppc64el/docker/version-19.03.8/centos/docker-ce-19.03.8-3.el7.ppc64le.rpm 

$ systemctl enable docker 
$ systemctl start docker 
$ systemctl is-active docker 
```
