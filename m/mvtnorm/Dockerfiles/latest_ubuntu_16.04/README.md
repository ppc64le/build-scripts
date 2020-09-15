mvtnorm (Rpackage)

Build and run the container:

$docker build -t mvtnorm .
$docker run --name demo_mvtnorm -i -t mvtnorm /bin/bash

Test the working of Container:
        Now inside the container type R and enter the  R shell.
	Now run the following program line by line:

> library(mvtnorm)
> dmvnorm(x=c(0,0))
[1] 0.1591549
> dmvnorm(x=c(0,0), mean=c(1,1))
[1] 0.05854983
> sigma <- matrix(c(4,2,2,3), ncol=2)
> x <- rmvnorm(n=500, mean=c(1,2), sigma=sigma)
> colMeans(x)
[1] 0.992497 1.896763
> var(x)
         [,1]     [,2]
[1,] 4.177774 1.957381
[2,] 1.957381 2.704036
> x <- rmvnorm(n=500, mean=c(1,2), sigma=sigma, method="chol")
> colMeans(x)
[1] 1.001032 1.928063
> var(x)
         [,1]     [,2]
[1,] 4.382499 2.032597
[2,] 2.032597 2.549872
