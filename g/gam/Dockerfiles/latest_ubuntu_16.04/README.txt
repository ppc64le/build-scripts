gam (Rpackage)
Build and run the container:

$docker build -t gam.
$docker run -it --name=demo_gam gam

Test the working of Container:
Inside the container type R and enter the R shell. Execute following code:

>> library(gam)
>> data(gam.data)
>> gam(y ~ s(x) + z, data=gam.data)

Output of last command will be:
       Call:
       gam(formula = y ~ s(x) + z, data = gam.data)
       
       Degrees of Freedom: 99 total; 93.99988 Residual
       Residual Deviance: 7.90768
