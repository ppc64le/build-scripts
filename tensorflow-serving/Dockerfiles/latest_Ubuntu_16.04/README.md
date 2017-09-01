#Instructions for TF Serving package.

1) First create a docker image using following command :

	docker build -t tf-serving .


2) Run tf-serving image & create container :

	 docker run -it tf-serving /bin/bash

3) Binaries are placed in the bazel-bin directory, and can be run using a command like:
       

	cd <TF-Serving-source-repo> && bazel-bin/tensorflow_serving/model_servers/tensorflow_model_server

	See the basic tutorial(https://github.com/tensorflow/serving/blob/master/tensorflow_serving/g3doc/serving_basic.md) and advanced tutorial (https://github.com/tensorflow/serving/blob/master/tensorflow_serving/g3doc/serving_advanced.md) for more in-depth examples of running TensorFlow Serving.
