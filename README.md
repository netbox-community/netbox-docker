# netbox-docker

[![Build Status](https://travis-ci.org/ninech/netbox-docker.svg?branch=master)](https://travis-ci.org/ninech/netbox-docker)

This repository houses the components needed to build NetBox as a Docker container.
Images built using this code are released to [Docker Hub](https://hub.docker.com/r/ninech/netbox) every night.

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

## Dependencies

This project relies only on *Docker* and *docker-compose* meeting this requirements:

* The *Docker version* must be at least `1.13.0`.
* The *docker-compose version* must be at least `1.10.0`.

To ensure this, compare the output of `docker --version` and `docker-compose --version` with the requirements above.

## Configuration

You can configure the app using environment variables. These are defined in `netbox.env`.

## Version

The `docker-compose.yml` file is prepared to run a specific version of Netbox.
To use this feature, set the environment-variable `VERSION` before launching `docker-compose`, as shown below.
`VERSION` may be set to the name of
[any tag of the `ninech/netbox` Docker image](https://hub.docker.com/r/ninech/netbox/tags/).

```
$ export VERSION=v2.2.1
$ docker-compose pull netbox
$ docker-compose up -d
```

You can also build a specific version of the Netbox image. This time, `VERSION` indicates any valid
[Git Reference](https://git-scm.com/book/en/v2/Git-Internals-Git-References) declared on
[the Netbox Github repository](https://github.com/digitalocean/netbox/releases).
Most commonly you will specify a tag name or a branch name.

```
$ export VERSION=develop
$ docker-compose build --no-cache netbox
$ docker-compose up -d
```

Hint: If you're building a specific version by tag name, the `--no-cache` argument is not strictly necessary.
This can increase the build speed if you're just adjusting the config, for example.

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
