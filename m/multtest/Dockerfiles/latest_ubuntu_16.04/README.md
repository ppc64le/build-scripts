multtest (Rpackage)

Build and run the container

$docker build -t multtest .
$docker run -it --name=demo_multtest multtest

Test the working of Container:

Inside the container type R and enter the R shell. Execute following commands:

>> library(multtest)
>> data(golub)
>> smallgd<-golub[1:100,]
>> classlabel<-golub.cl
>> res1<-mt.maxT(smallgd,classlabel)

OUTPUT:
b=100   b=200   b=300   b=400   b=500   b=600   b=700   b=800   b=900   b=1000
b=1100  b=1200  b=1300  b=1400  b=1500  b=1600  b=1700  b=1800  b=1900  b=2000
b=2100  b=2200  b=2300  b=2400  b=2500  b=2600  b=2700  b=2800  b=2900  b=3000
b=3100  b=3200  b=3300  b=3400  b=3500  b=3600  b=3700  b=3800  b=3900  b=4000
b=4100  b=4200  b=4300  b=4400  b=4500  b=4600  b=4700  b=4800  b=4900  b=5000
b=5100  b=5200  b=5300  b=5400  b=5500  b=5600  b=5700  b=5800  b=5900  b=6000
b=6100  b=6200  b=6300  b=6400  b=6500  b=6600  b=6700  b=6800  b=6900  b=7000
b=7100  b=7200  b=7300  b=7400  b=7500  b=7600  b=7700  b=7800  b=7900  b=8000
b=8100  b=8200  b=8300  b=8400  b=8500  b=8600  b=8700  b=8800  b=8900  b=9000
b=9100  b=9200  b=9300  b=9400  b=9500  b=9600  b=9700  b=9800  b=9900  b=10000
