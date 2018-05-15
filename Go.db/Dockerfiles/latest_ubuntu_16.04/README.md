Go.db (Rpackage)

Build and run the container

$docker build -t go_db .
$docker run -it --name=demo_go_db go_db

Test the working of Container:

Inside the container type R and enter the R shell. Execute following commands:

>> library(Go.db)
>> columns(GO.db)

OUTPUT:
[1] "DEFINITION" "GOID"       "ONTOLOGY"   "TERM"

>> ls("package:GO.db")

OUTPUT:
 [1] "GO"            "GO_dbconn"     "GO_dbfile"     "GO_dbInfo"
 [5] "GO_dbschema"   "GO.db"         "GOBPANCESTOR"  "GOBPCHILDREN"
 [9] "GOBPOFFSPRING" "GOBPPARENTS"   "GOCCANCESTOR"  "GOCCCHILDREN"
[13] "GOCCOFFSPRING" "GOCCPARENTS"   "GOMAPCOUNTS"   "GOMFANCESTOR"
[17] "GOMFCHILDREN"  "GOMFOFFSPRING" "GOMFPARENTS"   "GOOBSOLETE"
[21] "GOSYNONYM"     "GOTERM"
