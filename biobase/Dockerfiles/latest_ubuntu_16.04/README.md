Biobase (Rpackage)

Build and run the container

	$docker build -t biobase .
	$docker run -it --name=demo_biobase biobase


Test the working of Container:

Now inside the container type R and enter the  R shell.
Now run the following program line by line:

>> library(Biobase)
>> z <- new.env()
>> multiassign(letters, 1:26, envir=z)
>> contents(z)

OUTPUT:
$f
[1] NA

$g
[1] NA

$h
[1] NA
