How To Use Mongodb Container?


.	Start the container using following command:
	$ docker run -itd -p 27017:27017 -p 28017:28017 container_name

.	Now you can attach to it, and access its shell as follows:
	$docker exec -it <container ID or name> mongo

.	If you also want to access the dashboard of mongodb server through browser then you need to start the container as follows:
	$ docker run -itd -p 27017:27017 -p 28017:28017 container_name mongod --httpinterface -rest

.	Now you can access the dashboard with http://VM_ip:28017
	And you can access the shell just as above.

.	Some commands to try on mongo shell:

	>show dbs

	-	Steps to create new db:
		
		>use mydb
		
		>db.users.save( {username:.some_user_name.} )

		>db.users.find()

