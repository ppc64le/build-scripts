rpart (Rpackage)

Build and run the container:

$docker build -t rpart .
$docker run --name demo_rpart -i -t rpart /bin/bash

Test the working of Container:
Inside the container type R and enter the  R shell. Execute following code:

>> library(rpart)
>> z.auto <- rpart(Mileage ~ Weight, car.test.frame)
>> printcp(z.auto)

Output of the last command will be :

Regression tree:
rpart(formula = Mileage ~ Weight, data = car.test.frame)

Variables actually used in tree construction:
[1] Weight

Root node error: 1354.6/60 = 22.576

n= 60

        CP nsplit rel error  xerror     xstd
1 0.595349      0   1.00000 1.02091 0.177406
2 0.134528      1   0.40465 0.55778 0.103508
3 0.012828      2   0.27012 0.41780 0.077284
4 0.010000      3   0.25729 0.40997 0.069851
