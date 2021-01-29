---
name: Bug report
about: Create a report to help us improve
title: ''
labels: ''
assignees: ''

---

<!--

Before raising an issue here, answer the following questions for yourself, please:

* Did you read through the troubleshooting section? (https://github.com/netbox-community/netbox-docker/wiki/Troubleshooting)
* Have you had a look at the rest of the wiki? (https://github.com/netbox-community/netbox-docker/wiki)
* Have you updated to the latest version and tried again? (i.e. `git pull` and `docker-compose pull`)
* Have you reset the project and tried again? (i.e. `docker-compose down -v`)
* Are you confident that your problem is related to the Docker image or Docker Compose file this project provides?
  (Otherwise ask on the Netbox mailing list, please: https://groups.google.com/d/forum/netbox-discuss)
* Have you looked through the issues already resolved?

Please try this means to get help before opening an issue here:

* On the networktocode Slack in the #netbox-docker channel: http://slack.networktocode.com/
* On the networktocode Slack in the #netbox channel: http://slack.networktocode.com/
* On the Netbox mailing list: https://groups.google.com/d/forum/netbox-discuss

Please don't open an issue when you have a PR ready. Just submit the PR, that's good enough.

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

<!-- adjust the `latest` tag to the version you're using -->
The output of `docker inspect netboxcommunity/netbox:latest --format "{{json .Config.Labels}}"`:

```json
{
  "JSON JSON JSON":
    "--> Please paste formatted json. (Use e.g. `jq` or https://jsonformatter.curiousconcept.com/)"
}
```

The output of `docker-compose logs netbox`:
<!--
If your log is very long, create a Gist instead (and post the link to it): https://gist.github.com
-->

```text
LOG LOG LOG
```
