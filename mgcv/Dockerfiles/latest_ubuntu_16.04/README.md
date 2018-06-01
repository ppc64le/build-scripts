mgcv (Rpackage)

Build and run the container

	$docker build -t mgcv .
	$docker run -it --name=demo_mgcv mgcv


Test the working of Container:

Now inside the container type R and enter the  R shell.
Now run the following program line by line:

>> library(mgcv)
>> n<-20;c1<-4;c2<-7
>> X1<-matrix(runif(n*c1),n,c1)
>> X2<-matrix(runif(n*c2),n,c2)
>> X2[,3]<-X1[,2]+X2[,4]*.1
>> X2[,5]<-X1[,1]*.2+X1[,2]*.04
>> fixDependence(X1,X2)

OUTPUT:
[1] 3 5
