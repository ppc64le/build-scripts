FROM ppc64le/r-base
MAINTAINER "Priya Seth <sethp@us.ibm.com>"

RUN apt-get update \
        && R -e 'source("https://bioconductor.org/biocLite.R"); biocLite("org.Hs.eg.db")' \
        && R CMD check org.Hs.eg.db

CMD ["/bin/bash"]
