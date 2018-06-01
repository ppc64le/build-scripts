cluster (Rpackage)

Build and run the container:

$docker build -t cluster .
$docker run --name demo_cluster -i -t cluster /bin/bash

Test the working of Container:
        Now inside the container type R and enter the  R shell.
	Now run the following program line by line:

> library(cluster)
> x <- rbind(cbind(rnorm(10,0,0.5), rnorm(10,0,0.5)),
+ cbind(rnorm(15,5,0.5), rnorm(15,5,0.5)))
> clusplot(pam(x, 2))
> x4 <- cbind(x, rnorm(25), rnorm(25))
> clusplot(pam(x4, 2))
> data(agriculture)
> aa <- agnes(agriculture)
> coef(aa)
[1] 0.7818932
> coef(as.hclust(aa))
[1] 0.7818932
> coefHier(aa)
[1] 0.7818932
