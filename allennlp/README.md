***Prerequisite***

Before you run the script make sure that the patch file 

https://github.com/ppc64le/build-scripts/blob/master/allennlp/awscli_spacy_testfix.patch 

has been downloaded and is available in the same directory as the build script.



***Running the script***

**On Ubuntu 18.04**

$ bash allennlp_v0.8.4_ubuntu_18.04.sh 


**On RHEL 7.6**

$ bash allennlp_v0.8.4_rhel_7.6.sh 


**Note**

The awscli_spacy.patch does the following

- use a pre-built version of spacy available at https://public.dhe.ibm.com/ibmdl/export/pub/software/server/ibm-ai/conda/linux-ppc64le

- bypass dependency on awscli as it is only for remote docker commands and the dependency has been removed from the master branch

- fixes two automated test case failures as per suggestions from the community by backporting commit #ec30c9021bdbf85099b3556e5a5d270124c494c8


