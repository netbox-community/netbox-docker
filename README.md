# netbox-docker

[The Github repository](netbox-docker-github) houses the components needed to build Netbox as a Docker container.
Images are built using this code are released to [Docker Hub][netbox-dockerhub] every night.

Questions? Before opening an issue on Github, please join the [Network To Code][ntc-slack] Slack and ask for help in our `#netbox-docker` channel.

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

* The *Docker version* must be at least `1.13.0`.
* The *docker-compose version* must be at least `1.10.0`.

To ensure this, compare the output of `docker --version` and `docker-compose --version` with the requirements above.

## Configuration

You can configure the app using environment variables.
These are defined in `netbox.env`.
Read [Environment Variables in Compose][compose-env] to understand about the various possibilities to overwrite these variables.
(The easiest solution being simply adjusting that file.)

To find all possible variables, have a look at the [configuration.py][docker-config] and [docker-entrypoint.sh][entrypoint] files.
Generally, the environment variables are called the same as their respective Netbox configuration variables.
Variables which are arrays are usually composed by putting all the values into the same environment variables with the values separated by a whitespace ("` `").
For example defining `ALLOWED_HOSTS=localhost ::1 127.0.0.1` would allows access to Netbox through `http://localhost:8080`, `http://[::1]:8080` and `http://127.0.0.1:8080`.

[compose-env]: https://docs.docker.com/compose/environment-variables/

### Production

The default settings are optimized for (local) development environments.
You should therefore adjust the configuration for production setups, at least the following variables:

