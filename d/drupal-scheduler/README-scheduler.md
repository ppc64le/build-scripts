
How to run drupal related modules test cases (Unit/Functional/Intergration).
-------------

Summary :-
    
    To run test cases in drupal module we need drupal core package and drupal complete framework which incluse one database,apache server,and core package itself.
    There are 3 type of tests in drupal unit,functional,intergration. For unit test we dont need drupal full framework like database.
    Unit test does not use database testing.
 
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

    #docker run -it -d drupal_image /bin/bash
    #docker ps
    #docker exec -it 69cabf536f6f /bin/bash

Live drupal webserver will be available at http://<ip>:8081

After that we need to run below command inside container.Run it in single command . Step 1 will take sometime to exec. 

Step 1:- 

    su - postgres -c 'if [[ $(psql -l | grep dru2_pg) ]]; then     echo "Database already configured..."; else    /usr/pgsql-13/bin/pg_ctl -D /var/lib/pgsql/13/data/ start;     /usr/pgsql-13/bin/createdb -T template0 dru2_pg;     psql dru2_pg < /opt/app-root/src/drupal_schema.sql; fi'

Step 2:-

    /usr/sbin/httpd -k start;


Go to :-

    #cd /opt/app-root/src/drupal/modules

Clone the module which you wanted to test :-

    #git clone  https://git.drupalcode.org/project/scheduler.git
    #git checkout <versions>   
  
Follow automate_drupal.sh for more detail:-
  
    #cd /opt/app-root/src/drupal
     git checkout  8.9.0
     
     bash-4.4#yum install -y git php php-json php-dom php-mbstring zip unzip gd gd-devel php-gd php-pdo php-mysqlnd
     bash-4.4#php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && php composer-setup.php --install-dir=/bin --filename=composer
     bash-4.4#composer require --dev phpunit/phpunit --with-all-dependencies ^7  --no-interaction
     bash-4.4# composer install
    
    #cd /opt/app-root/src/drupal/modules/scheduler
    bash-4.4# pwd
    /opt/app-root/src/drupal/modules/scheduler/

    cd /opt/app-root/src/drupal/core
    bash-4.4# pwd
      /opt/app-root/src/drupal/core
      
 
RUN TESTS:- 
----------
# To run all tests in one go :-
 
# checkout -: 8.x-1.4  Pass/Pass

# bash-4.4# ../vendor/bin/phpunit  ../modules/scheduler/tests/
                # PHPUnit 7.5.20 by Sebastian Bergmann and contributors.

                # Testing ../modules/scheduler/tests/
                # ................................................................. 65 / 74 ( 87%)
                # .......SS                                                         74 / 74 (100%)

# Time: 47.85 minutes, Memory: 4.00 MB

                # OK, but incomplete, skipped, or risky tests!
                # Tests: 74, Assertions: 1439, Skipped: 2.

                # Legacy deprecation notices (106)
                # bash-4.4#
         



# Test version  8.x-1.3   ---Pass/Parity 


# bash-4.4# ../vendor/bin/phpunit --filter testRulesEvents ../modules/scheduler/
            # PHPUnit 7.5.20 by Sebastian Bergmann and contributors.

            # Testing ../modules/scheduler/
            # E                                                                   1 / 1 (100%)

            # Time: 17.77 seconds, Memory: 4.00 MB

            # There was 1 error:

            # 1) Drupal\Tests\scheduler\Functional\SchedulerRulesEventsTest::testRulesEvents
            # TypeError: Argument 2 passed to Drupal\rules\Engine\RulesComponent::addContextDefinition() must implement interface Drupal\rules\Context\ContextDefinitionInterface, array given, called in /opt/app-root/src/drupal/modules/contrib/rules/src/Engine/RulesComponent.php on line 176

            # /opt/app-root/src/drupal/modules/contrib/rules/src/Engine/RulesComponent.php:146
            # /opt/app-root/src/drupal/modules/contrib/rules/src/Engine/RulesComponent.php:176
            # /opt/app-root/src/drupal/modules/contrib/rules/src/Entity/ReactionRuleConfig.php:161
            # /opt/app-root/src/drupal/modules/contrib/rules/src/Entity/ReactionRuleConfig.php:268
            # /opt/app-root/src/drupal/core/lib/Drupal/Core/Config/Entity/ConfigEntityBase.php:318
            # /opt/app-root/src/drupal/core/lib/Drupal/Core/Entity/EntityStorageBase.php:499
            # /opt/app-root/src/drupal/core/lib/Drupal/Core/Entity/EntityStorageBase.php:454
            # /opt/app-root/src/drupal/core/lib/Drupal/Core/Config/Entity/ConfigEntityStorage.php:263
            # /opt/app-root/src/drupal/modules/contrib/rules/src/Entity/ReactionRuleStorage.php:118
            # /opt/app-root/src/drupal/core/lib/Drupal/Core/Entity/EntityBase.php:395
            # /opt/app-root/src/drupal/core/lib/Drupal/Core/Config/Entity/ConfigEntityBase.php:616
            # /opt/app-root/src/drupal/modules/scheduler/tests/src/Functional/SchedulerRulesEventsTest.php:72

            # ERRORS!
            # Tests: 1, Assertions: 10, Errors: 1.
                     
  
-------------


Note:-
----------

https://deninet.com/blog/2019/01/13/writing-automated-tests-drupal-8-part-2-functional-tests
https://deninet.com/blog/2018/12/31/writing-automated-tests-drupal-8-part-1-test-types-and-set

-------
    For drupal 9.4.x    
    Remove existing drupal folder from directory /opt/app-root/src/drupal and clone the 9.4.x version.
        #  git clone https://github.com/drupal/drupal  
        #   cd /opt/app-root/src/drupal/core
        #   cp phpunit.xml.dist phpunit.xml
    Edit the phpunit.xml file to update database url and apache server url.
    <env name="SIMPLETEST_BASE_URL" value="http://0.0.0.0:8081"/>
    <env name="SIMPLETEST_DB" value="pgsql://postgres:postgres@localhost/dru2_pg"/>
    
-------