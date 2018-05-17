RSQLite (Rpackage)

Build and run the container

$docker build -t rsqlite .
$docker run -it --name=demo_rsqlite rsqlite

Test the working of Container:

Inside the container type R and enter the R shell. Execute following commands:

>> library(RSQLite)
>> db <- RSQLite::datasetsDb()
>> dbListTables(db)

OUTPUT:

 [1] "BOD"              "CO2"              "ChickWeight"      "DNase"
 [5] "Formaldehyde"     "Indometh"         "InsectSprays"     "LifeCycleSavings"
 [9] "Loblolly"         "Orange"           "OrchardSprays"    "PlantGrowth"
[13] "Puromycin"        "Theoph"           "ToothGrowth"      "USArrests"
[17] "USJudgeRatings"   "airquality"       "anscombe"         "attenu"
[21] "attitude"         "cars"             "chickwts"         "esoph"
[25] "faithful"         "freeny"           "infert"           "iris"
[29] "longley"          "morley"           "mtcars"           "npk"
[33] "pressure"         "quakes"           "randu"            "rock"
[37] "sleep"            "stackloss"        "swiss"            "trees"
[41] "warpbreaks"       "women"
