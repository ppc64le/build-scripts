FROM openjdk:8

MAINTAINER "Lysanne Fernandes <lysannef@us.ibm.com>"

ENV PATH=$PATH:$JAVA_HOME/bin
ENV CLASSPATH=/CoreNLP/lib/*:/CoreNLP/liblocal/*:/CoreNLP/stanford-corenlp-models-current.jar:/CoreNLP/stanford-corenlp.jar

RUN apt-get update -y && \
    apt-get install -y build-essential git g++ ant wget && \
    git clone https://github.com/stanfordnlp/CoreNLP.git && \
    cd CoreNLP && ant && cd classes && \
    jar -cf ../stanford-corenlp.jar edu && \
    wget http://nlp.stanford.edu/software/stanford-corenlp-models-current.jar && \
    wget http://nlp.stanford.edu/software/stanford-english-corenlp-models-current.jar && \
    mv stanford-*.jar ../lib && \
    echo "the quick brown fox jumped over the lazy dog" > input.txt && \
    java -mx5g edu.stanford.nlp.pipeline.StanfordCoreNLP -outputFormat json -file input.txt && \
    apt-get purge -y build-essential git g++ ant wget && \
    rm -f lib/stanford-corenlp-models-current.jar && \
    rm -f lib/stanford-english-corenlp-models-current.jar && \
    apt-get autoremove -y

WORKDIR CoreNLP
CMD ["/bin/bash"]
