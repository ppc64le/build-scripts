Prodlim (Rpackage)

Build and run the container

	$docker build -t prodlim .
	$docker run -it --name=demo_prodlim prodlim


Test the working of Container:

Now inside the container type R and enter the  R shell.
Now run the following program line by line:

>> library(prodlim)
>> dat= data.frame(time=1:5,event=letters[1:5])
>> x=with(dat,Hist(time,event))
>> unclass(x)

OUTPUT:

     time status event
[1,]    1      1     1
[2,]    2      1     2
[3,]    3      1     3
[4,]    4      1     4
[5,]    5      1     5
attr(,"states")
[1] "a" "b" "c" "d" "e"
attr(,"cens.type")
[1] "uncensored"
attr(,"cens.code")
[1] "0"
attr(,"model")
[1] "competing.risks"
attr(,"entry.type")
[1] ""

>> getEvent(x)

OUTPUT:
[1] a b c d e
Levels: a b c d e unknown

