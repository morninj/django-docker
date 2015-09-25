# see https://docs.djangoproject.com/en/1.8/howto/deployment/checklist/
ALLOWED_HOSTS = ['*']
DEBUG = False

# The values below are loaded from environment variables
import os

SECRET_KEY = os.environ['SECRET_KEY']

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.mysql', # Add 'postgresql_psycopg2', 'mysql', 'sqlite3' or 'oracle'.
        'NAME': os.environ['DATABASE_NAME'],                      # Or path to database file if using sqlite3.
        # The following settings are not used with sqlite3:
        'USER': os.environ['DATABASE_USERNAME'],
        'PASSWORD': os.environ['DATABASE_PASSWORD'], # Entered via fab command; leave blank if using SQLite
        'HOST': os.environ['DATABASE_HOST'],                      # Empty for localhost through domain sockets or '127.0.0.1' for localhost through TCP.
        'PORT': '',                      # Set to empty string for default.
    }
}

