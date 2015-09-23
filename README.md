# django-docker

This repo has everything you need to develop and deploy Django projects with Docker. If there's an improvement you'd like to see, feel free to add an issue or open a pull request.

I've tested this configuration on Mac OS X 10.10.3 and Ubuntu 14.04. It should work equally well on other platforms.

## Get started

First, [install Docker](https://docs.docker.com/installation/). If you're new to Docker, you might also want to check out the [Hello, world! tutorial](https://docs.docker.com/userguide/dockerizing/).

Next, clone this repo:

    $ git clone git@github.com:morninj/django-docker.git
    $ cd django-docker

(Mac users should clone it to a directory under `/Users` because of a [Docker bug](https://blog.docker.com/2014/10/docker-1-3-signed-images-process-injection-security-options-mac-shared-directories/) involving Mac shared directories.)

Update the `origin` to point to your own Git repo:

    $ git remote set-url origin https://github.com/user/repo.git

Build the Docker image (you should be in the `django-docker/` directory, which contains the `Dockerfile`):

    $ docker build -t <yourname>/django-docker .

Run the Docker image you just created:

    $ docker run -d -p 80:80 morninj/django-docker

Run `docker ps` to verify that the Docker container is running:

    CONTAINER ID        IMAGE                   COMMAND                  CREATED             STATUS              PORTS                          NAMES
    2830610e8c87        morninj/django-docker   "/usr/bin/supervisord"   25 seconds ago      Up 25 seconds       0.0.0.0:80->80/tcp, 8000/tcp   focused_banach

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
    4. Rebuild the Docker image
    5. Push the Docker image to Docker Hub

Start the Docker container and mount the local directory:

    $ docker run -d -p 80:80 -v $(pwd):/code <yourname>/django-docker

Point your browser to your Docker host's IP address. You should see the "Hello, world!" message again.

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
    CONTAINER ID        IMAGE                   COMMAND                  CREATED             STATUS              PORTS                          NAMES
    39b60b7eb954        morninj/django-docker   "/usr/bin/supervisord"   4 minutes ago       Up 3 minutes        0.0.0.0:80->80/tcp, 8000/tcp   elegant_banach
    $ docker kill 39b60b7eb954

Rebuild the container with the updated code:

    $ docker build -t <yourname>/django-docker .

Push it to Docker Hub:

    $ docker push <yourname>/django-docker

If you want, you can use the Docker Hub web interface to make this image private.

## Deploying

*This configuration isn't ready for production. Right now, data is stored in a local SQLite database. That database will be refreshed each time you update your Docker image. This configuration will be updated soon to store production data on a persistent storage backend (like Amazon RDS or Google Cloud SQL).*

If you don't have a server running yet, start one. An easy and cheap option is the $5/month virtual server from Digital Ocean. They have Ubuntu images with Docker preinstalled.

SSH to the server. Stop any running Docker containers. Then, pull the image you just pushed:

    $ docker pull <yourname>/django-docker

Run the image:

    $ docker run -d -p 80:80 <yourname>/django-docker

Point a browser to your server's IP address. You should see the latest version of the project.
