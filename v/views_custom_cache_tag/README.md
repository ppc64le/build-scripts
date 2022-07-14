
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

    #git clone  https://git.drupalcode.org/project/views_custom_cache_tag.git
    #git checkout <requestedversions>   
----  
Follow automate_drupal.sh for more detail:-(Dependes on your package which version you need to install e.g ^8,^7)
  
    #cd /opt/app-root/src/drupal
    
     bash-4.4#yum install -y git php php-json php-dom php-mbstring zip unzip gd gd-devel php-gd php-pdo php-mysqlnd
     bash-4.4#php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && php composer-setup.php --install-dir=/bin --filename=composer
     bash-4.4#composer require --dev phpunit/phpunit --with-all-dependencies ^7  --no-interaction

     bash-4.4# composer install
    
    #cd /opt/app-root/src/drupal/modules/views_custom_cache_tag
    bash-4.4# pwd
    /opt/app-root/src/drupal/modules/views_custom_cache_tag
optional:---
    #composer require --dev drush/drush
    bash-4.4# ./vendor/bin/drush pm:enable   
------
    cd /opt/app-root/src/drupal/core
    bash-4.4# pwd
      /opt/app-root/src/drupal/core
	  
	  
	  or can use below steps after checkout the requested version:
	  
	  cd /opt/app-root/src/drupal/core
	  composer config allow-plugins true
	  composer update --ignore-platform-req=ext-gd
	  
	  
      Note:drupal 8.9.0 used in this package.
 
RUN TESTS:- 
----------
    
To run Functional tests :-      

    bash-4.4# ../vendor/phpunit/phpunit/phpunit ../modules/redirect/tests/src/Functional
   
Run all tests in one go :-
    
    bash-4.4# ../vendor/phpunit/phpunit/phpunit ../modules/views_custom_cache_tag/tests/
    
https://git.drupalcode.org/project/views_custom_cache_tag.git





Functional test output:
********************************
bash-4.4# ../vendor/phpunit/phpunit/phpunit ../modules/views_custom_cache_tag/tests/
PHPUnit 7.5.20 by Sebastian Bergmann and contributors.

Testing ../modules/views_custom_cache_tag/tests/
.                                                                   1 / 1 (100%)

Time: 37.14 seconds, Memory: 4.00 MB

OK (1 test, 46 assertions)

Remaining deprecation notices (2)

  1x: Any entity_reference_autocomplete component of an entity_form_display must have a match_limit setting. The uid field on the node.node_type_b.default form display is missing it. This BC layer will be removed before 9.0.0. See https://www.drupal.org/node/2863188
    1x in CustomCacheTagsTest::testCustomCacheTags from Drupal\Tests\views_custom_cache_tag\Functional

  1x: Any entity_reference_autocomplete component of an entity_form_display must have a match_limit setting. The uid field on the node.node_type_a.default form display is missing it. This BC layer will be removed before 9.0.0. See https://www.drupal.org/node/2863188
    1x in CustomCacheTagsTest::testCustomCacheTags from Drupal\Tests\views_custom_cache_tag\Functional

