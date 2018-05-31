IRanges (Rpackage)

Build and run the container

	$docker build -t iranges .
	$docker run -it --name=demo_iranges iranges


Test the working of Container:

Now inside the container type R and enter the  R shell.
Now run the following program line by line:

>> library(IRanges)
>> x <- IntegerList(11:12, integer(0), 3:-2, compress=TRUE)
>> class(x)

OUTPUT:
[1] "CompressedIntegerList"
attr(,"package")
[1] "IRanges"
