KernSmooth (Rpackage)

Build and run the container

	$docker build -t kernsmooth .
	$docker run -it --name=demo_kernsmooth kernsmooth


Test the working of Container:

Now inside the container type R and enter the  R shell.
Now run the following program line by line:

>> library(KernSmooth)
>> data(geyser, package="MASS")
>> x <- geyser$duration
>> est <- bkde(x, bandwidth=0.25)
>> plot(est, type="l")

OUTPUT:
No output as such but commands will pass without error.
