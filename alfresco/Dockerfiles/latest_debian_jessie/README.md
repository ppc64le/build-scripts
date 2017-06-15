1) Build image from dockerfile
	docker build -t alfresco .
	
2) start MariaDB container
    docker run --name mysql_db -d -p 3306:3306 ppc64le/mariadb:10.1

	Make sure to create the database and a user:-

       CREATE DATABASE alfresco default character set utf8 collate utf8_bin;

	   create user 'alfresco'@'localhost' identified by 'alfresco';

	   grant all on alfresco.* to 'alfresco'@'localhost' identified by 'alfresco' with grant option;

       grant all on alfresco.* to 'alfresco'@'%' identified by 'alfresco' with grant option;
	   
3) start alfresco container

    docker run --cap-add=SYS_PTRACE --name=test_alfresco --link mysql_db:mysql_db -d -p 8080:8080 alfresco

	Go to - http://<hostname/IP Address>:8080/alfresco   (Note - Server will be up in 5 to 7 minutes)

	Go to - http://<hostname/IP Address>:8080/share

	The default user name and password are:

	username: admin

	password: admin

