1) First create a docker image :

	docker build -t lustre-client/ppc64le:16.04 .


2) How to use this Image :

 
	a) First run the image in privileged mode :

		docker run --name lustre_client --privileged -it lustre-client/ppc64le:16.04 bash

	Inside the above docker container created ( lustre_client ) , please run below
	b) Create a mount point: 

		mkdir /mnt/lustre  
	
	c) Mount the lustre FS:
		
		mount -t lustre <lustre-server-ip>@tcp0:/<lustre-fs-name> <mount-point>  (e.g. mount -t lustre 10.51.229.219@tcp0:/lustre /mnt/lustre )

	d) check mount details : 

		df -T | grep lustre

	e) Enter into the mount directory :

		cd /mnt/lustre  

	f) Create any file for testing

		echo "testing" > test.txt

	g) Login into another client and check "test.txt" file is updated there or not (i.e. in mount directory of client2)

