FROM ppc64le/r-base
MAINTAINER "Yugandha deshpande <yugandha@us.ibm.com>"

RUN apt-get update \
	&& R -e 'source("https://bioconductor.org/biocLite.R"); biocLite("hgu95av2cdf")' \
	&& R CMD check hgu95av2cdf

CMD ["/bin/bash"]
