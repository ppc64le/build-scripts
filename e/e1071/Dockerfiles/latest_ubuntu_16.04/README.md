e1071 (Rpackage)

Build and run the container:

$docker build -t e1071 .
$docker run -it --name=demo_e1071 e1071 .

Test the working of Container:
Inside the container type R and enter the R shell. Execute following code:

>> library(e1071)
>> x <- matrix(NA, 5, 5)
>> diag(x) <- 0
>> x[1,2] <- 30; x[1,3] <- 10
>> x[2,4] <- 70; x[2,5] <- 40
>> x[3,4] <- 50; x[3,5] <- 20
>> x[4,5] <- 60
>> x[5,4] <- 10
>> print(x)

Output of the last command will be :

     [,1] [,2] [,3] [,4] [,5]
[1,]    0   30   10   NA   NA
[2,]   NA    0   NA   70   40
[3,]   NA   NA    0   50   20
[4,]   NA   NA   NA    0   60
[5,]   NA   NA   NA   10    0
