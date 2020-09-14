boot (Rpackage)
Build and run the container:
$docker build -t akima .
$docker run -it --name=demo_akima akima

Test the working of Container:
Inside the container type R and enter the R shell. Execute following code:

>> library(boot)
>> ratio <- function(d, w) sum(d$x * w)/sum(d$u * w)
>> boot(city, ratio, R = 999, stype = "w")

Output of last command:

	ORDINARY NONPARAMETRIC BOOTSTRAP
Call:
boot(data = city, statistic = ratio, R = 999, stype = "w")

Bootstrap Statistics :
    original     bias    std. error
t1* 1.520313 0.02841301   0.2106823
