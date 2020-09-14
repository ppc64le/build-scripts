FROM ppc64le/r-base
MAINTAINER "Vibhuti Sawant <Vibhuti.Sawant@ibm.com>"

RUN apt-get update \
	&& R -e 'source("https://bioconductor.org/biocLite.R"); biocLite("AnnotationDbi")' \
	&& R CMD check AnnotationDbi

CMD ["/bin/bash"]
