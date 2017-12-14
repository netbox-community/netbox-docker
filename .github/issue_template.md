<!--

Before raising an issue here, answer the following questions for yourself, please:

* Did you read through the troubleshooting section? (https://github.com/ninech/netbox-docker/#troubleshooting)
* Have you updated to the latest version and tried again? (i.e. `git pull` and `docker-compose pull`)
* Have you reset the project and tried again? (i.e. `docker-compose down -v`)
* Are you confident that your problem is related to the Docker or Docker Compose setup this project provides?
  (Otherwise ask on the Netbox mailing list, please: https://groups.google.com/d/forum/netbox-discuss)
* Have you looked through the issues already resolved?

-->

## Current Behavior

<!-- describe what you did and how it misbehaved -->
...

## Expected Behavior

<!-- describe what you expected instead -->
...

## Debug Information

<!-- please fill in the following information that might helps us debug your problem more quickly -->
The output of `docker-compose version`: `XXXXX`
The output of `docker version`: `XXXXX`
The output of `git rev-parse HEAD`: `XXXXX`
The command you used to start the project: `XXXXX`

The output of `docker-compose logs netbox`:
<!-- if your log is very long, create a Gist instead: https://gist.github.com -->

```
LOG LOG LOG
```

<!--
If you have get any 5xx http error, else delete this section.
If your log is very long, create a Gist instead: https://gist.github.com
-->
The output of `docker-compose logs nginx`:

```
LOG LOG LOG
```
