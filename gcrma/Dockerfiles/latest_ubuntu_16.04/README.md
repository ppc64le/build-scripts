Gcrma (Rpackage)

Build and run the container

$docker build -t gcrma .
$docker run -it --name=demo_gcrma gcrma

Test the working of Container:

Inside the container type R and enter the R shell. Execute following commands:

>> library(Gcrma)
>> sessionInfo()

OUTPUT:
Library Gcrma should be mentioned in the output.
