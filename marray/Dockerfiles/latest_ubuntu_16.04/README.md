marray (Rpackage)

Build and run the container

$docker build -t marray .
$docker run -it --name=demo_marray marray

Test the working of Container:

Inside the container type R and enter the R shell. Execute following commands:

>> library(marray)
>> data(swirl)
>> boxplot(swirl[,3])
>> boxplot(swirl[,3], xvar=NULL, col="green")
>> checkTargetInfo(swirl)

OUTPUT:
[1] TRUE
