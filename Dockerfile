FROM php:8.3-apache

RUN docker-php-ext-install pdo_pgsql \
    && a2enmod rewrite headers

COPY . /var/www/html/
RUN mkdir -p /var/www/html/uploads \
    && chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html

ENV APACHE_DOCUMENT_ROOT=/var/www/html
EXPOSE 80
CMD ["apache2-foreground"]
