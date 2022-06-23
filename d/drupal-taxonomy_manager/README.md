
How to run drupal related modules test cases.
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

    #git clone https://git.drupalcode.org/project/taxonomy_manager
    #git checkout <versions>   
  
Follow automate_drupal.sh for more detail:-
  
    #cd /opt/app-root/src/drupal
    
     bash-4.4#yum install -y git php php-json php-dom php-mbstring zip unzip gd gd-devel php-gd php-pdo php-mysqlnd
     bash-4.4#php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && php composer-setup.php --install-dir=/bin --filename=composer
     bash-4.4#composer require --dev phpunit/phpunit --with-all-dependencies ^8  --no-interaction

     bash-4.4# composer install
    
    #cd /opt/app-root/src/drupal/modules/taxonomy_manager
    bash-4.4# pwd
    /opt/app-root/src/drupal/modules/taxonomy_manager

    #composer require --dev drush/drush
    bash-4.4# ./vendor/bin/drush pm:enable taxonomy_manager   

    cd /opt/app-root/src/drupal/core
    bash-4.4# pwd
      /opt/app-root/src/drupal/core
      
 
RUN TEST:- 
----------    

    bash-4.4# ../vendor/phpunit/phpunit/phpunit ../modules/taxonomy_manager/src/Tests/
    
    
Test output
----------------    

bash-4.4# ../vendor/phpunit/phpunit/phpunit ../modules/taxonomy_manager/src/Tests/TaxonomyManagerPagesTest.php
PHPUnit 7.5.20 by Sebastian Bergmann and contributors.

Testing Drupal\taxonomy_manager\Tests\TaxonomyManagerPagesTest
EEE                                                                 3 / 3 (100%)

Time: 1.05 minutes, Memory: 4.00 MB

There were 3 errors:

1) Drupal\taxonomy_manager\Tests\TaxonomyManagerPagesTest::testConfigurationPageIsAccessible
Drupal\Core\Config\Schema\SchemaIncompleteException: Schema errors for taxonomy_manager.settings with the following errors: taxonomy_manager.settings:_core missing schema, taxonomy_manager.settings:langcode missing schema

/opt/app-root/src/drupal/core/lib/Drupal/Core/Config/Development/ConfigSchemaChecker.php:95
/opt/app-root/src/drupal/core/lib/Drupal/Component/EventDispatcher/ContainerAwareEventDispatcher.php:111
/opt/app-root/src/drupal/core/lib/Drupal/Core/Config/Config.php:231
/opt/app-root/src/drupal/core/lib/Drupal/Core/Config/ConfigInstaller.php:378
/opt/app-root/src/drupal/core/lib/Drupal/Core/Config/ConfigInstaller.php:137
/opt/app-root/src/drupal/core/lib/Drupal/Core/ProxyClass/Config/ConfigInstaller.php:75
/opt/app-root/src/drupal/core/lib/Drupal/Core/Extension/ModuleInstaller.php:288
/opt/app-root/src/drupal/core/lib/Drupal/Core/ProxyClass/Extension/ModuleInstaller.php:83
/opt/app-root/src/drupal/core/lib/Drupal/Core/Test/FunctionalTestSetupTrait.php:476
/opt/app-root/src/drupal/core/tests/Drupal/Tests/BrowserTestBase.php:578
/opt/app-root/src/drupal/core/tests/Drupal/Tests/BrowserTestBase.php:406
/opt/app-root/src/drupal/modules/taxonomy_manager/src/Tests/TaxonomyManagerPagesTest.php:41

2) Drupal\taxonomy_manager\Tests\TaxonomyManagerPagesTest::testVocabulariesListIsAccessible
Drupal\Core\Config\Schema\SchemaIncompleteException: Schema errors for taxonomy_manager.settings with the following errors: taxonomy_manager.settings:_core missing schema, taxonomy_manager.settings:langcode missing schema

/opt/app-root/src/drupal/core/lib/Drupal/Core/Config/Development/ConfigSchemaChecker.php:95
/opt/app-root/src/drupal/core/lib/Drupal/Component/EventDispatcher/ContainerAwareEventDispatcher.php:111
/opt/app-root/src/drupal/core/lib/Drupal/Core/Config/Config.php:231
/opt/app-root/src/drupal/core/lib/Drupal/Core/Config/ConfigInstaller.php:378
/opt/app-root/src/drupal/core/lib/Drupal/Core/Config/ConfigInstaller.php:137
/opt/app-root/src/drupal/core/lib/Drupal/Core/ProxyClass/Config/ConfigInstaller.php:75
/opt/app-root/src/drupal/core/lib/Drupal/Core/Extension/ModuleInstaller.php:288
/opt/app-root/src/drupal/core/lib/Drupal/Core/ProxyClass/Extension/ModuleInstaller.php:83
/opt/app-root/src/drupal/core/lib/Drupal/Core/Test/FunctionalTestSetupTrait.php:476
/opt/app-root/src/drupal/core/tests/Drupal/Tests/BrowserTestBase.php:578
/opt/app-root/src/drupal/core/tests/Drupal/Tests/BrowserTestBase.php:406
/opt/app-root/src/drupal/modules/taxonomy_manager/src/Tests/TaxonomyManagerPagesTest.php:41

3) Drupal\taxonomy_manager\Tests\TaxonomyManagerPagesTest::testTermsEditingPageIsAccessible
Drupal\Core\Config\Schema\SchemaIncompleteException: Schema errors for taxonomy_manager.settings with the following errors: taxonomy_manager.settings:_core missing schema, taxonomy_manager.settings:langcode missing schema

/opt/app-root/src/drupal/core/lib/Drupal/Core/Config/Development/ConfigSchemaChecker.php:95
/opt/app-root/src/drupal/core/lib/Drupal/Component/EventDispatcher/ContainerAwareEventDispatcher.php:111
/opt/app-root/src/drupal/core/lib/Drupal/Core/Config/Config.php:231
/opt/app-root/src/drupal/core/lib/Drupal/Core/Config/ConfigInstaller.php:378
/opt/app-root/src/drupal/core/lib/Drupal/Core/Config/ConfigInstaller.php:137
/opt/app-root/src/drupal/core/lib/Drupal/Core/ProxyClass/Config/ConfigInstaller.php:75
/opt/app-root/src/drupal/core/lib/Drupal/Core/Extension/ModuleInstaller.php:288
/opt/app-root/src/drupal/core/lib/Drupal/Core/ProxyClass/Extension/ModuleInstaller.php:83
/opt/app-root/src/drupal/core/lib/Drupal/Core/Test/FunctionalTestSetupTrait.php:476
/opt/app-root/src/drupal/core/tests/Drupal/Tests/BrowserTestBase.php:578
/opt/app-root/src/drupal/core/tests/Drupal/Tests/BrowserTestBase.php:406
/opt/app-root/src/drupal/modules/taxonomy_manager/src/Tests/TaxonomyManagerPagesTest.php:41

ERRORS!
Tests: 3, Assertions: 0, Errors: 3.

Remaining deprecation notices (3)

  3x: Drupal\Tests\BrowserTestBase::$defaultTheme is required in drupal:9.0.0 when using an install profile that does not set a default theme. See https://www.drupal.org/node/3083055, which includes recommendations on which theme to use.
    1x in TaxonomyManagerPagesTest::testConfigurationPageIsAccessible from Drupal\taxonomy_manager\Tests
    1x in TaxonomyManagerPagesTest::testVocabulariesListIsAccessible from Drupal\taxonomy_manager\Tests
    1x in TaxonomyManagerPagesTest::testTermsEditingPageIsAccessible from Drupal\taxonomy_manager\Tests