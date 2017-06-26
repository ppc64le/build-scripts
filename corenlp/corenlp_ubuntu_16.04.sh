# ----------------------------------------------------------------------------
#
# Package	: CoreNLP
# Version	: n/a
# Source repo	: https://github.com/stanfordnlp/CoreNLP.git
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

# Install dependencies.
sudo apt-get update -y
sudo apt-get install -y build-essential git g++ ant wget \
    software-properties-common openjdk-8-jdk openjdk-8-jre

export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-ppc64el
export PATH=$PATH:$JAVA_HOME/bin

# Clone and build source code.
git clone https://github.com/stanfordnlp/CoreNLP.git
cd CoreNLP
ant
cd classes
jar -cf ../stanford-corenlp.jar edu
cd ..

# Perform tests.
wget http://nlp.stanford.edu/software/stanford-corenlp-models-current.jar
wget http://nlp.stanford.edu/software/stanford-english-corenlp-models-current.jar
wget http://nlp.stanford.edu/software/stanford-spanish-corenlp-models-current.jar
cp stanford-*.jar lib
ant test
