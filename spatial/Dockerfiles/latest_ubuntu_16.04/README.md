spatial (Rpackage)

Build and run the container:

$docker build -t spatial .
$docker run --name demo_spatial -i -t spatial /bin/bash

Test the working of Container:
Inside the container type R and enter the R shell. Execute following commands:

>> library(spatial)
>>pines <- ppinit("pines.dat")
>> pplik(pines, 0.7)

Output of the last command will be:

[1] 0.1508756
