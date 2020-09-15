FROM ppc64le/r-base
MAINTAINER "Yugandha deshpande <yugandha@us.ibm.com>"

ENV _R_CHECK_FORCE_SUGGESTS_ false
RUN apt-get update \
	&& apt-get install git -y \
	&& R -e 'install.packages("RColorBrewer",dependencies= TRUE,repos="http://cran.rstudio.com/"); install.packages("maps",dependencies= TRUE,repos="http://cran.rstudio.com/")' \
	&& git clone https://github.com/cran/latticeExtra.git  \
	&& cd latticeExtra && git checkout 0.6-28 \
	&& cd .. \
	&& R CMD build latticeExtra \
	&& R CMD INSTALL latticeExtra \
	&& R CMD check latticeExtra --no-manual \
	&& apt-get purge --auto-remove git -y

CMD ["/bin/bash"]
