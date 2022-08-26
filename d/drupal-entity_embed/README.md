How to run drupal related modules test cases.
-------------

Summary :-

    To run test cases in drupal module, we need drupal core package and drupal complete framework which includes a database, apache server and core package itself.
    There are 3 type of tests in drupal Kernel, functional, FunctionalJavascript. No Unit testcase is avialable for this package.
  
    

*************************

Copy following files into the VM that is needed to run docker file successfully.

    1) automate_drupal.sh.txt
    2) Dockerfile.drupal.ubi
    3) drupal.zip
    4) drupal_schema.sql

Rename 2 files:-

    # cp Dockerfile.drupal.ubi Dockerfile
    # cp automate_drupal.sh.txt automate_drupal.sh
    # chmod +x automate_drupal.sh


Now create an image from dockerfile (Dockerfile.drupal.ubi i.e Dockerfile)

    # docker build -t drupal_image .
    # docker images

Then run a container using that image.

    # docker run -it -d drupal_image /bin/bash
    # docker ps
    # docker exec -it <container-id> /bin/bash

Live drupal webserver will be available at http://<ip>:8081

After that we need to run below command inside the container. Run it in single command. Step 1 will take some time to exec.

Step 1:-

    su - postgres -c 'if [[ $(psql -l | grep dru2_pg) ]]; then     echo "Database already configured..."; else    /usr/pgsql-13/bin/pg_ctl -D /var/lib/pgsql/13/data/ start;     /usr/pgsql-13/bin/createdb -T template0 dru2_pg;     psql dru2_pg < /opt/app-root/src/drupal_schema.sql; fi'

Step 2:-

    /usr/sbin/httpd -k start;


Go to :-

    # cd /opt/app-root/src/drupal/modules

Clone the module which you wanted to test :-

    # git clone https://git.drupalcode.org/project/entity_embed.git
    # git checkout <versions>

Follow automate_drupal.sh for more detail:-
    # cd /opt/app-root/src/drupal

    # yum install -y git php php-dom php-mbstring zip unzip gd gd-devel php-gd php-pdo php-mysqlnd
    # php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && php composer-setup.php --install-dir=/bin --filename=composer
    # composer require drupal/entity_browser:*
    # composer require drupal/entity_embed:*
    # composer require drupal/embed:*
    # composer require drupal/token:*
    
    # bash-4.4# ./vendor/bin/drush pm:enable entity_browser
       [notice] Already enabled: entity_browser
    # bash-4.4# ./vendor/bin/drush pm:enable embed
       [success] Successfully enabled: embed
    # bash-4.4# ./vendor/bin/drush pm:enable entity_embed
       [success] Successfully enabled: entity_embed
    # bash-4.4# ./vendor/bin/drush pm:enable token
       [success] Successfully enabled: token
    # cd /opt/app-root/src/drupal/core


RUN TEST:-
----------
    # ../vendor/phpunit/phpunit/phpunit ../modules/entity_embed/tests/

Test output
---------------
    bash-4.4# cd core/
    Functional Test:   

    bash-4.4# ../vendor/phpunit/phpunit/phpunit ../modules/entity_embed/tests/src/Functional
    PHPUnit 7.5.20 by Sebastian Bergmann and contributors.

    Testing ../modules/entity_embed/tests/src/Functional
    ...E..................                                            22 / 22 (100%)
    Time: 4.19 minutes, Memory: 4.00 MB
    There was 1 error:
    1) Drupal\Tests\entity_embed\Functional\EntityEmbedDisplayManagerTest::testGetDefinitionsForContexts
    PHPUnit\Framework\Exception: libpng warning: iCCP: known incorrect sRGB profile
    ERRORS!
    Tests: 22, Assertions: 465, Errors: 1.
    Remaining deprecation notices (21)

    # Test failure at parity with x86 Intel system

    Kernel Test:

    bash-4.4# ../vendor/phpunit/phpunit/phpunit ../modules/entity_embed/tests/src/Kernel/
    PHPUnit 7.5.20 by Sebastian Bergmann and contributors.

    Testing ../modules/entity_embed/tests/src/Kernel/
    ................FFF.........................                      44 / 44 (100%)
    Time: 1.21 minutes, Memory: 4.00 MB
    #Test failure at parity with x86 Intel system
    There were 3 failures:
    1) Drupal\Tests\entity_embed\Kernel\EntityEmbedFilterTest::testMissingEntityIndicator with data set "node; valid UUID but for a deleted entity" ('node',     'e7a3e1fe-b69b-417e-8ee4-c80cb7640e63', 'Missing content item.')
    Failed asserting that an object is not empty.
    /opt/app-root/src/drupal/modules/entity_embed/tests/src/Kernel/EntityEmbedFilterTest.php:261

    2) Drupal\Tests\entity_embed\Kernel\EntityEmbedFilterTest::testMissingEntityIndicator with data set "node; invalid UUID" ('node', 'invalidUUID', 'Missing    content item.')
    Failed asserting that an object is not empty.
    /opt/app-root/src/drupal/modules/entity_embed/tests/src/Kernel/EntityEmbedFilterTest.php:261

    3) Drupal\Tests\entity_embed\Kernel\EntityEmbedFilterTest::testMissingEntityIndicator with data set "user; invalid UUID" ('user', 'invalidUUID', 'Missing    user.')
    Failed asserting that an object is not empty.
    /opt/app-root/src/drupal/modules/entity_embed/tests/src/Kernel/EntityEmbedFilterTest.php:261
    Legacy deprecation notices (8)

    # Test failure at parity with x86 Intel system

    FunctionalJavascript Test:

    bash-4.4# ../vendor/phpunit/phpunit/phpunit ../modules/entity_embed/tests/src/FunctionalJavascript/
    PHPUnit 7.5.20 by Sebastian Bergmann and contributors.

    Testing ../modules/entity_embed/tests/src/FunctionalJavascript/
    SSSSSSSSSSSSSSSSSSSSSSSSSSSSSS                                    30 / 30 (100%)
    Time: 5.12 minutes, Memory: 4.00 MB
    OK, but incomplete, skipped, or risky tests!
    Tests: 30, Assertions: 30, Skipped: 30.

    Remaining deprecation notices (30)
    
   
