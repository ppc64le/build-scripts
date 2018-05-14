stringr (Rpackage)

Build and run the container:

$docker build -t stringr .
$docker run --name demo_stringr -i -t stringr /bin/bash

Test the working of Container:
Inside the container type R and enter the R shell. Execute following commands:

>> library(stringr)
>> dog <- "The quick brown dog"
>> str_to_upper(dog)

Output of the last command will be :
[1] "THE QUICK BROWN DOG"

>> str_to_lower(dog)

Output of the last command will be :
[1] "the quick brown dog"

>> str_to_title(dog)

Output of the last command will be :
[1] "The Quick Brown Dog"
