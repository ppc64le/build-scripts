FROM ppc64le/r-base
MAINTAINER "Jay Joshi <joshija@us.ibm.com>"

RUN apt-get update \
        && apt-get install git texlive-latex-extra -y \
	&& git clone https://github.com/cran/clusterGenomics.git \
	&& cd clusterGenomics && git checkout 1.0 \
        && R -e 'source("https://bioconductor.org/biocLite.R") ; biocLite("clusterGenomics",dependencies= TRUE)' \
	&& R CMD check clusterGenomics \
	&& cd .. && rm -rf clusterGenomics \
	&& apt-get purge --auto-remove git texlive-latex-extra -y

CMD ["/bin/bash"]