* `ALLOWED_HOSTS`: Add all URLs that lead to your Netbox instance, space separated. E.g. `ALLOWED_HOSTS=netbox.mycorp.com server042.mycorp.com 2a02:123::42 10.0.0.42 localhost ::1 127.0.0.1` (It's good advice to always allow localhost connections for easy debugging, i.e. `localhost ::1 127.0.0.1`.)
* `DB_*`: Use your own persistent database. Don't use the default passwords!
* `EMAIL_*`: Use your own mailserver.
* `MAX_PAGE_SIZE`: Use the recommended default of 1000.
* `SUPERUSER_*`: Only define those variables during the initial setup, and drop them once the DB is set up. Don't use the default passwords!
* `REDIS_*`: Use your own persistent redis. Don't use the default passwords!

### Running on Docker Swarm / Kubernetes / OpenShift

You may run this image in a cluster such as Docker Swarm, Kubernetes or OpenShift, but this is advanced level.

In this case, we encourage you to statically configure Netbox by starting from [Netbox's example config file][default-config], and mounting it into your container in the directory `/etc/netbox/config/` using the mechanism provided by your container platform (i.e. [Docker Swarm configs][swarm-config], [Kubernetes ConfigMap][k8s-config], [OpenShift ConfigMaps][openshift-config]).

But if you rather continue to configure your application through environment variables, you may continue to use [the built-in configuration file][docker-config].
We discourage storing secrets in environment variables, as environment variable are passed on to all sub-processes and may leak easily into other systems, e.g. error collecting tools that often collect all environment variables whenever an error occurs.

Therefore we *strongly advise* to make use of the secrets mechanism provided by your container platform (i.e. [Docker Swarm secrets][swarm-secrets], [Kubernetes secrets][k8s-secrets], [OpenShift secrets][openshift-secrets]).
[The configuration file][docker-config] and [the entrypoint script][entrypoint] try to load the following secrets from the respective files.
If a secret is defined by an environment variable and in the respective file at the same time, then the value from the environment variable is used.

* `SUPERUSER_PASSWORD`: `/run/secrets/superuser_password`
* `SUPERUSER_API_TOKEN`: `/run/secrets/superuser_api_token`
* `DB_PASSWORD`: `/run/secrets/db_password`
* `SECRET_KEY`: `/run/secrets/secret_key`
* `EMAIL_PASSWORD`: `/run/secrets/email_password`
* `NAPALM_PASSWORD`: `/run/secrets/napalm_password`
* `REDIS_PASSWORD`: `/run/secrets/redis_password`
* `AUTH_LDAP_BIND_PASSWORD`: `/run/secrets/auth_ldap_bind_password`

Please also consider [the advice about running Netbox in production](#production) above!

[docker-config]: https://github.com/netbox-community/netbox-docker/blob/master/configuration/configuration.py
[default-config]: https://github.com/netbox-community/netbox/blob/develop/netbox/netbox/configuration.example.py
[entrypoint]: https://github.com/netbox-community/netbox-docker/blob/master/docker/docker-entrypoint.sh
[swarm-config]: https://docs.docker.com/engine/swarm/configs/
[swarm-secrets]: https://docs.docker.com/engine/swarm/secrets/
[openshift-config]: https://docs.openshift.org/latest/dev_guide/configmaps.html
[openshift-secrets]: https://docs.openshift.org/latest/dev_guide/secrets.html
[k8s-secrets]: https://kubernetes.io/docs/concepts/configuration/secret/
[k8s-config]: https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/

### NAPALM Configuration

Since v2.1.0 NAPALM has been tightly integrated into Netbox.
NAPALM allows Netbox to fetch live data from devices and return it to a requester via its REST API.
To learn more about what NAPALM is and how it works, please see the documentation from the [libary itself][napalm-doc] or the documentation from [Netbox][netbox-napalm-doc] on how it is integrated.

To enable this functionality, simply complete the following lines in `netbox.env` (or appropriate secrets mechanism) :

* `NAPALM_USERNAME`: A common username that can be utilized for connecting to network devices in your environment.
* `NAPALM_PASSWORD`: The password to use in combintation with the username to connect to network devices.
* `NAPALM_TIMEOUT`: A value to use for when an attempt to connect to a device will timeout if no response has been recieved.

However, if you don't need this functionality, leave these blank.

[napalm-doc]: http://napalm.readthedocs.io/en/latest/index.html
[netbox-napalm-doc]: https://netbox.readthedocs.io/en/latest/configuration/optional-settings/#napalm_username

### Customizable Reporting

Netbox includes [customized reporting][netbox-reports-doc] that allows the user to write Python code and determine the validity of the data within Netbox.
The `REPORTS_ROOT` variable is setup as a mapped directory within this Docker container to `/reports/` and includes the example directly from the documentation for `devices.py`.
However, it has been renamed to `devices.py.example` which prevents Netbox from recognizing it as a valid report.
This was done to avoid unnessary issues from being opened when the default does not work for someone's expectations.

To re-enable this default report, simply rename `devices.py.example` to `devices.py` and browse within the WebUI to `/extras/reports/`.
You can also dynamically add any other report to this same directory and Netbox will be able to see it without restarting the container.

[netbox-reports-doc]: https://netbox.readthedocs.io/en/stable/additional-features/reports/

### Custom Initialization Code (e.g. Automatically Setting Up Custom Fields)

When using `docker-compose`, all the python scripts present in `/opt/netbox/startup_scripts` will automatically be executed after the application boots in the context of `./manage.py`.
The execution of the startup scripts can be prevented by setting the environment variable `SKIP_STARTUP_SCRIPTS` to `true`, e.g. in the file `env/netbox.env`.

That mechanism can be used for many things, e.g. to create Netbox custom fields:

```python
# docker/startup_scripts/load_custom_fields.py
from django.contrib.contenttypes.models import ContentType
from extras.models import CF_TYPE_TEXT, CustomField

from dcim.models import Device
from dcim.models import DeviceType

device      = ContentType.objects.get_for_model(Device)
device_type = ContentType.objects.get_for_model(DeviceType)

my_custom_field, created = CustomField.objects.get_or_create(
    type=CF_TYPE_TEXT,
    name='my_custom_field',
    description='My own custom field'
)

if created:
  my_custom_field.obj_type.add(device)
  my_custom_field.obj_type.add(device_type)
```

#### Initializers

Initializers are built-in startup scripts for defining Netbox custom fields, groups, users and many other resources.
All you need to do is to mount you own `initializers` folder ([see `docker-compose.yml`][netbox-docker-compose]).
Look at the [`initializers` folder][netbox-docker-initializers] to learn how the files must look like.

Here's an example for defining a custom field:

```yaml
# initializers/custom_fields.yml
text_field:
  type: text
  label: Custom Text
  description: Enter text in a text field.
  required: false
  filter_logic: loose
  weight: 0
  on_objects:
  - dcim.models.Device
  - dcim.models.Rack
  - ipam.models.IPAddress
  - ipam.models.Prefix
  - tenancy.models.Tenant
  - virtualization.models.VirtualMachine
```

[netbox-docker-initializers]: https://github.com/netbox-community/netbox-docker/tree/master/initializers
[netbox-docker-compose]: https://github.com/netbox-community/netbox-docker/blob/master/docker-compose.yml

##### Available Groups for User/Group initializers

To get an up-to-date list about all the available permissions, run the following command.

```bash
# Make sure the 'netbox' container is already running! If unsure, run `docker-compose up -d`
echo "from django.contrib.auth.models import Permission\nfor p in Permission.objects.all():\n  print(p.codename);" | docker-compose exec -T netbox ./manage.py shell
```

#### Custom Docker Image

You can also build your own Netbox Docker image containing your own startup scripts, custom fields, users and groups
like this:

```Dockerfile
ARG VERSION=latest
FROM netboxcommunity/netbox:$VERSION

COPY startup_scripts/ /opt/netbox/startup_scripts/
COPY initializers/ /opt/netbox/initializers/
```

## Netbox Version

The `docker-compose.yml` file is prepared to run a specific version of Netbox.
To use this feature, set the environment-variable `VERSION` before launching `docker-compose`, as shown below.
`VERSION` may be set to the name of
[any tag of the `netboxcommunity/netbox` Docker image on Docker Hub][netbox-dockerhub].

```bash
export VERSION=v2.2.6
docker-compose pull netbox
docker-compose up -d
```

You can also build a specific version of the Netbox image. This time, `VERSION` indicates any valid
[Git Reference][git-ref] declared on [the 'netbox-community/netbox' Github repository][netbox-github].
Most commonly you will specify a tag or branch name.

```bash
export VERSION=develop
docker-compose build --no-cache netbox
docker-compose up -d
```

Hint: If you're building a specific version by tag name, the `--no-cache` argument is not strictly necessary.
This can increase the build speed if you're just adjusting the config, for example.

[git-ref]: https://git-scm.com/book/en/v2/Git-Internals-Git-References
[netbox-github]: https://github.com/netbox-community/netbox/releases

### LDAP enabled variant

The images tagged with "-ldap" contain anything necessary to authenticate against an LDAP or Active Directory server.
The default configuration `ldap_config.py` is prepared for use with an Active Directory server.
Custom values can be injected using environment variables, similar to the main configuration mechanisms.

## Troubleshooting

This section is a collection of some common issues and how to resolve them.
If your issue is not here, look through [the existing issues][issues] and eventually create a new issue.

[issues]: (https://github.com/netbox-community/netbox-docker/issues)

### Docker Compose basics

* You can see all running containers belonging to this project using `docker-compose ps`.
* You can see the logs by running `docker-compose logs -f`.
  Running `docker-compose logs -f netbox` will just show the logs for netbox.
* You can stop everything using `docker-compose stop`.
* You can clean up everything using `docker-compose down -v --remove-orphans`. **This will also remove any related data.**
* You can enter the shell of the running Netbox container using `docker-compose exec netbox /bin/bash`. Now you have access to `./manage.py`, e.g. to reset a password.
* To access the database run `docker-compose exec postgres sh -c 'psql -U $POSTGRES_USER $POSTGRES_DB'`
* To create a database backup run `docker-compose exec postgres sh -c 'pg_dump -cU $POSTGRES_USER $POSTGRES_DB' | gzip > db_dump.sql.gz`
* To restore that database backup run `gunzip -c db_dump.sql.gz | docker exec -i $(docker-compose ps -q postgres) sh -c 'psql -U $POSTGRES_USER $POSTGRES_DB'`.

### Nginx doesn't start

As a first step, stop your docker-compose setup.
Then locate the `netbox-nginx-config` volume and remove it:

```bash
# Stop your local netbox-docker installation
$ docker-compose down

# Find the volume
$ docker volume ls | grep netbox-nginx-config
local               netbox-docker_netbox-nginx-config

# Remove the volume
$ docker volume rm netbox-docker_netbox-nginx-config
netbox-docker_netbox-nginx-config
```

Now start everything up again.

If this didn't help, try to see if there's anything in the logs indicating why nginx doesn't start:

```bash
docker-compose logs -f nginx
```

### Getting a "Bad Request (400)"

> When connecting to the Netbox instance, I get a "Bad Request (400)" error.

This usually happens when the `ALLOWED_HOSTS` variable is not set correctly.

### How to upgrade

> How do I update to a newer version of netbox?

It should be sufficient to pull the latest image from Docker Hub, stopping the container and starting it up again:

```bash
docker-compose pull netbox
docker-compose stop netbox netbox-worker
docker-compose rm -f netbox netbox-worker
docker-compose up -d netbox netbox-worker
```

### Webhooks don't work

First make sure that the webhooks feature is enabled in your Netbox configuration and that a redis host is defined.
Check `netbox.env` if the following variables are defined:

```bash
WEBHOOKS_ENABLED=true
REDIS_HOST=redis
```

Then make sure that the `redis` container and at least one `netbox-worker` are running.

```bash
# check the container status
$ docker-compose ps

Name                           Command               State                Ports
--------------------------------------------------------------------------------------------------------
netbox-docker_netbox-worker_1   /opt/netbox/docker-entrypo ...   Up
netbox-docker_netbox_1          /opt/netbox/docker-entrypo ...   Up
netbox-docker_nginx_1           nginx -c /etc/netbox-nginx ...   Up      80/tcp, 0.0.0.0:32776->8080/tcp
netbox-docker_postgres_1        docker-entrypoint.sh postgres    Up      5432/tcp
netbox-docker_redis_1           docker-entrypoint.sh redis ...   Up      6379/tcp

# connect to redis and send PING command:
$ docker-compose run --rm -T redis sh -c 'redis-cli -h redis -a $REDIS_PASSWORD ping'
Warning: Using a password with '-a' option on the command line interface may not be safe.
PONG
```

If `redis` and the `netbox-worker` are not available, make sure you have updated your `docker-compose.yml` file!

Everything's up and running? Then check the log of `netbox-worker` and/or `redis`:

```bash
docker-compose logs -f netbox-worker
docker-compose logs -f redis
```

Still no clue? You can connect to the `redis` container and have it report any command that is currently executed on the server:

```bash
docker-compose run --rm -T redis sh -c 'redis-cli -h redis -a $REDIS_PASSWORD monitor'

# Hit CTRL-C a few times to leave
```

If you don't see anything happening after you triggered a webhook, double-check the configuration of the `netbox` and the `netbox-worker` containers and also check the configuration of your webhook in the admin interface of Netbox.

## Breaking Changes

From time to time it might become necessary to re-engineer the structure of this setup.
Things like the `docker-compose.yml` file or your Kubernetes or OpenShift configurations have to be adjusted as a consequence.
Since April 2018 each image built from this repo contains a `NETBOX_DOCKER_PROJECT_VERSION` label.
You can check the label of your local image by running `docker inspect netboxcommunity/netbox:v2.3.1 --format "{{json .ContainerConfig.Labels}}"`.
Compare the version with the list below to check whether a breaking change was introduced with that version.

The following is a list of breaking changes of the `netbox-docker` project:

* 0.17.0: Updated the python image to `python:3.7-alpine3.10` in [#144][144]. Fixed the permissions and group scripts for Netbox 2.6. in [#148][148].
* 0.16.0: Update the Netbox URL from "github.com/digitalocean/netbox" to "github.com/netbox-community/netbox"
* 0.15.0: Update for Netbox v2.6.0.
  The `configuration/configuration.py` file has been updated to match the file from Netbox.
  `CORS_ORIGIN_WHITELIST` has a new default value of `http://localhost`.
  To provide a nice development environment, `CORS_ORIGIN_ALLOW_ALL` added to `env/netbox.env` with a default value of `True`.
  There are also new options:
  * `REDIS_CACHE_DATABASE`
  * `CACHE_TIMEOUT` (set to 0 to disable caching)
  * `CHANGELOG_RETENTION`
  * `CORS_ORIGIN_REGEX_WHITELIST` (space separated list of regular expressions)
  * `EXEMPT_VIEW_PERMISSIONS` (space separated list)
  * `METRICS_ENABLED`
* 0.14.0: Improved caching strategy [#137][137] [#136][136].
  New `AUTH_LDAP_GROUP_TYPE` environment variable [#135][135].
* 0.13.0: `AUTH_LDAP_BIND_PASSWORD` can now be extracted into a secrets file. [#133][133]
* 0.12.0: A new flag `REDIS_SSL=false` was added to the `env/netbox.env` file. [#129][129]
* 0.11.0: The docker-compose file now marks volumes as shared (`:z`). This should prevent SELinux problems [#131][131]
* 0.9.0: Upgrade to at least 2.1.5
* 0.8.0: Alpine linux was upgraded to 3.9 [#126][126]
* 0.7.0: The value of the `MAX_PAGE_SIZE` environment variable was changed to `1000`, which is the default of Netbox.
* 0.6.0: The naming of the default startup_scripts were changed.
  If you overwrite them, you may need to adjust these scripts.
* 0.5.0: Alpine was updated to 3.8, `*.env` moved to `/env` folder
* 0.4.0: In order to use Netbox webhooks you need to add Redis and a netbox-worker to your docker-compose.yml.
* 0.3.0: Field `filterable: <boolean` was replaced with field `filter_logic: loose/exact/disabled`. It will default to `CF_FILTER_LOOSE=loose` when not defined.
* 0.2.0: Re-organized paths: `/etc/netbox -> /etc/netbox/config` and `/etc/reports -> /etc/netbox/reports`. Fixes [#54][54].
* 0.1.0: Introduction of the `NETBOX_DOCKER_PROJECT_VERSION`. (Not a breaking change per se.)

[54]: https://github.com/netbox-community/netbox-docker/issues/54
[126]: https://github.com/netbox-community/netbox-docker/pull/126
[131]: https://github.com/netbox-community/netbox-docker/pull/131
[129]: https://github.com/netbox-community/netbox-docker/pull/129
[133]: https://github.com/netbox-community/netbox-docker/pull/133
[135]: https://github.com/netbox-community/netbox-docker/pull/135
[136]: https://github.com/netbox-community/netbox-docker/pull/136
[137]: https://github.com/netbox-community/netbox-docker/pull/137
[144]: https://github.com/netbox-community/netbox-docker/pull/144
[148]: https://github.com/netbox-community/netbox-docker/pull/148

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
