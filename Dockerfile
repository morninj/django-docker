FROM ubuntu:14.04
RUN apt-get update -y
RUN apt-get install -y nginx git python-setuptools python-dev vim supervisor
RUN easy_install pip
ADD . /code
RUN mkdir /djangomedia
RUN mkdir /static
RUN mkdir /logs
RUN mkdir /logs/nginx
RUN mkdir /logs/gunicorn
WORKDIR /code
RUN pip install -r requirements.txt
EXPOSE 80 8000
WORKDIR /code/django_docker
RUN python manage.py collectstatic --noinput
RUN python manage.py syncdb --noinput
RUN python manage.py migrate --noinput
RUN ln -s /code/nginx.conf /etc/nginx/sites-enabled/django_docker.conf
RUN rm /etc/nginx/sites-enabled/default
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
CMD ["/usr/bin/supervisord"]
