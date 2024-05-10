PACKAGE_NAME=editor_file
PACKAGE_VERSION=${1:-8.x-1.6}
PACKAGE_URL=https://git.drupalcode.org/project/editor_file.git

#yum module enable php:7.3 -y
yum update -y
yum install php -y
yum install php-mysql -y

yum install php php-json php-devel zip unzip php-zip wget git php-pdo php-dom php-mbstring -y
 
/usr/bin/php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && /usr/bin/php composer-setup.php --install-dir=/bin --filename=composer

rm -rf drupal
git clone https://github.com/drupal/drupal.git
cd drupal
git checkout 8.9.0
cd core/modules

 curl -sS https://getcomposer.org/installer | php
 #mv composer.phar /usr/local/bin/composer
 composer install --ignore-platform-reqs

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
cd ../../..
composer config allow-plugins true

if ! composer update --ignore-platform-req=ext-gd ; then
        echo "$PACKAGE_NAME  |  $PACKAGE_VERSION ------------------Build_fails---------------------"
        exit 1
else
        echo "$PACKAGE_NAME  |  $PACKAGE_VERSION ------------------Build_success-------------------------"
fi
