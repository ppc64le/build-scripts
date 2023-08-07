 #!/bin/bash -xe

version="$VERSION"
packageDirPath="$PKG_DIR_PATH"
configFile="build_info.json"
imageName=$IMAGE_NAME
buildDocker=$BUILD_DOCKER


cd $packageDirPath

if [ $buildDocker != false ];then
    if [[ $(jq --arg ver $version '.[$ver]' $configFile) != null ]]; then
        dockerBuildDir=$(jq -r --arg ver $version '.[$ver].dir' $configFile)
        args=$(jq -r --arg ver $version '.[$ver].args' $configFile)
        patches=$(jq -r --arg ver $version '.[$ver].patches' $configFile)
        # By default send PACKAGE_VERSION argument.
        buildArgs ="--build-arg PACKAGE_VERSION=$(VERSION)"
        if [ $args != null ]; then
            for row in $(echo "$args" | jq -r 'to_entries[] | @base64'); do
            key=$(echo "$row" | base64 -d | jq -r '.key')
            value=$(echo "$row" | base64 -d | jq -r '.value')
            buildArgs=$(echo $buildArgs --build-arg $key=$value )
            done
        fi
        if [ $patches != null ]; then
            for row in $(echo "$patches" | jq -r 'to_entries[] | @base64'); do
            key=$(echo "$row" | base64 -d | jq -r '.key')
            value=$(echo "$row" | base64 -d | jq -r '.value')
            buildArgs=$(echo $buildArgs --build-arg $key=$value )
            done
        fi
        if [[ $(jq --arg ver $version '.[$ver]' $configFile) != null ]] && 
            [[ $(jq -r --arg ver $version '.[$ver].base_docker_image' $configFile) != null ]]; then
            baseName=$(jq -r --arg ver $version '.[$ver].base_docker_image' $configFile)
        fi
        cmd="$buildArgs -t $imageName $dockerBuildDir"
        final_upload_image_link=$(DOCKER_UPLOAD_LINK)/$imageName
        docker_file_path="${packageDirPath}/Dockerfiles"
    fi

    cd Dockerfiles
    echo "Deleting existing docker image"
    docker rmi -f ${imageName}
    #docker rmi -f ${baseName}
    echo "Building docker image"
    sudo docker build $buildArgs -t $imageName $dockerBuildDir
    docker save -o "$HOME/build/$TRAVIS_REPO_SLUG/image.tar" $IMAGE_NAME
else
    echo "Docker image is not supported"
fi

# # Publish code keeping commented for now
# if [ $? == 0 ]
#   then
#     sudo docker tag ${imageName} ${docker_upload_link}/${imageName}
#     sudo docker login -u ${env.dockerHubUser} -p ${env.dockerHubPassword} ${docker_upload_link}
#     sudo docker push ${docker_upload_link}/${imageName}
# fi
