Digest (Rpackage)

Build and run the container

$docker build -t digest .
$docker run -it --name=demo_digest digest

Test the working of Container:

Inside the container type R and enter the R shell. Execute following commands:

>> library(digest)
>> makeRaw("1234567890ABCDE")

OUTPUT:

[1] 31 32 33 34 35 36 37 38 39 30 41 42 43 44 45
