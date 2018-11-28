Files for using the [Docker](http://www.docker.com) container system.
Please see [Docker instructions](https://github.com/tensorflow/serving/blob/master/tensorflow_serving/g3doc/docker.md)
for more info.

Building a ppc64le container from a Dockerfile:

1.  Clone this repo

    ```shell
    git clone https://github.com/ppc64le/build-scripts/
    cd build-scripts
    ```

2.  Build the development image

    *   For CPU:

        ```shell
        docker build --pull -t $USER/tensorflow-serving-devel \
          -f tensorflow-serving/Dockerfiles/Dockerfile.devel .
        ```

    *   For GPU: `

        ```shell
        docker build --pull -t $USER/tensorflow-serving-devel-gpu \
          -f tensorflow-serving/Dockerfiles/Dockerfile.devel-gpu .
        ```

3.  Build the serving image with the development image as a base

    *   For CPU:

        ```shell
        docker build -t $USER/tensorflow-serving \
          --build-arg TF_SERVING_BUILD_IMAGE=$USER/tensorflow-serving-devel \
          -f tensorflow-serving/Dockerfiles/Dockerfile .
        ```

        Your new Docker image is now `$USER/tensorflow-serving`, which you can
        [use](https://github.com/tensorflow/serving/blob/master/tensorflow_serving/g3doc/docker.md##running-a-serving-image)
        just as you would the standard `tensorflow/serving:latest` image.
        `tensorflow/serving:latest` image.

    *   For GPU:

        ```shell
        docker build -t $USER/tensorflow-serving-gpu \
          --build-arg TF_SERVING_BUILD_IMAGE=$USER/tensorflow-serving-devel-gpu \
          -f tensorflow-serving/Dockerfiles/Dockerfile.gpu .
        ```

        Your new Docker image is now `$USER/tensorflow-serving-gpu`, which you can
        [use](https://github.com/tensorflow/serving/blob/master/tensorflow_serving/g3doc/docker.md##running-a-gpu-serving-image)
        just as you would the standard `tensorflow/serving:latest-gpu` image.
