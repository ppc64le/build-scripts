httpRequest (Rpackage)

Build and run the container:

$docker build -t httprequest .
$docker run --name demo_httprequest -i -t httprequest /bin/bash

Test the working of Container:
Inside the container type R and enter the R shell. Execute following commands:

>> library(httpRequest)
>> host <- "api.scb.se"
>> path <- "/OV0104/v1/doris/en/ssd"
>> data <- '{"format":"json"}'
>> simplePostToHost(host, path, data, contenttype="text/json")

Output of the last command will be :

[1] "HTTP/1.1 200 OK\r\nCache-Control: private\r\nContent-Type: application/json; charset=utf-8\r\nServer: Microsoft-IIS/10.0\r\nAccess-Control-Allow-Origin: *\r\nX-Powered-By: ASP.NET\r\nDate: Mon, 14 May 2018 12:22:12 GMT\r\nContent-Length: 880\r\n\r\n[{\"id\":\"AM\",\"type\":\"l\",\"text\":\"Labour market\"},{\"id\":\"BE\",\"type\":\"l\",\"text\":\"Population\"},{\"id\":\"BO\",\"type\":\"l\",\"text\":\"Housing, construction and building\"},{\"id\":\"EN\",\"type\":\"l\",\"text\":\"Energy\"},{\"id\":\"FM\",\"type\":\"l\",\"text\":\"Financial markets\"},{\"id\":\"HA\",\"type\":\"l\",\"text\":\"Trade in goods and services\"},{\"id\":\"HE\",\"type\":\"l\",\"text\":\"Household finances\"},{\"id\":\"JO\",\"type\":\"l\",\"text\":\"Agriculture, forestry and fishery\"},{\"id\":\"LE\",\"type\":\"l\",\"text\":\"Living conditions\"},{\"id\":\"ME\",\"type\":\"l\",\"text\":\"Democracy\"},{\"id\":\"MI\",\"type\":\"l\",\"text\":\"Environment\"},{\"id\":\"NR\",\"type\":\"l\",\"text\":\"National accounts\"},{\"id\":\"NV\",\"type\":\"l\",\"text\":\"Business activities\"},{\"id\":\"OE\",\"type\":\"l\",\"text\":\"Public finances\"},{\"id\":\"PR\",\"type\":\"l\",\"text\":\"Prices and Consumption\"},{\"id\":\"TK\",\"type\":\"l\",\"text\":\"Transport and communications\"},{\"id\":\"UF\",\"type\":\"l\",\"text\":\"Education and research\"}]"
