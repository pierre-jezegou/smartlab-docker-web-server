FROM php:7.3-apache
# Install stuff
RUN apt-get update && apt-get upgrade -y && rm -rf /var/lib/apt/lists/*
RUN apt-get update && apt-get install sudo unzip wget -y && rm -rf /var/lib/apt/lists/*
RUN docker-php-ext-install mysqli pdo pdo_mysql
# Configure stuff
RUN a2enmod rewrite
