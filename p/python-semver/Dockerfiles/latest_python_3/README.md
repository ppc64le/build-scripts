semver (Python module)

Build and run the container:

$docker build -t semver .
$docker run --name demo_semver -i -t semver /bin/bash

Test the working of Container:
        Now inside the container type python and enter the shell.
	Now run the following examples line by line to test each output:

>>> import semver
>>> semver.compare("1.0.0", "2.0.0")
-1
>>> semver.compare("2.0.0", "1.0.0")
1
>>> semver.compare("2.0.0", "2.0.0")
0
