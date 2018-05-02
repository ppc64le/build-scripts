gbm (Rpackage)

Build and run the container:

$docker build -t gbm .
$docker run -it -name=demo_gbm gbm .

Test the working of Container:
Inside the container type R and enter the R shell. Execute following code:

>> library(gbm)
>> N <- 1000
>> X1 <- runif(N)
>> X2 <- 2*runif(N)
>> X3 <- ordered(sample(letters[1:4],N,replace=TRUE),levels=letters[4:1])
>> X4 <- factor(sample(letters[1:6],N,replace=TRUE))
>> X5 <- factor(sample(letters[1:3],N,replace=TRUE))
>> X6 <- 3*runif(N)
>> mu <- c(-1,0,1,2)[as.numeric(X3)]
>> SNR <- 10
>> Y <- X1**1.5 + 2 * (X2**.5) + mu
>> sigma <- sqrt(var(Y)/SNR)
>> Y <- Y + rnorm(N,0,sigma)
>> X1[sample(1:N,size=500)] <- NA
>> X4[sample(1:N,size=300)] <- NA
>> data <- data.frame(Y=Y,X1=X1,X2=X2,X3=X3,X4=X4,X5=X5,X6=X6)
>> gbm1 <-
+ gbm(Y~X1+X2+X3+X4+X5+X6,
+ data=data,
+ var.monotone=c(0,0,0,0,0,0),
+ distribution="gaussian",
+ n.trees=1000,
+ shrinkage=0.05,
+ interaction.depth=3,
+ bag.fraction = 0.5,
+ train.fraction = 0.5,
+ n.minobsinnode = 10,
+ cv.folds = 3,
+ keep.data=TRUE,
+ verbose=FALSE,
+ n.cores=1)
>> best.iter <- gbm.perf(gbm1,method="OOB")
Warning message:
In gbm.perf(gbm1, method = "OOB") :
  OOB generally underestimates the optimal number of iterations although predictive performance is reasonably competitive. Using cv.folds>0 when calling gbm usually results in improved predictive performance.
>> print(best.iter)

Output of the last command will be :

[1] 83
