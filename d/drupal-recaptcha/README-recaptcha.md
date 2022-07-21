
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

    #git clone https://git.drupalcode.org/project/recaptcha
    #git checkout <versions>   
  
Follow automate_drupal.sh for more detail:-
  
    #cd /opt/app-root/src/drupal
     git checkout  8.9.0
     
     bash-4.4#yum install -y git php php-json php-dom php-mbstring zip unzip gd gd-devel php-gd php-pdo php-mysqlnd
     bash-4.4#php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && php composer-setup.php --install-dir=/bin --filename=composer
     bash-4.4#composer require --dev phpunit/phpunit --with-all-dependencies ^7  --no-interaction
     bash-4.4# composer install
    
    #cd /opt/app-root/src/drupal/modules/recaptcha
    bash-4.4# pwd
    /opt/app-root/src/drupal/modules/recaptcha/

    cd /opt/app-root/src/drupal/core
    bash-4.4# pwd
      /opt/app-root/src/drupal/core
      
 
RUN TESTS:- 
----------
  
# Test is parity with intel.

# To run all tests in one go :-

# bash-4.4# ../vendor/phpunit/phpunit/phpunit ../modules/recaptcha/tests/
            # PHPUnit 7.5.20 by Sebastian Bergmann and contributors.

            # Testing ../modules/recaptcha/tests/
            # FFF                                                                 3 / 3 (100%)

            # Time: 52.61 seconds, Memory: 4.00 MB

            # There were 3 failures:

            # 1) Drupal\Tests\recaptcha\Functional\ReCaptchaBasicTest::testReCaptchaAdminAccess
            # Invalid permission <em class="placeholder">administer content types</em>.

            # /opt/app-root/src/drupal/core/modules/user/tests/src/Traits/UserCreationTrait.php:314
            # /opt/app-root/src/drupal/core/modules/user/tests/src/Traits/UserCreationTrait.php:261
            # /opt/app-root/src/drupal/core/modules/user/tests/src/Traits/UserCreationTrait.php:164
            # /opt/app-root/src/drupal/modules/recaptcha/tests/src/Functional/ReCaptchaBasicTest.php:68

            # 2) Drupal\Tests\recaptcha\Functional\ReCaptchaBasicTest::testReCaptchaAdminSettingsForm
            # Invalid permission <em class="placeholder">administer content types</em>.

            # /opt/app-root/src/drupal/core/modules/user/tests/src/Traits/UserCreationTrait.php:314
            # /opt/app-root/src/drupal/core/modules/user/tests/src/Traits/UserCreationTrait.php:261
            # /opt/app-root/src/drupal/core/modules/user/tests/src/Traits/UserCreationTrait.php:164
            # /opt/app-root/src/drupal/modules/recaptcha/tests/src/Functional/ReCaptchaBasicTest.php:68

            # 3) Drupal\Tests\recaptcha\Functional\ReCaptchaBasicTest::testReCaptchaOnLoginForm
            # Invalid permission <em class="placeholder">administer content types</em>.

            # /opt/app-root/src/drupal/core/modules/user/tests/src/Traits/UserCreationTrait.php:314
            # /opt/app-root/src/drupal/core/modules/user/tests/src/Traits/UserCreationTrait.php:261
            # /opt/app-root/src/drupal/core/modules/user/tests/src/Traits/UserCreationTrait.php:164
            # /opt/app-root/src/drupal/modules/recaptcha/tests/src/Functional/ReCaptchaBasicTest.php:68

            # FAILURES!
            # Tests: 3, Assertions: 18, Failures: 3.
  
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