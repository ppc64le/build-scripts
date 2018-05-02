labeling(Rpackage)
Build and run the container:

$docker build -t labeling .
$docker run -it --name=demo_ labeling labeling

Test the working of Container:
Inside the container type R and enter the R shell. Execute following code:

>> library(labeling)
>> heckbert(8.1, 14.1, 4)

Output:
       [1]  5 10 15
