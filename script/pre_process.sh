#!/bin/bash -e
actual_package_name=$(awk -F'/' 'tolower($0) ~ /^# source repo.*github.com/{sub(/\.git/, "", $NF); print $NF}' $HOME/build/$TRAVIS_REPO_SLUG/$PKG_DIR_PATH$BUILD_SCRIPT)

cd $actual_package_name

IFS=',' read -ra langs <<< "$Languages"
 
for language in "${langs[@]}"; do
    if [ "$language" == "python" ]; then
        touch final-requirements
	find ./ -type f -name '*requirements*.txt' -exec cat {} + >> final-requirements
	mv final-requirements requirements.txt
    elif [ "$language" == "javascript" ] || [ "$language" == "typescript" ]; then
    	nvm_path='/home/travis/.nvm/nvm.sh'
        if [ -f "package-lock.json" ] || [ -f "yarn.lock" ]; then
	    sudo chown travis:travis -R .
	    echo '
     	    if [ -f ${nvm_path} ]; then
	  	source ${nvm_path}
    	    else
	    	curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash
            	source ~/.bashrc
            	nvm install 16
	    fi
	    npm install -g yarn
            yarn import || true
	    ' > generate.sh
	    chmod +x generate.sh
            sudo ./generate.sh
            sudo rm -rf node_modules/ package-lock.json
        fi
    fi
done

