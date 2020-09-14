XML (Rpackage)

Build and run the container

$docker build -t xml .
$docker run -it --name=demo_xml xml

Test the working of Container:

Inside the container type R and enter the R shell. Execute following commands:

>> library(XML)
>> n = xmlNode("data", attrs = c("numVars" = 2, numRecords = 3))
>> n = append.xmlNode(n, xmlNode("varNames", xmlNode("string", "A"), xmlNode("string", "B")))
>> print(n)

OUTPUT:

<data numVars="2" numRecords="3">
 <varNames>
  <string>A</string>
  <string>B</string>
 </varNames>
</data>
