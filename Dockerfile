FROM ubuntu:14.04

# Enable production settings by default; for development, this can be set to 
# `false` in `docker run --env`
ENV DJANGO_PRODUCTION=true

# Enable MySQL root user creation without interactive input
RUN echo 'mysql-server mysql-server/root_password password devrootpass' | debconf-set-selections
RUN echo 'mysql-server mysql-server/root_password_again password devrootpass' | debconf-set-selections

# Install packages
RUN apt-get update && apt-get install -y \
    git \
    libmysqlclient-dev \
    mysql-server \
    nginx \
    python-dev \
    python-mysqldb \
    python-setuptools \
    supervisor \
    vim
RUN easy_install pip

# Configure Django project
ADD . /code
RUN mkdir /djangomedia
RUN mkdir /static
RUN mkdir /logs
RUN mkdir /logs/nginx
RUN mkdir /logs/gunicorn
WORKDIR /code
RUN pip install -r requirements.txt

# Expose ports
# 80 = Nginx
# 8000 = Gunicorn
# 3306 = MySQL
EXPOSE 80 8000 3306

# Create dev database and initialize Django project
WORKDIR /code/django_docker
RUN /etc/init.d/mysql start; mysql -uroot -e "CREATE DATABASE devdb; CREATE USER devuser@localhost; SET PASSWORD FOR devuser@localhost=PASSWORD('devpass'); GRANT ALL PRIVILEGES ON devdb.* TO devuser@localhost IDENTIFIED BY 'devpass'; FLUSH PRIVILEGES;" -pdevrootpass; python manage.py collectstatic --noinput; python manage.py syncdb --noinput; python manage.py migrate --noinput

# Create Django superuser
RUN /etc/init.d/mysql start; export ROOT_PASSWORD=$(cat ../root_password); echo "from django.contrib.auth.models import User; User.objects.create_superuser('root', 'admin@example.com', '$ROOT_PASSWORD')" | python manage.py shell

# Configure Nginx
RUN ln -s /code/nginx.conf /etc/nginx/sites-enabled/django_docker.conf
RUN rm /etc/nginx/sites-enabled/default

# Run Supervisor (i.e., start MySQL, Nginx, and Gunicorn)
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
CMD ["/usr/bin/supervisord"]
