from fabric.api import *
from fabric.contrib.files import *
import os
from ConfigParser import SafeConfigParser
parser = SafeConfigParser()
parser.read(os.path.join(os.path.dirname(__file__), 'config.ini'))
import time

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
    print 'Removing dangling Docker images...'
    run('if [ -z "$(docker images -f "dangling=true" -q)" ]; then echo "no images to remove";  else docker rmi $(docker images -f "dangling=true" -q); fi')
    print 'Pulling image on production host...'
    run('docker pull %s ' % parser.get('general', 'DOCKER_IMAGE_NAME'));
    print 'Running image on production host...'
    run_command = '''docker run \
    -d \
    -p 80:80 \
    --env DJANGO_PRODUCTION=true \
    --env ROOT_PASSWORD={ROOT_PASSWORD} \
    --env DATABASE_HOST={DATABASE_HOST} \
    --env DATABASE_USERNAME={DATABASE_USERNAME} \
    --env DATABASE_PASSWORD={DATABASE_PASSWORD} \
    --env DATABASE_NAME={DATABASE_NAME} \
    --env SECRET_KEY={SECRET_KEY} \
    {DOCKER_IMAGE_NAME}'''.format(
        ROOT_PASSWORD=parser.get('general', 'ROOT_PASSWORD'),
        DOCKER_IMAGE_NAME=parser.get('general', 'DOCKER_IMAGE_NAME'),
        DATABASE_HOST=parser.get('production', 'DATABASE_HOST'),
        DATABASE_USERNAME=parser.get('production', 'DATABASE_USERNAME'),
        DATABASE_PASSWORD=parser.get('production', 'DATABASE_PASSWORD'),
        DATABASE_NAME=parser.get('production', 'DATABASE_NAME'),
        SECRET_KEY=parser.get('production', 'SECRET_KEY'),
    )
    run(run_command);
    print '-' * 80
    print parser.get('general', 'DOCKER_IMAGE_NAME') + ' successfully deployed to ' + parser.get('production', 'HOST')
    print("Deployment time: %s seconds" % (time.time() - start_time))
