
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
    #docker exec -it 9fb83eb89cd9 /bin/bash

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

    #git clone  https://git.drupalcode.org/project/file_upload_secure_validator.git
    #git checkout <requestedversions>   
----  
Follow automate_drupal.sh for more detail:-(Dependes on your package which version you need to install e.g ^8,^7)
  
    #cd /opt/app-root/src/drupal
    
     bash-4.4#yum install -y git php php-json php-dom php-mbstring zip unzip gd gd-devel php-gd php-pdo php-mysqlnd
     bash-4.4#php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && php composer-setup.php --install-dir=/bin --filename=composer
     bash-4.4#composer require --dev phpunit/phpunit --with-all-dependencies ^7  --no-interaction

     bash-4.4# composer install
    
    #cd /opt/app-root/src/drupal/modules/file_upload_secure_validator
    bash-4.4# pwd
    /opt/app-root/src/drupal/modules/file_upload_secure_validator
	 optional :
	 #composer require --dev drush/drush
direct we can also execute below command :--

  
	cd /opt/app-root/src/drupal/core
    bash-4.4# ./vendor/bin/drush pm:enable packagename 
------
    cd /opt/app-root/src/drupal/core
    bash-4.4# pwd
      /opt/app-root/src/drupal/core
	  
	  
	  or can use below steps after checkout the requested version:
	  
	  cd /opt/app-root/src/drupal/core
	  composer config allow-plugins true
	  composer update --ignore-platform-req=ext-gd
	  
	  
      Note:drupal 8.9.0 used in this package.
      
 --------------------------------------------
 	        
    Remove existing drupal folder from directory /opt/app-root/src/drupal and clone the 8.9.0 version.
        #  git clone https://github.com/drupal/drupal  
        #   cd /opt/app-root/src/drupal/core
        #   cp phpunit.xml.dist phpunit.xml
    Edit the phpunit.xml file to update database url and apache server url.
    <env name="SIMPLETEST_BASE_URL" value="http://0.0.0.0:8081"/>
    <env name="SIMPLETEST_DB" value="pgsql://postgres:postgres@localhost/dru2_pg"/>
 
RUN TESTS:- 
----------
Unit Test:

bash-4.4# ../vendor/phpunit/phpunit/phpunit ../modules/file_upload_secure_validator/tests/src/Unit


To run Functional tests :-      

    bash-4.4# ../vendor/phpunit/phpunit/phpunit ../modules/file_upload_secure_validator/tests/src/Functional
   
Run all tests in one go :-
    
    bash-4.4# ../vendor/phpunit/phpunit/phpunit ../modules/file_upload_secure_validator/tests/
    


Unit Testoutput:
*******************

67 packages you are using are looking for funding.
Use the `composer fund` command to find out more!
Cleaning vendor directory.
> Drupal\Composer\Composer::generateMetapackages
Updated metapackage file composer/Metapackage/DevDependencies/composer.json.
If you make a patch, ensure that the files above are included.
Cloning into 'file_upload_secure_validator'...
remote: Enumerating objects: 261, done.
remote: Counting objects: 100% (126/126), done.
remote: Compressing objects: 100% (95/95), done.
remote: Total 261 (delta 34), reused 91 (delta 23), pack-reused 135
Receiving objects: 100% (261/261), 212.39 KiB | 3.86 MiB/s, done.
Resolving deltas: 100% (93/93), done.
Note: switching to '8.x-1.4'.

You are in 'detached HEAD' state. You can look around, make experimental
changes and commit them, and you can discard any commits you make in this
state without impacting any branches by switching back to a branch.

If you want to create a new branch to retain commits you create, you may
do so (now or later) by using -c with the switch command. Example:

  git switch -c <new-branch-name>

Or undo this operation with:

  git switch -

Turn off this advice by setting config variable advice.detachedHead to false

HEAD is now at 984a9e3 Issue #3197971 by stefanos.petrakis, mohit.bansal623: Undefined class constant 'NO_HEADERS_KEY'
PHPUnit 7.5.20 by Sebastian Bergmann and contributors.

Testing ../modules/file_upload_secure_validator/tests/src/Unit
.........                                                           9 / 9 (100%)

Time: 955 ms, Memory: 6.00 MB

OK (9 tests, 9 assertions)
------------------file_upload_secure_validator:install_&_test_both_success-------------------------
https://git.drupalcode.org/project/file_upload_secure_validator.git file_upload_secure_validator
file_upload_secure_validator  |  https://git.drupalcode.org/project/file_upload_secure_validator.git | 8.x-1.4 | Red Hat Enterprise Linux 8.6 (Ootpa) | GitHub  | Pass |  Both_Install_and_Test_Success


../vendor/phpunit/phpunit/phpunit ../modules/file_upload_secure_validator/tests/src/Unit




Functional test output:
********************************

bash-4.4# ../vendor/phpunit/phpunit/phpunit ../modules/file_upload_secure_validator/tests/src/Functional
PHPUnit 7.5.20 by Sebastian Bergmann and contributors.

Testing ../modules/file_upload_secure_validator/tests/src/Functional
.                                                                   1 / 1 (100%)

Time: 37.47 seconds, Memory: 4.00 MB

OK (1 test, 181 assertions)
