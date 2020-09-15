FROM ppc64le/r-base
MAINTAINER "Jay Joshi <joshija@us.ibm.com>"

RUN apt-get update \
      && apt-get install git -y \
	&& git clone https://github.com/r-spatial/r-spatial.org.git \
	&& cd r-spatial.org \
      && R -e 'install.packages("r-spatial.org",dependencies= TRUE,repos="http://cran.rstudio.com/")' \
	&& R CMD check r-spatial.org --no-manual \
	&& cd .. && rm -rf s-spatial.org \
	&& apt-get purge --auto-remove git -y

CMD ["/bin/bash"]
