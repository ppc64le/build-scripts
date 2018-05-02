Stringi (Rpackage)
Build and run the container:

$docker build -t stringi .
$docker run -it --name=demo_stringi stringi

Test the working of Container:
Inside the container type R and enter the R shell. Execute following code:

>> library(stringi)
>> stri_cmp_lt("hladny", "chladny", locale="pl_PL")

Output:
       [1] FALSE
       >> stri_cmp_lt("hladny", "chladny", locale="sk_SK")
      Output of last command:

      [1] TRUE
