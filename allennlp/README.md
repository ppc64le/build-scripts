#To run the script use

$ bash allennlp_v0.8.4_ubuntu_18.04.sh

#The awscli_spacy.patch does the following

- use a pre-built version of spacy available at https://public.dhe.ibm.com/ibmdl/export/pub/software/server/ibm-ai/conda/linux-ppc64le

- bypass dependency on awscli as it is only for remote docker commands and the dependency has been removed from the master branch

- fixes two automated test case failures as per suggestions from the community and backportin commit #ec30c9021bdbf85099b3556e5a5d270124c494c8


