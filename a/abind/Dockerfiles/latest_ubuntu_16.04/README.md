Abind (Rpackage)

Build and run the container

	$docker build -t abind .
	$docker run -it --name=demo_abind abind


Test the working of Container:

Now inside the container type R and enter the  R shell.
Now run the following program line by line:

>> library(abind)
>> x <- array(1:24,dim=c(2,3,4),dimnames=list(letters[1:2],LETTERS[1:3],letters[23:26]))
>> asub(x, list(1:2,3:4), c(1,3))

OUTPUT:
, , y

   A  B  C
a 13 15 17
b 14 16 18

, , z

   A  B  C
a 19 21 23
b 20 22 24
