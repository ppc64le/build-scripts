FROM ppc64le/php:7.0-apache
MAINTAINER Snehlata Mohite (smohite@us.ibm.com)


# Define Joomla version and expected SHA1 signature
ENV JOOMLA_VERSION 3.6.5
ENV JOOMLA_SHA1 3143994bb5520c249961cbb5bc297c149399f4b7

# Enable Apache Rewrite Module
# Install PHP extensions
RUN a2enmod rewrite\
    && apt-get update && apt-get install -y libpng12-dev libjpeg-dev libmcrypt-dev zip unzip && rm -rf /var/lib/apt/lists/* \
	&& docker-php-ext-configure gd --with-png-dir=/usr --with-jpeg-dir=/usr \
	&& docker-php-ext-install gd\
	&& docker-php-ext-install mysqli\
	&&  docker-php-ext-install mcrypt\
# Download package and extract to web volume
	&& curl -o joomla.zip -SL https://github.com/joomla/joomla-cms/releases/download/${JOOMLA_VERSION}/Joomla_${JOOMLA_VERSION}-Stable-Full_Package.zip \
	&& echo "$JOOMLA_SHA1 *joomla.zip" | sha1sum -c - \
	&& mkdir /usr/src/joomla \
	&& unzip joomla.zip -d /usr/src/joomla \
	&& rm joomla.zip \
	&& chown -R www-data:www-data /usr/src/joomla\
	&& apt-get autoremove -y zip unzip && apt-get clean
VOLUME /var/www/html
# Copy init scripts and custom .htaccess

COPY docker-entrypoint.sh /entrypoint.sh
COPY makedb.php /makedb.php

RUN chmod +x /entrypoint.sh && chmod +x /makedb.php 

ENTRYPOINT ["/entrypoint.sh"]
CMD ["apache2-foreground"]
