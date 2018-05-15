org.Hs.eg.db (Rpackage)

Build and run the container

$docker build -t org_hs_eg_db .
$docker run -it --name=demo_org_hs_eg_db org_hs_eg_db

Test the working of Container:

Inside the container type R and enter the R shell. Execute following commands:

>> library(org.Hs.eg.db)
>> columns(org.Hs.eg.db)

OUTPUT:
 [1] "ACCNUM"       "ALIAS"        "ENSEMBL"      "ENSEMBLPROT"  "ENSEMBLTRANS"
 [6] "ENTREZID"     "ENZYME"       "EVIDENCE"     "EVIDENCEALL"  "GENENAME"
[11] "GO"           "GOALL"        "IPI"          "MAP"          "OMIM"
[16] "ONTOLOGY"     "ONTOLOGYALL"  "PATH"         "PFAM"         "PMID"
[21] "PROSITE"      "REFSEQ"       "SYMBOL"       "UCSCKG"       "UNIGENE"
[26] "UNIPROT"
