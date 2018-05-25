Derby

Build Dockerfile

$docker build -t derby .

Running and Testing:

Run derby-server container
 $ docker run -d --name=derby -p 1527:1527 derby
	
Run derby cli(ij) and connect to server from it
 $ docker run -it --name=derby-client derby ij
	
Now you will enter the ij shell. 
To connect to derby server from here, type following in derby-client container.
 ij> connect 'jdbc:derby://host_ip:1527/MyDbTest;create=true';
	 

Now MyDbTest database will get created and you can create table here as follows:

 ij> CREATE TABLE FIRSTTABLE (ID INT PRIMARY KEY,NAME VARCHAR(12));
0 rows inserted/updated/deleted
 ij> INSERT INTO FIRSTTABLE VALUES (10,'TEN'),(20,'TWENTY'),(30,'THIRTY');
3 rows inserted/updated/deleted
 ij> SELECT * FROM FIRSTTABLE;
ID         |NAME
------------------------
10         |TEN
20         |TWENTY
30         |THIRTY

3 rows selected
