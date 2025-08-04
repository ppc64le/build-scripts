 #!/bin/bash -e

version="$VERSION"
package_dirpath="$PKG_DIR_PATH"
config_file="build_info.json"
image_name=$IMAGE_NAME
build_docker=$BUILD_DOCKER

CUR_DIR=$(pwd)
cd $package_dirpath

# Using python script to find matched version string/key in build_info.json for version passed 
match_version=$(python $CUR_DIR/gha-script/match_version_buildinfo.py)

if [ $build_docker != false ];then
    if [[ $(jq --arg ver "$match_version" '.[$ver]' $config_file) != null ]]; then
        docker_builddir=$(jq -r --arg ver "$match_version" '.[$ver].dir' $config_file)
        args=$(jq -r --arg ver "$match_version" '.[$ver].args' $config_file)
        patches=$(jq -r --arg ver "$match_version" '.[$ver].patches' $config_file)
        # By default send PACKAGE_VERSION argument.
        build_args="--build-arg PACKAGE_VERSION=$version"
        if [ $args != "null" ]; then
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
    # sudo docker build $build_args -t $image_name $docker_builddir > docker_build.log 2>&1 &
    # SCRIPT_PID=$!
    # while ps -p $SCRIPT_PID > /dev/null
    # do 
    #   echo "$SCRIPT_PID is running"
    #   sleep 100
    # done
    # wait $SCRIPT_PID
    # my_pid_status=$?

    sudo docker build $build_args -t $image_name $docker_builddir 2>&1 | tee docker_build.log
    my_pid_status=${PIPESTATUS[0]}
    docker_build_size=$(stat -c %s docker_build.log)
    
    if [ $my_pid_status != 0 ];
    then
        if [ $docker_build_size -lt 1800000 ];
        then
           cat docker_build.log
        else
           tail -300 docker_build.log
        fi
        exit 1
    else
        if [ $docker_build_size -lt 1800000 ];
        then
           cat docker_build.log
        else
           tail -300 docker_build.log
        fi    
    fi
    docker save -o image.tar $image_name
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
