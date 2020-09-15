preprocessorCore (Rpackage)

Build and run the container:

$docker build -t preprocessorcore .
$docker run --name demo_preprocessorcore -i -t preprocessorcore /bin/bash

Test the working of Container:
Inside the container type R and enter the R shell. Execute following commands:

>> library(preprocessorcore)
>> y <- matrix(10+rnorm(100),20,5)
>> colSummarizeAvg(y)

Output of the last command will be :

$Estimates
[1] 10.154864  9.908495  9.958157  9.955822 10.199821

$StdErrors
[1] 0.1789468 0.2568311 0.2134951 0.2575599 0.2272671
