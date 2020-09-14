Foreign (Rpackage)
Build and run the container:

$docker build -t foreign .
$docker run -it --name=demo_ foreign foreign

Test the working of Container:
Inside the container type R and enter the  R shell. Execute following code:

>> library(foreign)
>> x <- read.dbf(system.file("files/sids.dbf", package="foreign")[1])
>> str(x)
>> summary(x)

Output of last command:

	AREA          PERIMETER         CNTY_         CNTY_ID            NAME  
 Min.   :0.0420   Min.   :0.999   Min.   :1825   Min.   :1825   Alamance : 1 
 1st Qu.:0.0910   1st Qu.:1.324   1st Qu.:1902   1st Qu.:1902   Alexander: 1 
 Median :0.1205   Median :1.609   Median :1982   Median :1982   Alleghany: 1 
 Mean   :0.1263   Mean   :1.673   Mean   :1986   Mean   :1986   Anson    : 1 
 3rd Qu.:0.1542   3rd Qu.:1.859   3rd Qu.:2067   3rd Qu.:2067   Ashe     : 1 
 Max.   :0.2410   Max.   :3.640   Max.   :2241   Max.   :2241   Avery    : 1 
                                                                (Other)  :94 
      FIPS        FIPSNO         CRESS_ID          BIR74           SID74     
 37001  : 1   Min.   :37001   Min.   :  1.00   Min.   :  248   Min.   : 0.00 
 37003  : 1   1st Qu.:37050   1st Qu.: 25.75   1st Qu.: 1077   1st Qu.: 2.00 
 37005  : 1   Median :37100   Median : 50.50   Median : 2180   Median : 4.00 
 37007  : 1   Mean   :37100   Mean   : 50.50   Mean   : 3300   Mean   : 6.67 
 37009  : 1   3rd Qu.:37150   3rd Qu.: 75.25   3rd Qu.: 3936   3rd Qu.: 8.25 
 37011  : 1   Max.   :37199   Max.   :100.00   Max.   :21588   Max.   :44.00 
 (Other):94                                                                  
    NWBIR74           BIR79           SID79          NWBIR79
 Min.   :   1.0   Min.   :  319   Min.   : 0.00   Min.   :    3.0
 1st Qu.: 190.0   1st Qu.: 1336   1st Qu.: 2.00   1st Qu.:  250.5
 Median : 697.5   Median : 2636   Median : 5.00   Median :  874.5
 Mean   :1050.8   Mean   : 4224   Mean   : 8.36   Mean   : 1352.8
 3rd Qu.:1168.5   3rd Qu.: 4889   3rd Qu.:10.25   3rd Qu.: 1406.8
 Max.   :8027.0   Max.   :30757   Max.   :57.00   Max.   :11631.0
