# netbox-docker

[The Github repository](netbox-docker-github) houses the components needed to build Netbox as a Docker container.
Images are built using this code and are released to [Docker Hub][netbox-dockerhub] once a day.

Do you have any questions? Before opening an issue on Github, please join the [Network To Code][ntc-slack] Slack and ask for help in our `#netbox-docker` channel.

[netbox-dockerhub]: https://hub.docker.com/r/netboxcommunity/netbox/tags/
[netbox-docker-github]:  https://github.com/netbox-community/netbox-docker/
[ntc-slack]: http://slack.networktocode.com/

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

Default credentials:

* Username: **admin**
* Password: **admin**
* API Token: **0123456789abcdef0123456789abcdef01234567**

[docker-reception]: https://github.com/nxt-engineering/reception

## Dependencies

This project relies only on *Docker* and *docker-compose* meeting this requirements:

* The *Docker version* must be at least `17.05`.
* The *docker-compose version* must be at least `1.17.0`.

To ensure this, compare the output of `docker --version` and `docker-compose --version` with the requirements above.

## Reference Documentation

Please refer [to the wiki][wiki] for further information on how to use this Netbox Docker image properly.
It covers advanced topics such as using secret files, deployment to Kubernetes as well as NAPALM and LDAP configuration.

[wiki]: https://github.com/netbox-community/netbox-docker/wiki/

## Netbox Version

The `docker-compose.yml` file is prepared to run a specific version of Netbox.
To use this feature, set the environment-variable `VERSION` before launching `docker-compose`, as shown below.
`VERSION` may be set to the name of
[any tag of the `netboxcommunity/netbox` Docker image on Docker Hub][netbox-dockerhub].

```bash
export VERSION=v2.6.6
docker-compose pull netbox
docker-compose up -d
```

You can also build a specific version of the Netbox Docker image yourself.
`VERSION` can be any valid [git ref][git-ref] in that case.

```bash
export VERSION=v2.6.6
./build.sh $VERSION
docker-compose up -d
```

[git-ref]: https://git-scm.com/book/en/v2/Git-Internals-Git-References
[netbox-github]: https://github.com/netbox-community/netbox/releases

## Breaking Changes

From time to time it might become necessary to re-engineer the structure of this setup.
Things like the `docker-compose.yml` file or your Kubernetes or OpenShift configurations have to be adjusted as a consequence.
Since April 2018 each image built from this repo contains a `NETBOX_DOCKER_PROJECT_VERSION` label.
You can check the label of your local image by running `docker inspect netboxcommunity/netbox:v2.3.1 --format "{{json .ContainerConfig.Labels}}"`.

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
