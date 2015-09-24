# see https://docs.djangoproject.com/en/1.8/howto/deployment/checklist/
ALLOWED_HOSTS = ['*']
DEBUG = False

# The values below are loaded from production_secrets.ini
from ConfigParser import SafeConfigParser
import os
parser = SafeConfigParser()
parser.read(os.path.join(os.path.dirname(__file__), 'production_secrets.ini'))
SECRET_KEY = parser.get('general', 'SECRET_KEY')

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.mysql', # Add 'postgresql_psycopg2', 'mysql', 'sqlite3' or 'oracle'.
        'NAME': 'django',                      # Or path to database file if using sqlite3.
        # The following settings are not used with sqlite3:
        'USER': 'root',
        'PASSWORD': 'root', # Entered via fab command; leave blank if using SQLite
        'HOST': '173.194.81.164',                      # Empty for localhost through domain sockets or '127.0.0.1' for localhost through TCP.
        'PORT': '',                      # Set to empty string for default.
    }
}

