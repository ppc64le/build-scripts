**Purpose of the document**

   The document helps to explain how to use script with syntax, features of the script and constraints to build all the module in default mvn build install in a single run.

**Details and features**

   The script flowable-engine-all-modules-generic/flowable-engine_module_ubuntu_18.04.sh helps to build, Test and generate jar files for the modules under flowable-engine for the following package.
   
   https://github.com/flowable/flowable-engine/tree/master/modules

 parent level mvn install has certain constraint to build all modules in a single stretch as below
         The issue with building all modules at the same time is ,The process should build around 125 modules(mvn install by default from parent) under this package.It takes   more than 3.5 hrs and failing with javaswap page full/ java.lang.OutOfMemoryError: GC overhead limit exceeded/memory issues.

The script contains the following features 

    1. Passing Arguments: 
          1.Version of package 2.JDK version (openjdk-8-jdk or openjdk-11-jdk) 3.Module list to be build(single module OR list of modules listed with space in quotes).   
    2. Module argument is mandatory.
    3. Different tags(different version of  packages) can be passed as an argument to build and test.
    4. Different supported jdk can be passed to build for the different java environments.
    5. Single module can be passed and build.
    6. Multiple modules can be passed to build at the same time using space separated.


**Usage**

  1. Module name is must
  
    Syntax:-  
          sh flowable-engine_module_ubuntu_18.04.sh                                                       
          
      logs:- 
        Enter the module name to be build or List of modules to be build
        eg :-
        flowable-engine_module_ubuntu_18.04.sh '' '' 'flowable-ui-app'
        or
        flowable-engine_module_ubuntu_18.04.sh '' '' 'flowable-batch-service flowable-batch-service-api flowable-bpmn-converter .....'
        

  2.Unavailble JDK
  
     Syntax:-  
          sh flowable-engine_module_ubuntu_18.04.sh flowable-6.5.0 openjdk-16-jdk flowable-batch-service
      
      logs:-

        E: Unable to locate package openjdk-16-jdk
        Failed to install JDK openjdk-16-jdk

  3 Unavailable tag
     
      Syntax:- 
            sh flowable-engine_module_ubuntu_18.04.sh flowable-5.5.0 openjdk-11-jdk flowable-form-api
      logs:-

        error: pathspec 'flowable-5.5.0' did not match any file(s) known to git.
        flowable-5.5.0 not found.

  4 Unavailable module
      
      Syntax:- 
            sh flowable-engine_module_ubuntu_18.04.sh '' openjdk-8-jdk flowab
      logs:-
      
        HEAD is now at ed4261edeb Move to version 6.6.0
        flowable-6.6.0 found to checkout
        flowable-engine_module_ubuntu_18.04.sh: 96: cd: can't cd to flowab
        flowab module not found in the package ...

  5. Default tag and jdk8 with module
         
         Syntax:- 
            sh flowable-engine_module_ubuntu_18.04.sh '' '' flowable-task-service

  6. Default tag , jdk11 and module
      
         Syntax:- 
            sh flowable-engine_module_ubuntu_18.04.sh '' openjdk-11-jdk flowable-ldap


  7. Specific tag flowable-6.5.0,jdk11 and module
      
         Syntax:- 
            sh flowable-engine_module_ubuntu_18.04.sh flowable-6.5.0 openjdk-11-jdk flowable-form-api

  8. Specific tag jdk8 and list of modules
      
         Syntax:- 
            sh flowable-engine_module_ubuntu_18.04.sh flowable-6.5.0 openjdk-8-jdk "flowable-bpmn-converter flowable-bpmn-model"

  9  Run for all modules specified in the list with different verion of jdk and version of tag(package version)
      
      Syntax:- 
          sh flowable-engine_module_ubuntu_18.04.sh '' '' "flowable-batch-service flowable-batch-service-api flowable-bpmn-converter flowable-bpmn-model flowable-cmmn-engine flowable-cmmn-model flowable-common-rest flowable-content-api flowable-dmn-api flowable-dmn-engine flowable-engine-common flowable-engine-common-api flowable-entitylink-service flowable-entitylink-service-api flowable-event-registry flowable-event-registry-api flowable-event-registry-configurator flowable-event-registry-json-converter flowable-event-registry-model flowable-event-registry-spring flowable-event-registry-spring-configurator flowable-eventsubscription-service flowable-eventsubscription-service-api flowable-form-api flowable-form-model flowable-identitylink-service flowable-identitylink-service-api flowable-idm-api flowable-idm-engine flowable-idm-engine-configurator flowable-image-generator flowable-job-service flowable-job-service-api flowable-job-spring-service flowable-process-validation flowable-rest flowable-spring flowable-spring-boot flowable-spring-boot flowable-spring-common flowable-spring-security flowable-task-service flowable-task-service-api flowable-variable-service"
      
      Syntax:- 
          sh flowable-engine_module_ubuntu_18.04.sh 'flowable-6.6.0' 'openjdk-8-jdk' "flowable-batch-service flowable-batch-service-api flowable-bpmn-converter flowable-bpmn-model flowable-cmmn-engine flowable-cmmn-model flowable-common-rest flowable-content-api flowable-dmn-api flowable-dmn-engine flowable-engine-common flowable-engine-common-api flowable-entitylink-service flowable-entitylink-service-api flowable-event-registry flowable-event-registry-api flowable-event-registry-configurator flowable-event-registry-json-converter flowable-event-registry-model flowable-event-registry-spring flowable-event-registry-spring-configurator flowable-eventsubscription-service flowable-eventsubscription-service-api flowable-form-api flowable-form-model flowable-identitylink-service flowable-identitylink-service-api flowable-idm-api flowable-idm-engine flowable-idm-engine-configurator flowable-image-generator flowable-job-service flowable-job-service-api flowable-job-spring-service flowable-process-validation flowable-rest flowable-spring flowable-spring-boot flowable-spring-boot flowable-spring-common flowable-spring-security flowable-task-service flowable-task-service-api flowable-variable-service"
      
      Syntax:- 
          sh flowable-engine_module_ubuntu_18.04.sh 'flowable-5.5.0' 'openjdk-11-jdk' "flowable-batch-service flowable-batch-service-api flowable-bpmn-converter flowable-bpmn-model flowable-cmmn-engine flowable-cmmn-model flowable-common-rest flowable-content-api flowable-dmn-api flowable-dmn-engine flowable-engine-common flowable-engine-common-api flowable-entitylink-service flowable-entitylink-service-api flowable-event-registry flowable-event-registry-api flowable-event-registry-configurator flowable-event-registry-json-converter flowable-event-registry-model flowable-event-registry-spring flowable-event-registry-spring-configurator flowable-eventsubscription-service flowable-eventsubscription-service-api flowable-form-api flowable-form-model flowable-identitylink-service flowable-identitylink-service-api flowable-idm-api flowable-idm-engine flowable-idm-engine-configurator flowable-image-generator flowable-job-service flowable-job-service-api flowable-job-spring-service flowable-process-validation flowable-rest flowable-spring flowable-spring-boot flowable-spring-boot flowable-spring-common flowable-spring-security flowable-task-service flowable-task-service-api flowable-variable-service"
