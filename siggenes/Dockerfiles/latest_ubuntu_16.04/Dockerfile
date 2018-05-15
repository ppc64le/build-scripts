FROM ppc64le/r-base
MAINTAINER "Yugandha deshpande <yugandha@us.ibm.com>"

RUN apt-get update \
	&& R -e 'source("https://bioconductor.org/biocLite.R"); biocLite("siggenes")' \
	&& R CMD check siggenes

CMD ["/bin/bash"]
