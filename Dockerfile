# Używamy Ubuntu 22.04 LTS jako obrazu bazowego
FROM ubuntu:22.04

# Ustawiamy zmienną środowiskową dla nieinteraktywnej instalacji APT
ENV DEBIAN_FRONTEND=noninteractive

# 1. Aktualizujemy listę pakietów i instalujemy Apache2 oraz PHP (domyślne dla Ubuntu 22.04)
#    Instalujemy metapakiety PHP, które wskażą na wersję 8.1 w Ubuntu 22.04.
#    Dodajemy również wszystkie biblioteki potrzebne dla Imagick i HEIF.
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        apache2 \
        php \
        libapache2-mod-php \
        php-mysql \
        php-cli \
        php-common \
        php-json \
        php-opcache \
        php-readline \
        php-xml \
        php-mbstring \
        php-zip \
        php-bcmath \
        php-bz2 \
        php-gd \
        php-imap \
        php-ldap \
        php-soap \
        php-imagick \
        # Pakiety dla Imagick i HEIF
        libmagickwand-dev \
        imagemagick \
        ghostscript \
        libheif-dev \
        libheif-examples \
        liblcms2-utils \
		liblcms2-dev \

    && apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/doc/*

COPY policy.xml /etc/ImageMagick-6/policy.xml

# 2. Konfiguracja Apache
# Włączamy mod_rewrite (często potrzebne dla aplikacji PHP, np. frameworków)
RUN a2enmod rewrite \
    && sed -i '/<Directory \/var\/www\/>/,/<\/Directory>/d' /etc/apache2/apache2.conf \
    && echo '<Directory /var/www/html>' >> /etc/apache2/apache2.conf \
    && echo '    Options Indexes FollowSymLinks' >> /etc/apache2/apache2.conf \
    && echo '    AllowOverride All' >> /etc/apache2/apache2.conf \
    && echo '    Require all granted' >> /etc/apache2/apache2.conf \
    && echo '</Directory>' >> /etc/apache2/apache2.conf \
    && sed -i 's|DocumentRoot .*|DocumentRoot /var/www/html|g' /etc/apache2/sites-available/000-default.conf
# Ustawiamy ServerName, aby Apache nie wyświetlał ostrzeżeń przy starcie
RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf

# Przekierowanie logów Apache i PHP do stdout/stderr
RUN ln -sf /dev/stdout /var/log/apache2/access.log && \
    ln -sf /dev/stderr /var/log/apache2/error.log && \
    echo "log_errors = On" >> /etc/php/8.1/apache2/php.ini && \
    echo "error_log = /dev/stderr" >> /etc/php/8.1/apache2/php.ini && \
    echo "log_errors = On" >> /etc/php/8.1/cli/php.ini && \
    echo "error_log = /dev/stderr" >> /etc/php/8.1/cli/php.ini

# 3. Ekspozycja portu 80
EXPOSE 80

# 4. Definiujemy komendę uruchamiającą Apache na pierwszym planie,
#    co jest standardową praktyką dla kontenerów Docker.
CMD ["apache2ctl", "-D", "FOREGROUND"]
