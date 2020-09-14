FROM ppc64le/r-base 
MAINTAINER "Jay Joshi <joshija@us.ibm.com>"

RUN apt-get update \
        && apt-get install git texlive-latex-extra -y \
	&& git clone https://github.com/cran/acepack.git \
	&& cd acepack && git checkout 1.3-3.2 \
        && R -e 'install.packages("acepack",dependencies= TRUE,repos="http://cran.rstudio.com/")' \
	&& R CMD check acepack \
	&& cd .. && rm -rf acepack \
	&& apt-get purge --auto-remove git texlive-latex-extra -y

CMD ["/bin/bash"]
