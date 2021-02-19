# netbox-docker

[![GitHub release (latest by date)](https://img.shields.io/github/v/release/netbox-community/netbox-docker)][github-release]
[![GitHub stars](https://img.shields.io/github/stars/netbox-community/netbox-docker)][github-stargazers]
![GitHub closed pull requests](https://img.shields.io/github/issues-pr-closed-raw/netbox-community/netbox-docker)
![Github release workflow](https://img.shields.io/github/workflow/status/netbox-community/netbox-docker/release)
![Docker Pulls](https://img.shields.io/docker/pulls/netboxcommunity/netbox)
[![GitHub license](https://img.shields.io/github/license/netbox-community/netbox-docker)][netbox-docker-license]

[The Github repository](netbox-docker-github) houses the components needed to build NetBox as a Docker container.
Images are built using this code and are released to [Docker Hub][netbox-dockerhub] and [Quay.io][netbox-quayio] once a day.

Do you have any questions?
Before opening an issue on Github, please join the [Network To Code][ntc-slack] Slack and ask for help in our [`#netbox-docker`][netbox-docker-slack] channel.

[github-stargazers]: https://github.com/netbox-community/netbox-docker/stargazers
[github-release]: https://github.com/netbox-community/netbox-docker/releases
[netbox-docker-microbadger]: https://microbadger.com/images/netboxcommunity/netbox
[netbox-dockerhub]: https://hub.docker.com/r/netboxcommunity/netbox/
[netbox-docker-github]: https://github.com/netbox-community/netbox-docker/
[ntc-slack]: http://slack.networktocode.com/
[netbox-docker-slack]: https://slack.com/app_redirect?channel=netbox-docker&team=T09LQ7E9E
[netbox-docker-license]: https://github.com/netbox-community/netbox-docker/blob/release/LICENSE
[netbox-quayio]: https://quay.io/repository/netboxcommunity/netbox

## Docker Tags

* `vX.Y.Z`: These are release builds, automatically built from [the corresponding releases of NetBox][netbox-releases].
* `latest`: These are release builds, automatically built from [the `master` branch of NetBox][netbox-master].
* `snapshot`: These are pre-release builds, automatically built from the [`develop` branch of NetBox][netbox-develop].
* `develop-X.Y`: These are pre-release builds, automatically built from the corresponding [branch of NetBox][netbox-branches].

Then there is currently one extra tags for each of the above tags:

* `-ldap`: Contains additional dependencies and configurations for connecting NetBox to an LDAP directory.
  [Learn more about that in our wiki][netbox-docker-ldap].

New images are built and published automatically every ~24h.

[netbox-releases]: https://github.com/netbox-community/netbox/releases
[netbox-master]: https://github.com/netbox-community/netbox/tree/master
[netbox-develop]: https://github.com/netbox-community/netbox/tree/develop
[netbox-branches]: https://github.com/netbox-community/netbox/branches
[netbox-docker-ldap]: https://github.com/netbox-community/netbox-docker/wiki/LDAP

## Quickstart

To get NetBox Docker up and running run the following commands.
There is a more complete [_Getting Started_ guide on our wiki][wiki-getting-started] which explains every step.

```bash
git clone -b release https://github.com/netbox-community/netbox-docker.git
cd netbox-docker
tee docker-compose.override.yml <<EOF
version: '3.4'
services:
  netbox:
    ports:
      - 8000:8080
EOF
docker-compose pull
docker-compose up
```

The whole application will be available after a few minutes.
Open the URL `http://0.0.0.0:8000/` in a web-browser.
You should see the NetBox homepage.
In the top-right corner you can login.
The default credentials are:

* Username: **admin**
* Password: **admin**
* API Token: **0123456789abcdef0123456789abcdef01234567**

[wiki-getting-started]: https://github.com/netbox-community/netbox-docker/wiki/Getting-Started
[docker-reception]: https://github.com/nxt-engineering/reception

## Documentation

Please refer [to our wiki on Github][netbox-docker-wiki] for further information on how to use this NetBox Docker image properly.
It covers advanced topics such as using files for secrets, deployment to Kubernetes, monitoring and configuring NAPALM or LDAP.

[netbox-docker-wiki]: https://github.com/netbox-community/netbox-docker/wiki/

## Getting Help

Feel free to ask questions in our [Github Community][netbox-community] or join [our Slack channel `#netbox-docker`][netbox-docker-slack] on the [Network To Code Slack][ntc-slack],
which is free to use and where there are almost always people online that can help you in the Slack channel.

If you need help with using NetBox or developing for it or against it's API you may find the `#netbox` channel on the same Slack instance very helpful.

[netbox-community]: https://github.com/netbox-community/netbox-docker/discussions

## Dependencies

This project relies only on *Docker* and *docker-compose* meeting these requirements:

* The *Docker version* must be at least `19.03`.
* The *docker-compose version* must be at least `1.28.0`.

To check the version installed on your system run `docker --version` and `docker-compose --version`.

## Breaking Changes

From time to time it might become necessary to re-engineer the structure of this setup.
Things like the `docker-compose.yml` file or your Kubernetes or OpenShift configurations have to be adjusted as a consequence.

Since November 2019 each image built from this repo contains a `org.opencontainers.image.version` label.
(The images contained labels since April 2018, although in November 2019 the labels' names changed.)
You can check the label of your local image by running `docker inspect netboxcommunity/netbox:v2.7.1 --format "{{json .Config.Labels}}"`.

Please read [the release notes][releases] carefully when updating to a new image version.

[releases]: https://github.com/netbox-community/netbox-docker/releases

## Rebuilding the Image

`./build.sh` can be used to rebuild the Docker image. See `./build.sh --help` for more information.

For more details on custom builds [consult our wiki][netbox-docker-wiki-build].

[netbox-docker-wiki-build]: https://github.com/netbox-community/netbox-docker/wiki/Build

## Tests

We have a test script.
It runs NetBox's own unit tests and ensures that all initializers work:

```bash
IMAGE=netboxcommunity/netbox:latest ./test.sh
```

## About

This repository is currently maintained and funded by [nxt][nxt].

[nxt]: https://nxt.engineering/en/
