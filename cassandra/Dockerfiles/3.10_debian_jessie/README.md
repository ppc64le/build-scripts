How to Use Cassandra Container?

1.	Running the Cassandra container to keep the data persistent irrespective of the life of the container:
$docker run --name=some-cassandra -v /my/data/dir:/apache-cassandra-3.10/data/data -dP cassandra
2.	Accessing the cqlsh shell:
$ docker exec -it some-cassandra cqlsh
3.	Creating data:
-	Create KEYSPACE:
Eg. 
Cql> CREATE KEYSPACE myspace
          	         WITH replication = {'class':'SimpleStrategy', 'replication_factor' : 3}; 
Cql> DESCRIBE keyspaces;
-	Create Teable
Eg:
Cql> USE myspace;
               Cql> CREATE TABLE emp(
   	emp_id int PRIMARY KEY,
   	emp_name text,
   	emp_city text,
   	emp_sal varint,
   	emp_phone varint
  	 );

-	Insert Data in table:
               Cql> INSERT INTO emp (emp_id, emp_name, emp_city,
   	emp_phone, emp_sal) VALUES(1,'ram', 'Hyderabad', 9848022338, 50000);

               Cql>  INSERT INTO emp (emp_id, emp_name, emp_city,
   	emp_phone, emp_sal) VALUES(2,'robin', 'Hyderabad', 9848022339, 40000);

-	Verify the data:
 Cql> SELECT * FROM emp;
4.	Exit the container and check the dir on host which you mounted, viz, /my/data/dir, you will find all the data you that created in container.
5.	Checking the Cassandra nodes status:
$ docker exec -it some-cassandra nodetool ring
or
Run .$ bin/nodetool ring. inside Cassandra installation dir, to check the Cassandra status.

Can also check the status with following:
$ docker exec -i some-cassandra curl 127.0.0.1:9042

6.	The following command starts another Cassandra container instance and runs cqlsh (Cassandra Query Language Shell) against your original Cassandra container, allowing you to execute CQL statements against your database instance:
	$docker run -it --link some-cassandra:cassandra --rm cassandra cqlsh cassandra



