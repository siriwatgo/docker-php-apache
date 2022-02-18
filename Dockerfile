FROM php:7.3-apache

# install ODBC driver
RUN apt-get update && apt-get install -y freetds-bin freetds-dev freetds-common libct4 libsybdb5 libicu-dev libcurl3-dev git zlib1g-dev apt-transport-https gnupg wget unixodbc-dev libldap2-dev \
    autoconf tzdata openntpd file g++ git gcc binutils libc-dev musl-dev make re2c coreutils libmcrypt-dev libpng-dev libxml2-dev libcurl4-openssl-dev curl \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    libssl-dev \
    libzip-dev && \
    apt-get clean; rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/doc/*

# Install mssql drivers
RUN curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add - && \
    curl https://packages.microsoft.com/config/debian/9/prod.list > /etc/apt/sources.list.d/mssql-release.list && \
    apt-get -y update && \
    export DEBIAN_FRONTEND=noninteractive && ACCEPT_EULA=Y apt-get install -y msodbcsql17 mssql-tools

RUN apt-get install -y wget
RUN wget http://ftp.br.debian.org/debian/pool/main/g/glibc/multiarch-support_2.24-11+deb9u4_amd64.deb && \
    dpkg -i multiarch-support_2.24-11+deb9u4_amd64.deb

# Install php extension
RUN docker-php-ext-configure intl --enable-intl && \
    docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu/ && \
    docker-php-ext-install ldap \
    && docker-php-ext-install -j$(nproc) iconv mysqli pdo pdo_mysql curl bcmath json xml zip opcache intl soap exif sockets \
    && pecl install sqlsrv \
    && pecl install pdo_sqlsrv \
    && docker-php-ext-enable sqlsrv pdo_sqlsrv \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install -j$(nproc) gd
    
# PHP settings
# COPY etc/php/production.ini /usr/local/etc/php/conf.d/production.ini

# TimeZone
RUN cp /usr/share/zoneinfo/Asia/Bangkok /etc/localtime \
  && echo "Asia/Bangkok" >  /etc/timezone
  
# Install Composer && Assets Plugin
RUN php -r "readfile('https://getcomposer.org/installer');" | php -- --install-dir=/usr/local/bin --filename=composer \
    # && composer global require --no-progress "fxp/composer-asset-plugin:~1.4" \
    && rm -rf /var/cache/apk/*

# Apache settings
# COPY etc/apache2/conf-enabled/host.conf /etc/apache2/conf-enabled/host.conf
# COPY etc/apache2/apache2.conf /etc/apache2/apache2.conf
# COPY etc/apache2/sites-enabled/000-default.conf /etc/apache2/sites-enabled/000-default.conf

COPY 000-default.conf /etc/apache2/sites-available/000-default.conf
COPY start-apache /usr/local/bin
RUN a2enmod rewrite

# Copy application source
COPY src /var/www/
RUN chown -R www-data:www-data /var/www

CMD ["start-apache"]
