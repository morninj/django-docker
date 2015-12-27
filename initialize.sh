#!/bin/bash
# This script initializes the Django project. It will be executed (from 
# supervisord) every time the Docker image is run.

# If we're not in production, create a temporary dev database
if [ "$DJANGO_PRODUCTION" != "true" ]; then
    echo "DJANGO_PRODUCTION=false; creating local database..."
    # Wait until the MySQL daemon is running
    while [ "$(pgrep mysql | wc -l)" -eq 0 ] ; do
        echo "MySQL daemon not running; waiting one second..."
        sleep 1
    done
    # Wait until we can successfully connect to the MySQL daemon
    until mysql -uroot -pdevrootpass -e ";" ; do
        echo "Can't connect to MySQL; waiting one second..."
        sleep 1
    done
    echo "MySQL daemon is running; creating database..."
    mysql -uroot -e "CREATE DATABASE devdb; CREATE USER devuser@localhost; SET PASSWORD FOR devuser@localhost=PASSWORD('devpass'); GRANT ALL PRIVILEGES ON devdb.* TO devuser@localhost IDENTIFIED BY 'devpass'; FLUSH PRIVILEGES;" -pdevrootpass;
else
    echo "DJANGO_PRODUCTION=true; no local database created"        
fi

# Initialize Django project
python /code/django_docker/manage.py collectstatic --noinput
python /code/django_docker/manage.py syncdb --noinput
python /code/django_docker/manage.py makemigrations
python /code/django_docker/manage.py migrate --noinput

# Create a Django superuser named `root` if it doesn't yet exist
echo "Creating Django superuser named 'root'..."
if [ "$DJANGO_PRODUCTION" != "true" ]; then
    # We're in the dev environment
    if [ "$ROOT_PASSWORD" == "" ]; then
        # Root password environment variable is not set; so, load it from config.ini
        echo "from ConfigParser import SafeConfigParser; parser = SafeConfigParser(); parser.read('/code/config.ini'); from django.contrib.auth.models import User; print 'Root user already exists' if User.objects.filter(username='root') else User.objects.create_superuser('root', 'admin@example.com', parser.get('general', 'ROOT_PASSWORD'))" | python /code/django_docker/manage.py shell
    else
        # Root password environment variable IS set; so, use it
        echo "import os; from django.contrib.auth.models import User; print 'Root user already exists' if User.objects.filter(username='root') else User.objects.create_superuser('root', 'admin@example.com', os.environ['ROOT_PASSWORD'])" | python /code/django_docker/manage.py shell
    fi
else
    # We're in production; use root password environment variable
    echo "import os; from django.contrib.auth.models import User; print 'Root user already exists' if User.objects.filter(username='root') else User.objects.create_superuser('root', 'admin@example.com', os.environ['ROOT_PASSWORD'])" | python /code/django_docker/manage.py shell
fi
