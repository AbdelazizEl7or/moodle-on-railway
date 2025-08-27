FROM php:8.2-apache

# System deps
RUN apt-get update && apt-get install -y \
      unzip curl git dos2unix \
      libpng-dev libjpeg-dev libfreetype6-dev \
      libonig-dev libxml2-dev libzip-dev libpq-dev mariadb-client libicu-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install mysqli pdo pdo_mysql zip gd intl xml soap mbstring \
    && a2enmod rewrite

# PHP tuning
RUN printf "max_input_vars=5000\nupload_max_filesize=64M\npost_max_size=64M\nmemory_limit=512M\n" \
    > /usr/local/etc/php/conf.d/moodle.ini

# Apache → 8080
RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf \
 && sed -i 's/:80/:8080/g' /etc/apache2/ports.conf /etc/apache2/sites-enabled/000-default.conf

# Moodle core in image
WORKDIR /var/www/html
RUN curl -L -o /tmp/moodle.zip \
      https://download.moodle.org/download.php/direct/stable500/moodle-5.0.1.zip \
 && unzip /tmp/moodle.zip -d /tmp \
 && mv /tmp/moodle/* /var/www/html/ \
 && rm -rf /tmp/moodle /tmp/moodle.zip

# Optional: stage default moodledata for first boot (use a permanent link if you need this)
RUN mkdir -p /usr/src/moodledata \
 && echo "(Optional) put filedir defaults here if needed" >/usr/src/moodledata/README.txt

# Entrypoint
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN dos2unix /usr/local/bin/entrypoint.sh && chmod +x /usr/local/bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]

EXPOSE 8080
