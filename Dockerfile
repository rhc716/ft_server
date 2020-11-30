FROM debian:buster

RUN	apt-get update && apt-get install -y \
	nginx \
	mariadb-server \
	php-mysql \
	openssl \
	vim \
	wget \
	php7.3-fpm

COPY	./srcs/setup.sh ./tmp
COPY	./srcs/default ./tmp
COPY	./srcs/wp-config.php ./tmp
COPY	./srcs/config.inc.php ./tmp

# nginx
RUN cp -rp /tmp/default /etc/nginx/sites-available/

# SSL
RUN openssl req -newkey rsa:4096 -days 365 -nodes -x509 -subj "/C=KR/ST=Seoul/L=Seoul/O=42Seoul/OU=hroh/CN=localhost" -keyout test.key -out test.crt &&\
	mv test.crt etc/ssl/certs/ &&\
	mv test.key etc/ssl/private/ &&\
	chmod 600 etc/ssl/certs/test.crt etc/ssl/private/test.key

# wordpress
RUN wget https://wordpress.org/latest.tar.gz &&\
	tar -xvf latest.tar.gz &&\
	rm latest.tar.gz &&\
	mv wordpress/ var/www/html/ &&\
	chown -R www-data:www-data /var/www/html/wordpress &&\
	cp -rp ./tmp/wp-config.php /var/www/html/wordpress

# mysql DB table
RUN service mysql start &&\
	echo "CREATE DATABASE IF NOT EXISTS wordpress;" \
	| mysql -u root --skip-password &&\
	echo "CREATE USER IF NOT EXISTS 'hroh'@'localhost' IDENTIFIED BY 'hroh';" \
	| mysql -u root --skip-password &&\
	echo "GRANT ALL PRIVILEGES ON wordpress.* TO 'hroh'@'localhost' WITH GRANT OPTION;" \
	| mysql -u root --skip-password

# phpMyAdmin
RUN wget https://files.phpmyadmin.net/phpMyAdmin/5.0.2/phpMyAdmin-5.0.2-all-languages.tar.gz &&\
	tar -xvf phpMyAdmin-5.0.2-all-languages.tar.gz &&\
	mv phpMyAdmin-5.0.2-all-languages phpmyadmin &&\
	mv phpmyadmin /var/www/html/ &&\
	rm phpMyAdmin-5.0.2-all-languages.tar.gz &&\
	cp -rp /tmp/config.inc.php /var/www/html/phpmyadmin/

# 권한설정
RUN chown -R www-data:www-data /var/www/ &&\
	chmod -R 755 /var/www/

EXPOSE	80 443

CMD 	bash ./tmp/setup.sh