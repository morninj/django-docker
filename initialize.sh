#!/bin/bash
# This script initializes the Django project. It will be executed (from 
# supervisord) every time the Docker image is run.

# If we're not in production, create a temporary dev database
if [ "$DJANGO_PRODUCTION" != "true" ]; then
    echo "DJANGO_PRODUCTION=false; creating local database..."
    mysql -uroot -e "CREATE DATABASE devdb; CREATE USER devuser@localhost; SET PASSWORD FOR devuser@localhost=PASSWORD('devpass'); GRANT ALL PRIVILEGES ON devdb.* TO devuser@localhost IDENTIFIED BY 'devpass'; FLUSH PRIVILEGES;" -pdevrootpass;
else
    echo "DJANGO_PRODUCTION=true; no local database created"        
fi

# Initialize Django project
python /code/django_docker/manage.py collectstatic --noinput
python /code/django_docker/manage.py syncdb --noinput
python /code/django_docker/manage.py migrate --noinput

# Create a Django superuser named `root` if it doesn't yet exist
echo "Creating Django superuser named 'root'..."
export ROOT_PASSWORD=$(cat /code/root_password)
echo "from django.contrib.auth.models import User; print 'Root user already exists' if User.objects.filter(username='root') else User.objects.create_superuser('root', 'admin@example.com', '$ROOT_PASSWORD')" | python /code/django_docker/manage.py shell
