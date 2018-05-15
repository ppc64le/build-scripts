vsn(Rpackage)

Build and run the container

$docker build -t vsn .
$docker run -it --name=demo_vsn vsn

Test the working of Container:

Inside the container type R and enter the R shell. Execute following commands:

>> library(vsn)
>> data("lymphoma")
>> lymphoma
>> pData(lymphoma)

OUTPUT:
                     name    sample dye
lc7b047.reference lc7b047 reference Cy3
lc7b047.CLL-13    lc7b047    CLL-13 Cy5
lc7b048.reference lc7b048 reference Cy3
lc7b048.CLL-13    lc7b048    CLL-13 Cy5
lc7b069.reference lc7b069 reference Cy3
lc7b069.CLL-52    lc7b069    CLL-52 Cy5
lc7b070.reference lc7b070 reference Cy3
lc7b070.CLL-39    lc7b070    CLL-39 Cy5
lc7b019.reference lc7b019 reference Cy3
lc7b019.DLCL-0032 lc7b019 DLCL-0032 Cy5
lc7b056.reference lc7b056 reference Cy3
lc7b056.DLCL-0024 lc7b056 DLCL-0024 Cy5
lc7b057.reference lc7b057 reference Cy3
lc7b057.DLCL-0029 lc7b057 DLCL-0029 Cy5
lc7b058.reference lc7b058 reference Cy3
lc7b058.DLCL-0023 lc7b058 DLCL-0023 Cy5
