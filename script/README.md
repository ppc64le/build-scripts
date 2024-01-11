# Build Script Automation

Build script automation is a process which creates build_script and build_info.json for packages with minimal human intervention. 
The process creates,executes the build_script ,validates it and eventually creates a pull request for the same on users approval.

# Pre-requisites

+ Create a fork of the build-scripts repo,update it if already present.
+ Have the following details of package to be ported:
  * Package name
  * Package version
  * Package URL
  * Package language 
+ Create a python environment and activate it. Refer gfg url to create an environment.
 

# Steps to execute

1. Traverse to the base level of the ppc64le repo.
2. Activate the previously created python environment.
3. Run the following command to run the automation:
     python3 script/node_bs.py <package_version> <package_language>
4. The process expects the name of the package to be built from user. Enter the package name.
5. Respond to any prompts from the system and monitor the logs for success/failure.
6. Push the code and create a pull request in case of success.

