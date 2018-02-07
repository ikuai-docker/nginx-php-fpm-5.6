FROM ikuai/php-fpm-5.6

MAINTAINER Dylan <bbcheng@ikuai8.com>

ENV NGINX_CONF_DIR=/etc/nginx

COPY ./supervisord.conf /etc/supervisor/conf.d/
COPY ./app /var/www/app/

RUN buildDeps='software-properties-common python-software-properties' \
	apt-get update \
	&& apt-get install --no-install-recommends -y $buildDeps wget curl \
	&& wget -O - http://nginx.org/keys/nginx_signing.key | apt-key add - \
	&& echo "deb http://nginx.org/packages/ubuntu/ xenial nginx" | tee -a /etc/apt/sources.list \
	&& echo "deb-src http://nginx.org/packages/ubuntu/ xenial nginx" | tee -a /etc/apt/sources.list \
	&& apt-get update \
	&& apt-get install -y nginx \
	&& rm -rf  ${NGINX_CONF_DIR}/sites-enabled/* ${NGINX_CONF_DIR}/sites-available/* \
	# Install supervisor
	&& apt-get install -y supervisor \
	&& mkdir -p /var/log/supervisor \
	&& chown www-data:www-data /var/www/app/ -Rf \
	# Cleaning
	&& apt-get purge -y --auto-remove $buildDeps \
	&& apt-get autoremove -y \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/* \
	# Forward request and error logs to docker log collector
	&& ln -sf /dev/stdout /var/log/nginx/access.log \
	&& ln -sf /dev/stderr /var/log/nginx/error.log

COPY ./configs/nginx.conf ${NGINX_CONF_DIR}/nginx.conf
COPY ./configs/app.conf ${NGINX_CONF_DIR}/sites-enabled/app.conf
COPY ./configs/www.conf /etc/php/5.6/fpm/pool.d/www.conf

WORKDIR /var/www/app/

EXPOSE 80 443

CMD ["/usr/bin/supervisord"]
