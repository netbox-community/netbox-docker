# netbox-docker

[![Build Status](https://travis-ci.org/ninech/netbox-docker.svg?branch=master)](https://travis-ci.org/ninech/netbox-docker)

This repository houses the components needed to build NetBox as a Docker container.
Images built using this code are released to [Docker Hub](https://hub.docker.com/r/ninech/netbox) every night.

## Quickstart

To get NetBox up and running:

```
$ git clone -b master https://github.com/ninech/netbox-docker.git
$ cd netbox-docker
$ docker-compose up
```

The application will be available after a few minutes.

In another terminal:

```
# Try the REST API:
$ curl -L http://localhost:8080/api
{"circuits":"http://localhost:8080/api/circuits/","dcim":"http://localhost:8080/api/dcim/","extras":"http://localhost:8080/api/extras/","ipam":"http://localhost:8080/api/ipam/","secrets":"http://localhost:8080/api/secrets/","tenancy":"http://localhost:8080/api/tenancy/"}

# Open netbox in your default browser on macOS:
$ open http://localhost:8080

# Open netbox in your default browser on (most) linuxes:
$ xdg-open http://localhost:8080 &>/dev/null &
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
