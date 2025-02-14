#!/bin/bash -xe
cloned_package=$(ls -td -- */ | head -n 1)
cd $cloned_package

IFS=',' read -ra langs <<< "$Languages"
 
for language in "${langs[@]}"; do
    if [ "$language" == "python" ]; then
    	echo "executing python code in pre-process"
        touch final-requirements
	find ./ -type f -name '*requirements*.txt' -exec cat {} + >> final-requirements
	mv final-requirements requirements.txt
 	ls -ltr
    elif [ "$language" == "javascript" ] || [ "$language" == "typescript" ]; then
    	echo "executing javascript code in pre-process"
    	nvm_path='/home/travis/.nvm/nvm.sh'
        if [ -f "package-lock.json" ] || [ -f "yarn.lock" ]; then
	    sudo chown travis:travis -R .
     	    if [ -f ${nvm_path} ]; then
	  	source ${nvm_path}
    	    else
	    	curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash
            	source ~/.bashrc       
	    fi
            nvm install 16
       	    nvm use 16
	    node --version
	    npm install -g yarn
            yarn import || true
            rm -rf node_modules/ package-lock.json
	    ls -ltr
        fi
    fi
done

