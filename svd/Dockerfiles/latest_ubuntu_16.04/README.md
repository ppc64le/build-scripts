svd (Rpackage)

Build and run the container

$docker build -t svd .
$docker run -it --name=demo_svd svd

Test the working of Container:

Inside the container type R and enter the R shell. Execute following commands:

>> library(svd)
>> sessionInfo() 
