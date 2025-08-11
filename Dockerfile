# -------------- base image --------------
FROM php:8.2-apache

# -------------- system deps --------------
RUN apt-get update && apt-get install -y \
      unzip curl git \
      libpng-dev libjpeg-dev libfreetype6-dev \
      libonig-dev libxml2-dev libzip-dev libpq-dev mariadb-client \
      libicu-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install mysqli pdo pdo_mysql zip gd intl xml soap mbstring \
    && a2enmod rewrite

# -------------- PHP tuning --------------
RUN printf "max_input_vars=5000\nupload_max_filesize=64M\npost_max_size=64M\nmemory_limit=512M\n" \
    > /usr/local/etc/php/conf.d/moodle.ini

# -------------- Apache → Railway port --------------
RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf \
 && sed -i 's/:80/:8080/g' /etc/apache2/ports.conf /etc/apache2/sites-enabled/000-default.conf

# -------------- get Moodle core into the image --------------
WORKDIR /var/www/html
RUN curl -L -o /tmp/moodle.zip \
      https://download.moodle.org/download.php/direct/stable500/moodle-latest-500.zip \
 && unzip /tmp/moodle.zip -d /tmp \
 && mv /tmp/moodle/* /var/www/html/ \
 && rm -rf /tmp/moodle /tmp/moodle.zip

# -------------- stage default moodledata (for first boot) --------------
# NOTE: put a permanent link here; filebin links expire
RUN mkdir -p /usr/src/moodledata \
 && curl -L "https://filebin.net/mxk4jbe4s15jnoda/filedir.tar.gz" -o /tmp/filedir.tar.gz || true \
 && if [ -f /tmp/filedir.tar.gz ]; then tar -xzf /tmp/filedir.tar.gz -C /usr/src/moodledata && rm /tmp/filedir.tar.gz; fi

# -------------- entrypoint --------------
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]

EXPOSE 8080
