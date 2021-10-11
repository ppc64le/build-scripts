# ----------------------------------------------------------------------------
# Package          : flowable-engine
# Version          : 6.6.0
# Source repo      : https://github.com/flowable/flowable-engine
# Tested on        : ubuntu_18.04
# Passing Arguments: 1.Version of package, 2.JDK version (openjdk-8-jdk or openjdk-11-jdk)
#                    3.Module list to be build(single module OR list of modules listed with space in quotes)
# Modlues covered  : flowable-batch-service,flowable-batch-service-api,flowable-bpmn-converter, flowable-bpmn-model,flowable-cmmn-engine,flowable-cmmn-model,flowable-common-rest,flowable-content-api,flowable-dmn-api,flowable-dmn-engineflowable-engine-common,flowable-engine-common-api,flowable-entitylink-service,flowable-entitylink-service-api,flowable-event-registry,flowable-event-registry-api,flowable-event-registry-configurator,flowable-event-registry-json-converter,flowable-event-registry-model,flowable-event-registry-spring,flowable-event-registry-spring-configurator,flowable-eventsubscription-service,flowable-eventsubscription-service-api,flowable-form-api,flowable-form-model,flowable-identitylink-service,flowable-identitylink-service-api,flowable-idm-api,flowable-idm-engine,flowable-idm-engine-configurator,flowable-image-generator,flowable-job-service,flowable-job-service-api,flowable-job-spring-service,flowable-process-validation,flowable-rest,flowable-spring,flowable-spring-boot,flowable-spring-boot,flowable-spring-common,flowable-spring-security,flowable-task-service,flowable-task-service-api,flowable-variable-service
# or any list of modules under package  https://github.com/flowable/flowable-engine
# Script License   : Apache License, Version 2 or later
# Maintainer       : Arumugam N S <asellappen@yahoo.com> / Priya Seth<sethp@us.ibm.com>
#
# Disclaimer       : This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash


export REPO=https://github.com/flowable/flowable-engine

#Default tag flowable-6.6.0
if [ -z "$1" ]; then
  export VERSION="flowable-6.6.0"
else
  export VERSION="$1"
fi

#Default testing on jdk8
if [ -z "$2" ]; then
  export JDK="openjdk-8-jdk"
else
  export JDK="$2"
fi

#Module options need to be passed,otherwise Raise exception
if [ -z "$3" ]; then
 echo "Enter the module name to be build or List of modules to be build\n
 eg :-
      flowable-engine_module_ubuntu_18.04.sh '' '' 'flowable-ui-app'
      or
      flowable-engine_module_ubuntu_18.04.sh '' '' 'flowable-batch-service flowable-batch-service-api flowable-bpmn-converter .....' "
  exit
else
  export MODULElIST="$3"
fi

#Default installation
sudo apt-get update
sudo apt-get install -y apt-utils
sudo apt-get install  git -y

#Fro rerunning build
if [ -d "flowable-engine" ] ; then
  rm -rf flowable-engine
fi

# run tests with java 11 or jdk 8
sudo apt-get install -y ${JDK}
jret=$?
if [ $jret -eq 0 ] ; then
  echo "Sucessfully installed JDK  ${JDK} "
else
  echo "Failed to install JDK  ${JDK} "
  exit
fi

#Setting JAVA_HOME
export folder=`echo ${JDK}  | grep -oP '(?<=openjdk-).*(?=-jdk)'`
export JAVA_HOME=/usr/lib/jvm/java-${folder}-openjdk-ppc64el/


sudo apt install  -y maven

mvn -v


git clone ${REPO}
cd flowable-engine
git checkout ${VERSION}
ret=$?
if [ $ret -eq 0 ] ; then
  echo  "${VERSION} found to checkout"
else
  echo  "${VERSION} not found"
  exit
fi
#goto module path
cd modules
for MODULE in ${MODULElIST};
do
 # Check module path
    cd ${MODULE}
    ret=$?
    if [ $ret -eq 0 ] ; then
      echo  "${MODULE} module found in the package to build and started building ..."
    else
      echo  "${MODULE} module not found in the package ..."
      continue
    fi
    #Build and test flowable module
    pwd
    sudo mvn clean install -DskipTests=true -B -V
    ret=$?
    if [ $ret -eq 0 ] ; then
      echo  "Done build for ${MODULE}......"
    else
      echo  "Failed build for ${MODULE}......"
      cd ..
      continue
    fi
    mvn test -B
    ret=$?
    if [ $ret -eq 0 ] ; then
      echo  "Done Test for ${MODULE}......"
    else
      echo  "Failed Test for ${MODULE}......"
    fi
    #back to module path
    cd ..
done
echo "Completed build for all modules ................\n "
