hgu95av2cdf (Rpackage)

Build and run the container

$docker build -t hgu95av2cdf .
$docker run -it --name=demo_hgu95av2cdf hgu95av2cdf

Test the working of Container:

Inside the container type R and enter the R shell. Execute following commands:

>> library(hgu95av2cdf)
>> xy2i(5,5)

OUTPUT:
[1] 3206

#NOTE: It might give deprication warning message.
