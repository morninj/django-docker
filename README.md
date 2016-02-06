# django-docker

This is a production-ready setup for running Django on Docker.

## Quick start

    $ cp config.ini.sample config.ini # add your server details here
    $ fab deploy_production

That's it—you now have a fully Dockerized Django project running on a production server. Read below for details on configuring the project and managing the development workflow.

## Installation

First, [install Docker](https://docs.docker.com/installation/). If you're new to Docker, you might also want to check out the [Hello, world! tutorial](https://docs.docker.com/userguide/dockerizing/).

Next, clone this repo:

    $ git clone git@github.com:morninj/django-docker.git
    $ cd django-docker

(Mac users should clone it to a directory under `/Users` because of a [Docker bug](https://blog.docker.com/2014/10/docker-1-3-signed-images-process-injection-security-options-mac-shared-directories/) involving Mac shared directories.)

You can also fork this repo or pull it as  image from Docker Hub as [`morninj/django-docker`](https://hub.docker.com/r/morninj/django-docker/).


Update the `origin` to point to your own Git repo:

    $ git remote set-url origin https://github.com/user/repo.git

## Configure the project

Project settings live in `config.ini`. It contains sensitive data, so it's excluded in `.gitignore` and `.dockerignore`. Copy `config.ini.sample` to `config.ini`:

    $ cp config.ini.sample config.ini

Edit `config.ini`. At a minimum, change these settings:

* `DOCKER_IMAGE_NAME`: change to `<yourname>/some-image-name`.
* `ROOT_PASSWORD`: this is the password for a Django superuser with username `root`. Change it to something secure.

Run `docker ps` to make sure your Docker host is running. If it's not, run:

    $ docker-machine start <dockerhostname>
    $ eval "$(docker-machine env <dockerhostname>)"

Build the Docker image (you should be in the `django-docker/` directory, which contains the `Dockerfile`):

    $ docker build -t <yourname>/django-docker .

Run the Docker image you just created (the command will be explained in the `Development workflow` section below):

    $ docker run -d -p 80:80 -v $(pwd):/code --env DJANGO_PRODUCTION=false <yourname>/django-docker

Run `docker ps` to verify that the Docker container is running:

    CONTAINER ID        IMAGE                      COMMAND                  CREATED             STATUS              PORTS                          NAMES
    2830610e8c87        <yourname>/django-docker   "/usr/bin/supervisord"   25 seconds ago      Up 25 seconds       0.0.0.0:80->80/tcp, 8000/tcp   focused_banach

You should now be able to access the running app through a web browser. Run `docker-machine ls` to get the local IP address for your Docker host:

    NAME           ACTIVE   DRIVER       STATE     URL                         SWARM
    mydockerhost   *        virtualbox   Running   tcp://192.168.99.100:2376

Open `http://192.168.99.100` (or your host's address, if it's different) in a browser. You should see a "Hello, world!" message.

Grab the `CONTAINER ID` from the `docker ps` output above, and use `docker kill` to stop the container:

    $ docker kill 2830610e8c87

The output of `docker ps` should now be empty:

    $ docker ps
    CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS              PORTS               NAMES

## Development workflow

You should be inside the `django-docker` folder, which contains the `Dockerfile` and this README.

Here's the outline of the workflow:

    1. Run the Docker container and mount the local directory containing the Django project code
    2. Make changes and test them on the container
    3. Commit the changes to the Git repo

Start the Docker container:

    $ docker run -d -p 80:80 -v $(pwd):/code --env DJANGO_PRODUCTION=false <yourname>/django-docker

Here's what the flags do:

* `-d`: Run in detached mode (i.e., Docker will no longer listen to the console where you ran `docker run`).
* `-p 80:80`: Map port 80 on the host to port 80 on the container. This lets you communicate with Nginx from your browser.
* `-v $(pwd):/code`: Mount the current directory as a volume at `/code` on the Docker container. This lets you edit the code while the container is running so you can test it without having to rebuild the image.
* `--env DJANGO_PRODUCTION=false`: Production settings are enabled by default in `settings.py` and defined in `settings_production.py`. This flag prevents `settings_production.py` from being loaded, which lets you have separate settings for local development (e.g., `DEBUG = True` and a local development database).

Point your browser to your Docker host's IP address. You should see the "Hello, world!" message again.

Point your browser to `http://<ip address>/admin/`. You should be able to log in with username `root` and the root password you set in `config.ini`. 

In your editor of choice, open `django_docker/hello_world/templates/hello_world/index.html`. It looks like this:

    {% extends 'base.html' %}

    {% load staticfiles %}

    {% block content %}
    <p class="hello-world">Hello, world!</p>
    {% endblock content %} 

Edit the `<p>` tag to read `Hello again, world!` and save the file. Refresh the page in your browser and you should see the updated message.

Next, commit this change to your repo and push it:

    $ git commit -am 'Add "Hello again, world!"'
    $ git push origin master

Run `docker ps` to get the `CONTAINER ID` and use `docker kill` to stop the container:

    $ docker ps
    CONTAINER ID        IMAGE                      COMMAND                  CREATED             STATUS              PORTS                          NAMES
    39b60b7eb954        <yourname>/django-docker   "/usr/bin/supervisord"   4 minutes ago       Up 3 minutes        0.0.0.0:80->80/tcp, 8000/tcp   elegant_banach
    $ docker kill 39b60b7eb954

### Editing files

Unlike the Django development server, this configuration won't automatically detect and load changes in Python files. You'll have to manually refresh the server when you make changes (except for templates, which will automatically update). First, open a shell on the dev server:

    $ docker exec -ti <CONTAINER ID> /bin/bash

Then, each time you change a Python file, run:

    $ supervisorctl restart gunicorn

### Updating models

When you update your models, `django-docker` will automatically run `python manage.py makemigrations` and  `python manage.py migrate` the next time you run the Docker image. There are a few caveats:

- Don't delete the `migrations/` folders inside your apps (or else you'll have to do something like editing `initialize.sh` to add `migrate --fake-initial`—ugh)
- When adding new model fields, remember to set a `default` (or else `migrate` will fail)

Still, there will be times when you need to create migrations by hand. Django currently doesn't support fully automated migration creation—for instance, you might get a prompt like this:

    Did you rename job.cost to job.paid (a IntegerField)? [y/N]

As far as I know, this can't be automated. To handle this scenario, open a shell on your development Docker machine:

    $ docker run -ti -p 80:80 -v $(pwd):/code --env DJANGO_PRODUCTION=false <yourname>/django-docker /bin/bash

Then, start the database server and invoke `initialize.sh`:

    $ /etc/init.d/mysql start
    $ ./initialize.sh

This will call `python manage.py makemigrations` and prompt you if necessary. It will create the necessary migration files. The migration will be automatically applied the next time you run the Docker image in production. (This can be scary. Make a clean backup of your code and database _before_ applying the migration in production in case you need to roll back.)

## Deployment

If you don't have a server running yet, start one. An easy and cheap option is the $5/month virtual server from Digital Ocean. They have Ubuntu images with Docker preinstalled.

You'll also need a separate database server. Two good options are Google Cloud SQL and Amazon RDS. Be sure to create a database named `django` (or anything else, as long as it matches `DATABASE_NAME` in `config.ini`). Also make sure to create a database user that can access this database. Finally, make sure that the production server is authorized to access the database server. (An easy way to verify all of this is to SSH to the production server and run `mysql -h <db server ip address> -uroot -p` and then `mysql> CREATE DATABASE django;`.)

`config.ini` contains settings for production (e.g., the web server's IP address and the database details). Edit these values now.

If you want to enable additional production settings, you can add them to `django_docker/django_docker/settings_production.py`.

The project can be deployed with a single Fabric command. Make sure Fabric is installed (do `pip install fabric`), and then run:

    $ fab deploy_production

This builds the Docker image, pushes it to Docker Hub, pulls it on the production server, and starts a container with the production settings.

Verify that your production settings (not the development settings!) are active. Navigate to `http://<ip address>/spamalot`. You should see the basic Nginx "not found" page. If you see the full Django error page, that means that `DEBUG = True`, which probably means that your production settings are not loaded.
