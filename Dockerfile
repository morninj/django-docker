FROM ubuntu:14.04

ENV DJANGO_PRODUCTION=true

RUN apt-get update -y

RUN echo 'mysql-server mysql-server/root_password password devrootpass' | debconf-set-selections
RUN echo 'mysql-server mysql-server/root_password_again password devrootpass' | debconf-set-selections

RUN apt-get install -y nginx git python-setuptools python-dev vim supervisor python-mysqldb libmysqlclient-dev mysql-server
RUN easy_install pip
ADD . /code
RUN mkdir /djangomedia
RUN mkdir /static
RUN mkdir /logs
RUN mkdir /logs/nginx
RUN mkdir /logs/gunicorn
WORKDIR /code
RUN pip install -r requirements.txt
EXPOSE 80 8000 3306
WORKDIR /code/django_docker
RUN /etc/init.d/mysql start; mysql -uroot -e "CREATE DATABASE devdb; CREATE USER devuser@localhost; SET PASSWORD FOR devuser@localhost=PASSWORD('devpass'); GRANT ALL PRIVILEGES ON devdb.* TO devuser@localhost IDENTIFIED BY 'devpass'; FLUSH PRIVILEGES;" -pdevrootpass; python manage.py collectstatic --noinput; python manage.py syncdb --noinput; python manage.py migrate --noinput
RUN ln -s /code/nginx.conf /etc/nginx/sites-enabled/django_docker.conf
RUN rm /etc/nginx/sites-enabled/default
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
CMD ["/usr/bin/supervisord"]
