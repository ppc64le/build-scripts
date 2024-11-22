How to run drupal related modules test cases (Unit/Functional/Intergration).
-------------

Summary :-

    To run test cases in drupal module we need build drupal core package and drupal complete framework which include one database,apache server,and drupal core package.
    There are 3 type of tests in drupal unit,functional,intergration. For unit test we dont need drupal full framework like database.
    Unit test does not use database testing as i tested some packages.

*************************

Copy following files From local into VM thats needed to run docker file succesfully.

    1) automate_drupal.sh.txt
    2) Dockerfile.drupal.ubi
    3) drupal.zip
    4) drupal_schema.sql

Rename 2 below files:-

    #cp Dockerfile.drupal.ubi Dockerfile
    #cp automate_drupal.sh.txt automate_drupal.sh
    #chmod +x automate_drupal.sh


Now we can create an image  using below command from dockerfile (Dockerfile.drupal.ubi i.e Dockerfile)

     #docker build -t drupal_image .
     #docker images


Then run a container using that image.

    #docker run -it -d drupal_image /bin/bash
    #docker ps
    #docker exec -it a025d0a771a8 /bin/bash

Live drupal webserver will be available at http://<ip>:8081

After that we need to run below command inside container.Run it in single command . 
Step 1 will take sometime to exec. (configuration)

Step 1:- 

    su - postgres -c 'if [[ $(psql -l | grep dru2_pg) ]]; then     echo "Database already configured..."; else    /usr/pgsql-13/bin/pg_ctl -D /var/lib/pgsql/13/data/ start;     /usr/pgsql-13/bin/createdb -T template0 dru2_pg;     psql dru2_pg < /opt/app-root/src/drupal_schema.sql; fi'

Step 2:-

    /usr/sbin/httpd -k start;


step 3 Go to :-

    #cd /opt/app-root/src/drupal/modules

Clone the module which you wanted to test :-

/usr/sbin/httpd -k start

export PACKAGE_NAME=session_based_temp_store

cd /opt/app-root/src/drupal/modules
git clone  https://git.drupalcode.org/project/$PACKAGE_NAME
cd $PACKAGE_NAME
git checkout 8.x-1.1

cd /opt/app-root/src/drupal/core/
../vendor/bin/drush pm:enable $PACKAGE_NAME

RUN TEST:---

bash-4.4# ../vendor/phpunit/phpunit/phpunit ../modules/$PACKAGE_NAME/tests

TEST OUTPUT:--------

bash-4.4# git clone https://git.drupalcode.org/project/session_based_temp_store
Cloning into 'session_based_temp_store'...
warning: redirecting to https://git.drupalcode.org/project/session_based_temp_store.git/
remote: Enumerating objects: 156, done.
remote: Counting objects: 100% (35/35), done.
remote: Compressing objects: 100% (21/21), done.
remote: Total 156 (delta 12), reused 35 (delta 12), pack-reused 121
Receiving objects: 100% (156/156), 26.95 KiB | 8.98 MiB/s, done.
Resolving deltas: 100% (63/63), done.
bash-4.4# ls
README.txt  gutenberg  session_based_temp_store
bash-4.4# cd session_based_temp_store/
bash-4.4# git checkout 8.x-1.1
Note: switching to '8.x-1.1'.

You are in 'detached HEAD' state. You can look around, make experimental
changes and commit them, and you can discard any commits you make in this
state without impacting any branches by switching back to a branch.

If you want to create a new branch to retain commits you create, you may
do so (now or later) by using -c with the switch command. Example:

  git switch -c <new-branch-name>

Or undo this operation with:

  git switch -

Turn off this advice by setting config variable advice.detachedHead to false

HEAD is now at 0ceedb5 Fix test for D9
bash-4.4# cd /opt/app-root/src/drupal/core/
bash-4.4# ../vendor/bin/drush pm:enable session_based_temp_store
[success] Successfully enabled: session_based_temp_store
bash-4.4# ../vendor/phpunit/phpunit/phpunit ../modules/session_based_temp_store/tests/
PHPUnit 7.5.20 by Sebastian Bergmann and contributors.

Testing ../modules/session_based_temp_store/tests/
.                                                                   1 / 1 (100%)

Time: 18.82 seconds, Memory: 4.00 MB

OK (1 test, 13 assertions)