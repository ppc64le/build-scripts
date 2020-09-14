latticeExtra (Rpackage)

Build and run the container

$docker build -t lattice-extra .
$docker run -it --name=demo_lattice-extra lattice-extra

Test the working of Container:

Inside the container type R and enter the R shell. Execute following commands:

>> library(latticeExtra)
>> b1 <- barley
>> b2 <- barley
>> b2$yield <- b2$yield + 10

OUTPUT:
Should run without any error message.
