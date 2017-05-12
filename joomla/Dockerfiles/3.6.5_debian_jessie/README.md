How to use this image

I)Command to create a docker image - 

	docker build -t joomla .

II)The following environment variables are also used for configuring your Joomla instance:

-e JOOMLA_DB_HOST=... (defaults to the IP and port of the linked mysql container)
-e JOOMLA_DB_USER=... (defaults to "root")
-e JOOMLA_DB_PASSWORD=... (defaults to the value of the MYSQL_ROOT_PASSWORD environment variable from the linked mysql container)
-e JOOMLA_DB_NAME=... (defaults to "joomla")
If the JOOMLA_DB_NAME specified does not already exist on the given MySQL server, it will be created automatically upon startup of the joomla container,
provided that the JOOMLA_DB_USER specified has the necessary permissions to create it.

III)Command to create joomla container - 
$docker run --name some-joomla --link some-mysql:mysql -e JOOMLA_DB_USER=<user> -e JOOMLA_DB_PASSWORD=<DB user password> -p 8080:80 -d joomla

Then,you will be able to access joomla portal via http://localhost:8080 or http://host-ip:8080 in a browser.
