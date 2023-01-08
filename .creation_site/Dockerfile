FROM php:7.3-apache
# Install stuff
RUN apt-get update && apt-get upgrade -y
RUN apt-get install sudo unzip wget -y
RUN docker-php-ext-install mysqli pdo pdo_mysql
# Configure stuff
RUN a2enmod rewrite
RUN a2enmod ssl
RUN service apache2 restart
EXPOSE 80
