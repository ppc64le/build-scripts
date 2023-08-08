semver (Python module)

Build and run the container:

$docker build -t semver . $docker run --name demo_semver -i -t semver /bin/bash

Test the working of Container: Now inside the container type python and enter the shell. Now run the following examples line by line to test each output:

To import this library, use:

>>> import semver

To compare two versions, semver provides the semver.compare function. The return value indicates the relationship between the first and second version:

>>> semver.compare("1.0.0", "2.0.0")
-1
>>> semver.compare("2.0.0", "1.0.0")
1
>>> semver.compare("2.0.0", "2.0.0")
0
