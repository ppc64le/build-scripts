siggenes(Rpackage)

Build and run the container

$docker build -t siggenes .
$docker run -it --name=demo_siggenes siggenes

Test the working of Container:

Inside the container type R and enter the R shell. Execute following commands:

>> library(siggenes)
>> x <- rnorm(10000)
>> out <- denspr(x, addx=TRUE)

OUTPUT:
Loading required package: KernSmooth
KernSmooth 2.23 loaded
Copyright M. P. Wand 1997-2009

>> plot(out)
