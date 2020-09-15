RandomForest(Rpackage)
Build and run the container:

$docker build -t random-forest .
$docker run -it --name=demo_random-forest random-forest

Test the working of Container:
Inside the container type R and enter the R shell. Execute following code:

>> library(randomForest)
>> data(fgl, package="MASS")
>> fgl.res <- tuneRF(fgl[,-10], fgl[,10], stepFactor=1.5)
      
Output:
       mtry = 3  OOB error = 22.43%
       Searching left ...
       mtry = 2        OOB error = 19.16%
       0.1458333 0.05
       Searching right ...
       mtry = 4        OOB error = 23.36%
       -0.2195122 0.05
