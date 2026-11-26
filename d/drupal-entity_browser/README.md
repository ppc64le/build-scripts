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

    # git clone https://git.drupalcode.org/project/entity_browser.git
    # git checkout <versions>

Follow automate_drupal.sh for more detail:-
    # cd /opt/app-root/src/drupal

    # yum install -y git php php-dom php-mbstring zip unzip gd gd-devel php-gd php-pdo php-mysqlnd
    # php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && php composer-setup.php --install-dir=/bin --filename=composer
    # composer require drupal/inline_entity_form:*
    # composer require drupal/entity_embed:*
    # composer require drupal/embed:*
    # composer require drupal/token:*
    # composer require drupal/paragraphs:*
    # composer require drupal/entityqueue:*
    # composer require drupal/entity_reference_revisions:*
    
    # bash-4.4# ./vendor/bin/drush pm:enable entity_browser
       [notice] Already enabled: entity_browser
    # bash-4.4# ./vendor/bin/drush pm:enable embed
       [success] Successfully enabled: embed
    # bash-4.4# ./vendor/bin/drush pm:enable inline_entity_form
       [success] Successfully enabled: inline_entity_form
    # bash-4.4# ./vendor/bin/drush pm:enable entity_reference_revisions
       [success] Successfully enabled: entity_reference_revisions
    # bash-4.4# ./vendor/bin/drush pm:enable entity_embed
       [success] Successfully enabled: entity_embed
    # bash-4.4# ./vendor/bin/drush pm:enable token
       [success] Successfully enabled: token
    # bash-4.4# ./vendor/bin/drush pm:enable paragraphs
       [success] Successfully enabled: paragraphs
    # bash-4.4# ./vendor/bin/drush pm:enable entityqueue
      [success] Successfully enabled: entityqueue
    # cd /opt/app-root/src/drupal/core


RUN TEST:-
----------
    # ../vendor/phpunit/phpunit/phpunit ../modules/entity_browser/tests/

Test output
---------------
    bash-4.4# cd core/
    bash-4.4# ../vendor/phpunit/phpunit/phpunit ../modules/entity_browser/tests/src/
PHPUnit 7.5.20 by Sebastian Bergmann and contributors.

Testing ../modules/entity_browser/tests/src/
......SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS.........             53 / 53 (100%)

Time: 48.91 minutes, Memory: 4.00 MB

OK, but incomplete, skipped, or risky tests!
Tests: 53, Assertions: 532, Skipped: 38.

Remaining deprecation notices (7)

  6x: Any entity_reference_autocomplete component of an entity_form_display must have a match_limit setting. The uid field on the node.test_entity_embed.default form display is missing it. This BC layer will be removed before 9.0.0. See https://www.drupal.org/node/2863188
    1x in CardinalityTest::testEntityReferenceWidget from Drupal\Tests\entity_browser\FunctionalJavascript
    1x in CardinalityTest::testEntityEmbed from Drupal\Tests\entity_browser\FunctionalJavascript
    1x in CardinalityTest::testInlineEntityForm from Drupal\Tests\entity_browser\FunctionalJavascript
    1x in EntityEmbedTest::testEntityBrowserWidgetContext from Drupal\Tests\entity_browser\FunctionalJavascript
    1x in EntityEmbedTest::testContextualBundle from Drupal\Tests\entity_browser\FunctionalJavascript
    1x in EntityEmbedTest::testContextualBundleExposed from Drupal\Tests\entity_browser\FunctionalJavascript

  1x: Any entity_reference_autocomplete component of an entity_form_display must have a match_limit setting. The uid field on the node.paragraphs_test.default form display is missing it. This BC layer will be removed before 9.0.0. See https://www.drupal.org/node/2863188
    1x in ParagraphsTest::testParagraphs from Drupal\Tests\entity_browser\FunctionalJavascript
bash-4.4#
