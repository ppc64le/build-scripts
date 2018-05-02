iterators (Rpackage)
Build and run the container:

$docker build -t iterators .
$docker run -it --name=demo_iterators iterators

Test the working of Container:
Inside the container type R and enter the R shell. Execute following code:

>> library(iterators)
>> a <- array(1:8, c(2, 2, 2))
>> it <- iapply(a, 3)
>> as.list(it)

Output of last command:

	[[1]]
     [,1] [,2]
[1,]    1    3
[2,]    2    4

[[2]]
     [,1] [,2]
[1,]    5    7
[2,]    6    8
