# django-docker

This repo has everything you need to develop and deploy Django projects with Docker. It's being actively developed. If there's an improvement you'd like to see, feel free to add an issue or open a pull request.

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
