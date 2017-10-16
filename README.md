# netbox-docker

[![Build Status](https://travis-ci.org/ninech/netbox-docker.svg?branch=master)](https://travis-ci.org/ninech/netbox-docker)

This repository houses the components needed to build NetBox as a Docker container.
Images built using this code are released to [Docker Hub](https://hub.docker.com/r/ninech/netbox) every night.

### Dependencies

This project depends on:

* [docker/docker-ce] >= 1.13.0
* [docker/compose] >= 1.10.0

## Quickstart

To get NetBox up and running:

```
$ git clone -b master https://github.com/ninech/netbox-docker.git
$ cd netbox-docker
$ docker-compose up -d
```

The application will be available after a few minutes.
Use `docker-compose port nginx 80` to find out where to connect to.

```
$ echo "http://$(docker-compose port nginx 80)/"
http://0.0.0.0:32768/

# Open netbox in your default browser on macOS:
$ open "http://$(docker-compose port nginx 80)/"

# Open netbox in your default browser on (most) linuxes:
$ xdg-open "http://$(docker-compose port nginx 80)/" &>/dev/null &
```

Default credentials:

* Username: **admin**
* Password: **admin**

## Configuration

You can configure the app using environment variables. These are defined in `netbox.env`.

## Rebuilding & Publishing images

`./build.sh` is used to rebuild the Docker image:

```
$ ./build.sh --help
Usage: ./build.sh <branch> [--push]
  branch  The branch or tag to build. Required.
  --push  Pushes built Docker image to docker hub.

You can use the following ENV variables to customize the build:
  BRANCH   The branch to build.
           Also used for tagging the image.
  DOCKER_REPO The Docker registry (i.e. hub.docker.com/r/DOCKER_REPO/netbox)
           Also used for tagging the image.
           Default: ninech
  SRC_REPO Which fork of netbox to use (i.e. github.com/<SRC_REPO>/netbox).
           Default: digitalocean
  URL      Where to fetch the package from.
           Must be a tar.gz file of the source code.
           Default: https://github.com/${SRC_REPO}/netbox/archive/$BRANCH.tar.gz
```

## Tests

To run the bundled test, use the `docker-compose.test.yml` file.

```
$ docker-compose -f docker-compose.test.yml run --rm app
```

## About

This repository is currently maintained and funded by [nine](https://nine.ch).

[![logo of the company 'nine'](https://logo.apps.at-nine.ch/Dmqied_eSaoBMQwk3vVgn4UIgDo=/trim/500x0/logo_claim.png)](https://www.nine.ch)

[docker/docker-ce]: https://github.com/docker/docker-ce
[docker/compose]: https://github.com/docker/compose
