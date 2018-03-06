# ----------------------------------------------------------------------------
#
# Package	: mirdeep2
# Version	: 2.0.0.8
# Source repo	: https://github.com/rajewsky-lab/mirdeep2
# Tested on	: ubuntu_16.04
# Script License: Apache License, Version 2 or later
# Maintainer	: Atul Sowani <sowania@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

sudo apt-get update -y
sudo apt-get install -y wget curl unzip python perl build-essential \
    libwww-perl libfont-ttf-perl libpdf-api2-perl
export PERL_MM_USE_DEFAULT=1

# Source zip is not available any more, need to check out from git.
#wget https://www.mdc-berlin.de/45995549/en/research/research_teams/systems_biology_of_gene_regulatory_elements/projects/miRDeep/mirdeep2_0_0_8.zip
#unzip mirdeep2_0_0_8.zip
#cd mirdeep2_0_0_8

git clone https://github.com/rajewsky-lab/mirdeep2
cd mirdeep2

# Changes required to build mirdeep2 on ppc64le.
sed -i -e "s/if(not -d 'bin'){/\$dtool ='wget';\nif(not -d 'bin'){/" install.pl
#sed -i -e 's/\$err=system("\$dtool http:\/\/netcologne.dl.sourceforge.net\/project\/bowtie-bio\/bowtie\/\$bowtie_version\/\$bowtie \$dopt");/\$err=system("\$dtool http:\/\/netcologne.dl.sourceforge.net\/project\/bowtie-bio\/bowtie\/\$bowtie_version\/\$bowtie \$dopt \$bowtie");/' install.pl
#sed -i -e 's/\$err=system("\$dtool http:\/\/netcologne.dl.sourceforge.net\/project\/bowtie-bio\/bowtie\/old\/\$bowtie_version\/\$bowtie \$dopt");/\$err=system("$dtool http:\/\/netcologne.dl.sourceforge.net\/project\/bowtie-bio\/bowtie\/old\/\$bowtie_version\/\$bowtie \$dopt \$bowtie");/' install.pl
sed -i -e 's/\$err=system("\$dtool http:\/\/www.tbi.univie.ac.at\/RNA\/packages\/source\/ViennaRNA-1.8.4.tar.gz \$dopt");/\$err=system("\$dtool http:\/\/www.tbi.univie.ac.at\/RNA\/packages\/source\/ViennaRNA-1.8.4.tar.gz \$dopt \$dfile");/' install.pl
sed -i -e 's/`.\/configure --prefix=\$dir\/essentials\/ViennaRNA-1.8.4\/install_dir`;/`.\/configure --prefix=\$dir\/essentials\/ViennaRNA-1.8.4\/install_dir --build=ppc64le`;/' install.pl
sed -i -e "s/\`\$dtool http:\/\/eddylab.org\/software\/squid\/squid.tar.gz \$dopt\`;/\`\$dtool http:\/\/eddylab.org\/software\/squid\/squid.tar.gz \$dopt \$dfile\`;/" install.pl
sed -i -e "s/\`\$dtool http:\/\/bioinformatics.psb.ugent.be\/supplementary_data\/erbon\/nov2003\/downloads\/randfold-2.0.tar.gz \$dopt\`;/\`\$dtool http:\/\/bioinformatics.psb.ugent.be\/supplementary_data\/erbon\/nov2003\/downloads\/randfold-2.0.tar.gz \$dopt \$dfile\`;/" install.pl

./install.pl
source $HOME/.bash_profile
perl ./install.pl
