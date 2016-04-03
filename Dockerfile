FROM php:5.6-fpm

MAINTAINER Evgen Kretsu <krecu.me@ya.ru>

LABEL Description="PHP-fpm with installed extensions" Vendor="GosBook Lab" Version="1.0"

########################################################################################################################
# Опредялем переменные
########################################################################################################################
# Версия PhpRedis
ENV PHPREDIS_VERSION 2.2.7

# Версия xDebug
ENV XDEBUG_VERSION 2.3.3

# Версия AMQP
ENV AMQP_VERSION 0.7.1

########################################################################################################################
# Устанавливаем php extension
########################################################################################################################
RUN apt-get update && apt-get upgrade -y
RUN apt-get install -y \
#        postgresql-client \
        libfreetype6 \
        libjpeg62-turbo \
        libmcrypt4 \
        libpng12-0 \
        libjpeg-dev \
        libldap2-dev \
		libfreetype6-dev \
		libmcrypt-dev \
		libpng12-dev \
		libpq-dev \
		zlib1g-dev

RUN	docker-php-ext-configure gd --enable-gd-native-ttf --with-jpeg-dir=/usr/lib/x86_64-linux-gnu --with-png-dir=/usr/lib/x86_64-linux-gnu --with-freetype-dir=/usr/lib/x86_64-linux-gnu \
	&& docker-php-ext-install gd \
	&& docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu \
	&& docker-php-ext-install ldap \
	&& docker-php-ext-install mbstring \
	&& docker-php-ext-install mcrypt \
	&& docker-php-ext-install pdo_pgsql \
	#&& docker-php-ext-install mysql \
	#&& docker-php-ext-install mysqli \
	#&& docker-php-ext-install pdo_mysql \
	&& docker-php-ext-install zip \
	&& docker-php-ext-install bcmath


########################################################################################################################
# Устанавливаем php extension PhpRedis
########################################################################################################################
RUN curl -L -o /tmp/redis.tar.gz https://github.com/phpredis/phpredis/archive/$PHPREDIS_VERSION.tar.gz \
    && tar xfz /tmp/redis.tar.gz \
    && rm -r /tmp/redis.tar.gz \
    && mv phpredis-$PHPREDIS_VERSION /usr/src/php/ext/redis \
    && docker-php-ext-install redis

########################################################################################################################
# Устанавливаем php extension AMQP
########################################################################################################################
RUN curl -L -o /tmp/amqp.tar.gz https://github.com/alanxz/rabbitmq-c/releases/download/v0.7.1/rabbitmq-c-$AMQP_VERSION.tar.gz \
    && tar xfz /tmp/amqp.tar.gz \
    && rm -r /tmp/amqp.tar.gz \
    && mv rabbitmq-c-$AMQP_VERSION /usr/src/php/ext/amqp \
    && cd /usr/src/php/ext/amqp \
    && ./configure && make && make install


########################################################################################################################
# Устанавливаем php extension xDebug
########################################################################################################################
RUN curl -L -o /tmp/xdebug.tar.gz https://github.com/xdebug/xdebug/archive/$XDEBUG_VERSION.tar.gz \
    && tar xfz /tmp/xdebug.tar.gz \
    && rm -r /tmp/xdebug.tar.gz \
    && mv xdebug-$XDEBUG_VERSION /usr/src/php/ext/xdebug \
    && docker-php-ext-install xdebug

# немного правим конфиг
RUN sed -i '1 a xdebug.remote_autostart = true' $PHP_INI_DIR/conf.d/docker-php-ext-xdebug.ini \
    && sed -i '1 a xdebug.remote_mode = req' $PHP_INI_DIR/conf.d/docker-php-ext-xdebug.ini \
    && sed -i '1 a xdebug.remote_handler = dbgp' $PHP_INI_DIR/conf.d/docker-php-ext-xdebug.ini \
    && sed -i '1 a xdebug.remote_connect_back = 1 ' $PHP_INI_DIR/conf.d/docker-php-ext-xdebug.ini \
    && sed -i '1 a xdebug.remote_port = 9999' $PHP_INI_DIR/conf.d/docker-php-ext-xdebug.ini \
    && sed -i '1 a xdebug.remote_enable = 1' $PHP_INI_DIR/conf.d/docker-php-ext-xdebug.ini

# Устанавливаем composer
RUN curl -sS https://getcomposer.org/installer | php \
    && mv composer.phar /usr/local/bin/composer

########################################################################################################################
# Фиксим php.ini
########################################################################################################################
RUN cat /usr/src/php/php.ini-production | sed 's/^;\(date.timezone.*\)/\1 \"Etc\/UTC\"/' > /usr/local/etc/php/php.ini
RUN sed -i 's/;\(cgi\.fix_pathinfo=\)1/\10/' /usr/local/etc/php/php.ini

# открываем порт
EXPOSE 9999