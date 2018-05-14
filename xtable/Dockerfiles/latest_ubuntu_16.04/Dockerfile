FROM ppc64le/r-base
MAINTAINER "Jay Joshi <joshija@us.ibm.com>"

RUN apt-get update \
        && apt-get install git -y \
	&& git clone https://github.com/cran/xtable.git\
	&& cd xtable && git checkout 1.8-2 \
        && R -e 'install.packages("knitr",dependencies= TRUE,repos="http://cran.rstudio.com/")' \
	&& R CMD check xtable --no-manual \
	&& cd .. && rm -rf xtable \
	&& apt-get purge --auto-remove git -y

CMD ["/bin/bash"]
