# netbox-docker

[![GitHub release (latest by date)](https://img.shields.io/github/v/release/netbox-community/netbox-docker)][github-release]
[![GitHub stars](https://img.shields.io/github/stars/netbox-community/netbox-docker)][github-stargazers]
![GitHub closed pull requests](https://img.shields.io/github/issues-pr-closed-raw/netbox-community/netbox-docker)
![Docker Cloud Build Status](https://img.shields.io/docker/cloud/build/netboxcommunity/netbox)
![Docker Pulls](https://img.shields.io/docker/pulls/netboxcommunity/netbox)
[![MicroBadger Layers](https://img.shields.io/microbadger/layers/netboxcommunity/netbox)][netbox-docker-microbadger]
[![MicroBadger Size](https://img.shields.io/microbadger/image-size/netboxcommunity/netbox)][netbox-docker-microbadger]
[![GitHub license](https://img.shields.io/github/license/netbox-community/netbox-docker)][netbox-docker-license]

[The Github repository](netbox-docker-github) houses the components needed to build Netbox as a Docker container.
Images are built using this code and are released to [Docker Hub][netbox-dockerhub] once a day.

Do you have any questions? Before opening an issue on Github, please join the [Network To Code][ntc-slack] Slack and ask for help in our [`#netbox-docker`][netbox-docker-slack] channel.

[github-stargazers]: https://github.com/netbox-community/netbox-docker/stargazers
[github-release]: https://github.com/netbox-community/netbox-docker/releases
[netbox-docker-microbadger]: https://microbadger.com/images/netboxcommunity/netbox
[netbox-dockerhub]: https://hub.docker.com/r/netboxcommunity/netbox/tags/
[netbox-docker-github]: https://github.com/netbox-community/netbox-docker/
[ntc-slack]: http://slack.networktocode.com/
[netbox-docker-slack]: https://slack.com/app_redirect?channel=netbox-docker&team=T09LQ7E9E
[netbox-docker-license]: https://github.com/netbox-community/netbox-docker/blob/master/LICENSE

## Docker Tags

* `vX.Y.Z`: Release builds, built from [releases of Netbox][netbox-releases].
* `latest`: Release builds, built from [`master` branch of Netbox][netbox-master].
* `snapshot`: Pre-release builds, built from the [`develop` branch of Netbox][netbox-develop].
* `develop-X.Y`: Pre-release builds, built from the corresponding [branch of Netbox][netbox-branches].

Then there is currently one extra tags for each of the above labels:

* `-ldap`: Contains additional dependencies and configurations for connecting Netbox to an LDAP directroy.
  [Learn more about that in our wiki][netbox-docker-ldap].

[netbox-releases]: https://github.com/netbox-community/netbox/releases
[netbox-master]: https://github.com/netbox-community/netbox/tree/master
[netbox-develop]: https://github.com/netbox-community/netbox/tree/develop
[netbox-branches]: https://github.com/netbox-community/netbox/branches
[netbox-docker-ldap]: https://github.com/netbox-community/netbox-docker/wiki/LDAP

## Quickstart

To get Netbox up and running:

```bash
git clone -b master https://github.com/netbox-community/netbox-docker.git
cd netbox-docker
docker-compose pull
docker-compose up -d
```

The application will be available after a few minutes.
Use `docker-compose port nginx 8080` to find out where to connect to.

```bash
$ echo "http://$(docker-compose port nginx 8080)/"
http://0.0.0.0:32768/

# Open netbox in your default browser on macOS:
$ open "http://$(docker-compose port nginx 8080)/"

# Open netbox in your default browser on (most) linuxes:
$ xdg-open "http://$(docker-compose port nginx 8080)/" &>/dev/null &
```

Alternatively, use something like [Reception][docker-reception] to connect to _docker-compose_ projects.

The default credentials are:

* Username: **admin**
* Password: **admin**
* API Token: **0123456789abcdef0123456789abcdef01234567**

There is a more complete [Getting Started guide on our Wiki][wiki-getting-started].

[wiki-getting-started]: https://github.com/netbox-community/netbox-docker/wiki/Getting-Started
[docker-reception]: https://github.com/nxt-engineering/reception

## Dependencies

This project relies only on *Docker* and *docker-compose* meeting these requirements:

* The *Docker version* must be at least `17.05`.
* The *docker-compose version* must be at least `1.17.0`.

To check the version installed on your system run `docker --version` and `docker-compose --version`.

## Documentation

Please refer [to our wiki on Github][netbox-docker-wiki] for further information on how to use this Netbox Docker image properly.
It covers advanced topics such as using secret files, deployment to Kubernetes as well as NAPALM and LDAP configuration.

[netbox-docker-wiki]: https://github.com/netbox-community/netbox-docker/wiki/

## Netbox Version

The `docker-compose.yml` file is prepared to run a specific version of Netbox.
To use this feature, set the environment-variable `VERSION` before launching `docker-compose`, as shown below.
`VERSION` may be set to the name of
[any tag of the `netboxcommunity/netbox` Docker image on Docker Hub][netbox-dockerhub].

```bash
export VERSION=v2.6.7
docker-compose pull netbox
docker-compose up -d
```

You can also build a specific version of the Netbox Docker image yourself.
`VERSION` can be any valid [git ref][git-ref] in that case.

```bash
export VERSION=v2.6.7
./build.sh $VERSION
docker-compose up -d
```

[git-ref]: https://git-scm.com/book/en/v2/Git-Internals-Git-References
[netbox-github]: https://github.com/netbox-community/netbox/releases

## Breaking Changes

From time to time it might become necessary to re-engineer the structure of this setup.
Things like the `docker-compose.yml` file or your Kubernetes or OpenShift configurations have to be adjusted as a consequence.
Since November 2019 each image built from this repo contains a `org.opencontainers.image.version` label.
(The images contained labels since April 2018, although in November 2019 the labels' names changed.)
You can check the label of your local image by running `docker inspect netboxcommunity/netbox:v2.6.7 --format "{{json .ContainerConfig.Labels}}"`.

Please read [the release notes][releases] carefully when updating to a new image version.

[releases]: https://github.com/netbox-community/netbox-docker/releases

## Rebuilding & Publishing images

`./build.sh` can be used to rebuild the Docker image. See `./build.sh --help` for more information.

### Publishing Docker Images

New Docker images are built and published every 24h on the [Docker Build Infrastructure][docker-build-infra].
`DOCKER_HUB.md` contains more information about the build infrastructure.

[docker-build-infra]: https://hub.docker.com/r/netboxcommunity/netbox/builds/

## Tests

To run the tests coming with Netbox, use the `docker-compose.yml` file as such:

```bash
docker-compose run netbox ./manage.py test
```

## About

This repository is currently maintained and funded by [nxt][nxt].

[nxt]: https://nxt.engineering/en/
