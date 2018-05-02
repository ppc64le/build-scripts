tables (Rpackage)

Build and run the container:

$docker build -t tables .
$docker run -it -name=demo_tables tables .

Test the working of Container:
Inside the container type R and enter the R shell. Execute following code:

>> library(tables)
>> set.seed(100)
>> X <- rnorm(10)
>> X

Output of the last command will be :

[1] -0.50219235  0.13153117 -0.07891709  0.88678481  0.11697127  0.31863009
[7] -0.58179068  0.71453271 -0.82525943 -0.35986213
