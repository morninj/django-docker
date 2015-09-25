from fabric.api import *
from fabric.contrib.files import *
import os
from ConfigParser import SafeConfigParser
parser = SafeConfigParser()
parser.read(os.path.join(os.path.dirname(__file__), 'config.ini'))
import time

SECRET_KEY = parser.get('general', 'SECRET_KEY')

# Configure server admin login credentials
if parser.get('production', 'USE_PASSWORD'):
    env.password = parser.get('production', 'PASSWORD')
else:
    env.key_filename = parser.get('production', 'PUBLIC_KEY')

# Deploy production server
@hosts(parser.get('production', 'USERNAME') + '@' + parser.get('production', 'HOST'))
def deploy_production():
    start_time = time.time();
    print 'Building Docker image...'
    local('docker build -t %s .' % parser.get('general', 'DOCKER_IMAGE_NAME'))
    print 'Pushing image to Docker Hub...'
    local('docker push %s' % parser.get('general', 'DOCKER_IMAGE_NAME'))
    print 'Removing any existing Docker containers on the production host...'
    run('if [ "$(docker ps -qa)" != "" ]; then docker rm --force `docker ps -qa`; fi')
    run('docker ps')
    print 'Pulling image on production host...'
    run('docker pull %s ' % parser.get('general', 'DOCKER_IMAGE_NAME'));
    print 'Running image on production host...'
    # TODO below: set DJANGO_PRODUCTION=true
    run_command = '''docker run \
    -d \
    -p 80:80 \
    --env DJANGO_PRODUCTION=false \
    --env ROOT_PASSWORD={ROOT_PASSWORD} \
    {DOCKER_IMAGE_NAME}'''.format(
        ROOT_PASSWORD=parser.get('general', 'ROOT_PASSWORD'),
        DOCKER_IMAGE_NAME=parser.get('general', 'DOCKER_IMAGE_NAME'),
    )
    run(run_command); # TODO define env variables in config.ini; set them here; and then grab them in settings_production.py
    print '-' * 80
    print parser.get('general', 'DOCKER_IMAGE_NAME') + ' successfully deployed to ' + parser.get('production', 'HOST')
    print("Deployment time: %s seconds" % (time.time() - start_time))
