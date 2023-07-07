
How to run drupal related modules test cases (Functional/Kernel).
-------------

Summary :-
    
    To run test cases in drupal module we need drupal core package and drupal complete framework which incluse one database,apache server,and core package itself.
    There are different types of tests in drupal. For unit test we dont need drupal full framework like database.
    Unit test does not use database testing.
	
	Some packages may require drupal 9.4.x version to run successfully. 
	For drupal 9.4.x: 
    Remove existing drupal folder from directory /opt/app-root/src/drupal and clone the 9.4.x version.
        #  git clone https://github.com/drupal/drupal  
        #  cd /opt/app-root/src/drupal/core
        #  cp phpunit.xml.dist phpunit.xml
    Edit the phpunit.xml file to update database url and apache server url.
    <env name="SIMPLETEST_BASE_URL" value="http://0.0.0.0:8081"/>
    <env name="SIMPLETEST_DB" value="pgsql://postgres:postgres@localhost/dru2_pg"/>
    
-------
*************************

Copy following files into VM thats needed to run docker file succesfully.

    1) automate_drupal.sh.txt
    2) Dockerfile.drupal.ubi
    3) drupal.zip
    4) drupal_schema.sql

Rename 2 files:-

    #cp Dockerfile.drupal.ubi Dockerfile
    #cp automate_drupal.sh.txt automate_drupal.sh
    #chmod +x automate_drupal.sh
     

Now create an image from dockerfile (Dockerfile.drupal.ubi i.e Dockerfile)
  
     #docker build -t drupal_image .
	 #docker images
	
Then run a container using that image.

    #docker run --name drupal_container -it -d drupal_image /bin/bash
	#docker ps
	#docker exec -it drupal_container /bin/bash

Live drupal webserver will be available at http://:8081

After that we need to run below command inside container.Run it in single command . Step 1 will take some time to execute. 

Step 1:- 

    su - postgres -c 'if [[ $(psql -l | grep dru2_pg) ]]; then     echo "Database already configured..."; else    /usr/pgsql-13/bin/pg_ctl -D /var/lib/pgsql/13/data/ -l logfile start;     /usr/pgsql-13/bin/createdb -T template0 dru2_pg;     psql dru2_pg < /opt/app-root/src/drupal_schema.sql; fi'

Step 2:-

    /usr/sbin/httpd -k start;


Go to :-

    #cd /opt/app-root/src/drupal/modules

Clone the module which you wanted to test :-

    #git clone  https://git.drupalcode.org/project/<package_name>
    #cd <package_name>
    #git checkout <version>   
  
Follow automate_drupal.sh for more detail:-

	#cd /opt/app-root/src/drupal

	bash-4.4#yum install -y git php php-json php-dom php-mbstring zip unzip gd gd-devel php-gd php-pdo php-mysqlnd
	bash-4.4#php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && php composer-setup.php --install-dir=/bin --filename=composer
	bash-4.4#composer require --dev phpunit/phpunit --with-all-dependencies ^8  --no-interaction

	bash-4.4# composer install
	bash-4.4# composer require drupal/facets:*
	bash-4.4# composer require drupal/pathauto:*	
	
	bash-4.4# cd /opt/app-root/src/drupal/modules/<package_name>
	
	
	#composer require --dev drush/drush
	bash-4.4# ./vendor/bin/drush pm:enable   
	
	bash-4.4# cd /opt/app-root/src/drupal/core
	    
     
	
RUN TESTS:- 
----------

To run Functional tests :-      

    bash-4.4# ../vendor/phpunit/phpunit/phpunit ../modules/<package_name>/tests/src/Functional
    
To run Kernel tests :-      

    bash-4.4# ../vendor/phpunit/phpunit/phpunit ../modules/<package_name>/tests/src/Kernel/

  
Run all tests in one go :-
    
    bash-4.4# ../vendor/phpunit/phpunit/phpunit ../modules/<package_name>/tests
    
    
Testcase Output :-
--------------------------------

Kernel tests :-

	bash-4.4#  ../vendor/phpunit/phpunit/phpunit ../modules/facets_pretty_paths/tests/src/Kernel/
  PHPUnit 7.5.20 by Sebastian Bergmann and contributors.
  
  Testing ../modules/facets_pretty_paths/tests/src/Kernel/
  ....                                                                4 / 4 (100%)
  
  Time: 10.61 seconds, Memory: 4.00 MB
  
  OK (4 tests, 19 assertions)

Functional tests :-

	bash-4.4#  ../vendor/phpunit/phpunit/phpunit ../modules/facets_pretty_paths/tests/src/Functional/
  PHPUnit 7.5.20 by Sebastian Bergmann and contributors.
  
  Testing ../modules/facets_pretty_paths/tests/src/Functional/
  ...                                                                 3 / 3 (100%)
  
  Time: 2.96 minutes, Memory: 4.00 MB
  
  OK (3 tests, 21 assertions)

All tests in one go :-

  bash-4.4#  ../vendor/phpunit/phpunit/phpunit ../modules/facets_pretty_paths/tests/
  PHPUnit 7.5.20 by Sebastian Bergmann and contributors.
  
  Testing ../modules/facets_pretty_paths/tests/
  .......                                                             7 / 7 (100%)
  
  Time: 7.22 minutes, Memory: 4.00 MB
  
  OK (7 tests, 40 assertions)

Note:-
----------

https://deninet.com/blog/2019/01/13/writing-automated-tests-drupal-8-part-2-functional-tests
https://deninet.com/blog/2018/12/31/writing-automated-tests-drupal-8-part-1-test-types-and-set

-------