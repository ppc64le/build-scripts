AnnotationDbi (Rpackage)

Build and run the container

$docker build -t annotation_dbi .
$docker run -it --name=demo_annotation_dbi annotation_dbi

Test the working of Container:

Inside the container type R and enter the R shell. Execute following commands:

>> library(AnnotationDbi)
>> toSQLStringSet(letters[1:4])

OUTPUT:
[1] "'a','b','c','d'"
