Docker build command : docker build -t corenlp .

Docker run command : docker run -t corenlp

NOTE:
When using corenlp, please download following models and language jars from
https://nlp.stanford.edu/software/ and copy them to the CoreNLP/lib folder.
for e.g.:
  wget http://nlp.stanford.edu/software/stanford-corenlp-models-current.jar
  wget http://nlp.stanford.edu/software/stanford-english-corenlp-models-current.jar or 
  wget http://nlp.stanford.edu/software/stanford-spanish-corenlp-models-current.jar
  cp stanford-*.jar lib
