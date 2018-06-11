jforests (package)

Build and run the container:

$docker build -t jforests .
$docker run --name demo_jforests -i -t jforests /bin/bash

Test the working of Container:

Follow below given steps:

1. cp jforests/releases/jforests-0.5.jar jforests/jforests/src/main/resources
2. cd jforests/jforests/src/main/resources
3. unzip sample-ranking-data.zip
4. java -jar jforests.jar --cmd=generate-bin --ranking --folder . --file train.txt --file valid.txt --file test.txt

The last command will generate binary's for the three files train.txt, valid.txt and test.txt in the same folder.

Additional examples are available at: https://github.com/yasserg/jforests
