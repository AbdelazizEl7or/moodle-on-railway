FROM php:8.1-apache

RUN apt-get update && apt-get install -y \
    unzip git libpng-dev libjpeg-dev libfreetype6-dev libonig-dev libxml2-dev zip \
    mariadb-client libzip-dev libpq-dev \
    && docker-php-ext-install mysqli pdo pdo_mysql zip gd intl xml soap mbstring \
    && a2enmod rewrite

WORKDIR /var/www/html

RUN curl -L -o moodle.zip https://download.moodle.org/download.php/direct/stable500/moodle-latest-500.zip && \
    unzip moodle.zip && mv moodle/* ./ && rm -rf moodle moodle.zip

RUN chown -R www-data:www-data /var/www/html && chmod -R 755 /var/www/html

# ✅ Configure Apache to listen on port 8080 for Railway
RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf && \
    sed -i 's/80/8080/g' /etc/apache2/ports.conf /etc/apache2/sites-enabled/000-default.conf

EXPOSE 8080
