plyr (Rpackage)
Build and run the container:

$docker build -t plyr .
$docker run -it --name=demo_ plyr plyr

Test the working of Container:
Inside the container type R and enter the R shell. Execute following code:

>> library(plyr)
>> dim(ozone)
>> aaply(ozone, 1, mean) 
      
Output of last command:

	-21.2    -18.7    -16.2    -13.7    -11.2     -8.7     -6.2     -3.7
266.8194 263.0104 260.6493 258.8148 257.8657 256.9306 256.1007 255.6238
    -1.2      1.3      3.8      6.3      8.7     11.2     13.7     16.2
255.5081 255.0718 254.1771 254.5139 256.0729 258.8160 261.3009 263.7072
    18.7     21.2     23.7     26.2     28.7     31.2     33.7     36.2
266.4005 269.9294 273.9062 279.5926 285.3356 293.2234 300.2546 308.7153
