Hmisc (Rpackage)
Build and run the container:

$docker build -t hmisc .
$docker run -it --name=demo_hmisc hmisc

Test the working of Container:
Inside the container type R and enter the R shell. Execute following code:

>> library(Hmisc)
>> approxExtrap(1:3,1:3,xout=c(0,4))

Output of last command will be:
       
       $x
       [1] 0 4
       
       $y
       [1] 0 4
