rspace (Rpackage)

Build and run the container:

$docker build -t colorspace .
$docker run -it -name=demo_colorspace colorspace .

Test the working of Container:
Inside the container type R and enter the R shell. Execute following code:

>> library(colorspace)
>> x <- RGB(1, 0, 0)
>> coords(as(x, "HSV"))

Output of the last command will be :

  H S V
[1,] 360 1 1
