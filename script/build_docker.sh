 #!/bin/bash -e

version="$VERSION"
package_dirpath="$PKG_DIR_PATH"
config_file="build_info.json"
image_name=$IMAGE_NAME
build_docker=$BUILD_DOCKER

CUR_DIR=$(pwd)
cd $package_dirpath

# Using python script to find matched version string/key in build_info.json for version passed 
match_version=$(python $CUR_DIR/script/match_version_buildinfo.py)

if [ $build_docker != false ];then
    if [[ $(jq --arg ver "$match_version" '.[$ver]' $config_file) != null ]]; then
        docker_builddir=$(jq -r --arg ver "$match_version" '.[$ver].dir' $config_file)
        args=$(jq -r --arg ver "$match_version" '.[$ver].args' $config_file)
        patches=$(jq -r --arg ver "$match_version" '.[$ver].patches' $config_file)
        # By default send PACKAGE_VERSION argument.
        build_args ="--build-arg PACKAGE_VERSION=$version"
        if [ $args != null ]; then
            for row in $(echo "$args" | jq -r 'to_entries[] | @base64'); do
            key=$(echo "$row" | base64 -d | jq -r '.key')
            value=$(echo "$row" | base64 -d | jq -r '.value')
            build_args=$(echo $build_args --build-arg $key=$value )
            done
        fi
        if [ $patches != null ]; then
            for row in $(echo "$patches" | jq -r 'to_entries[] | @base64'); do
            key=$(echo "$row" | base64 -d | jq -r '.key')
            value=$(echo "$row" | base64 -d | jq -r '.value')
            build_args=$(echo $build_args --build-arg $key=$value )
            done
        fi
        if [[ $(jq --arg ver "$match_version" '.[$ver]' $config_file) != null ]] && 
            [[ $(jq -r --arg ver "$match_version" '.[$ver].base_docker_image' $config_file) != null ]]; then
            basename=$(jq -r --arg ver "$match_version" '.[$ver].base_docker_image' $config_file)
        fi
        cmd="$build_args -t $image_name $docker_builddir"
        #final_upload_image_link=$(DOCKER_UPLOAD_LINK)/$image_name
        docker_file_path="${package_dirpath}/Dockerfiles"
    fi

    cd Dockerfiles
    #echo "Deleting existing docker image"
    #docker rmi -f ${image_name}
    #docker rmi -f ${basename}
    echo "Building docker image"
    echo "sudo docker build $build_args -t $image_name $docker_builddir"
    echo "*************************************************************************************"
    sudo docker build $build_args -t $image_name $docker_builddir
    docker save -o "$HOME/build/$TRAVIS_REPO_SLUG/image.tar" $image_name
else
    echo "Docker image is not supported"
fi

# # Publish code keeping commented for now
# if [ $? == 0 ]
#   then
#     sudo docker tag ${image_name} ${docker_upload_link}/${image_name}
#     sudo docker login -u ${env.dockerHubUser} -p ${env.dockerHubPassword} ${docker_upload_link}
#     sudo docker push ${docker_upload_link}/${image_name}
# fi
