How To Use Geode Container?

.	Start the geode container as follows:
   	$docker run -it  -p 8080:80 -p 10334:10334 -p 40404 -p 1099:1099 -p 7070:7070 --name=<container name> geode

.	Now you will get a geode shell

.	Now type following command in ghfs shell:
	> start locator --name=loc1

.	Now if you want you can also access geode pulse dashboard from browser with url:
	http://vm_ip: 7070/pulse/
 

