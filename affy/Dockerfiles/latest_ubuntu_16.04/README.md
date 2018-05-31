Affy (Rpackage)

Build and run the container

	$docker build -t affy .
	$docker run -it --name=demo_affy affy


Test the working of Container:

Now inside the container type R and enter the  R shell.
Now run the following program line by line:

>> library(affy)
>> affy.opt <- getOption("BioC")$affy
>> .setAffyOptions(affy.opt)

OUTPUT:
NULL
