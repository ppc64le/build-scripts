FROM ppc64le/r-base
MAINTAINER "Yugandha deshpande <yugandha@us.ibm.com>"

RUN apt-get update \
        && R -e 'source("https://bioconductor.org/biocLite.R"); biocLite("hgu95av2.db")' \
        && R CMD check hgu95av2.db

CMD ["/bin/bash"]
