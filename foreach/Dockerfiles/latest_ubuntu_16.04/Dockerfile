FROM ppc64le/r-base
MAINTAINER "Jay Joshi <joshija@us.ibm.com>"

ENV _R_CHECK_FORCE_SUGGESTS_ false
RUN apt-get update \
	&& apt-get install texlive texinfo  git -y \
	&& git clone https://github.com/cran/foreach.git \
	&& cd foreach && git checkout 1.4.4 \
	&& R -e 'install.packages("iterators",dependencies= TRUE,repos="http://cran.rstudio.com/")' \
	&& R -e 'install.packages("randomForest",dependencies= TRUE,repos="http://cran.rstudio.com/")' \
	&& cd .. \
	&& R CMD build foreach \
	&& R CMD INSTALL foreach \
	&& R CMD check foreach --no-manual \
	&& apt-get purge --auto-remove git -y

CMD ["/bin/bash"]
