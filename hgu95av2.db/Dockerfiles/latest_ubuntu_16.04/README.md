hgu95av2.db (Rpackage)

Build and run the container

	$docker build -t hgu95av2_db .
	$docker run -it --name=demo_hgu95av2_db hgu95av2_db


Test the working of Container:

Now inside the container type R and enter the  R shell.
Now run the following program line by line:

>> library(hgu95av2.db)
>> tt <- hgu95av2CHRLENGTHS
>> tt["1"]

OUTPUT:

248956422

