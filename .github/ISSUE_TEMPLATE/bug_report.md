---
name: Bug report
about: Create a report about a malfunction of the Docker setup
title: ''
labels: ''
assignees: ''

---

<!--

Please only raise an issue if you're certain that you've found a bug.
Else, see these other means to get help:

* See our troubleshooting section:
  https://github.com/netbox-community/netbox-docker/wiki/Troubleshooting
* Have a look at the rest of the wiki:
  https://github.com/netbox-community/netbox-docker/wiki
* Check the release notes:
  https://github.com/netbox-community/netbox-docker/releases
* Look through the issues already resolved:
  https://github.com/netbox-community/netbox-docker/issues?q=is%3Aclosed

If you did not find what you're looking for,
try the help of our community:

* Post to Github Discussions:
  https://github.com/netbox-community/netbox-docker/discussions
* Join the `#netbox-docker` channel on our Slack:
  https://join.slack.com/t/netdev-community/shared_invite/zt-mtts8g0n-Sm6Wutn62q_M4OdsaIycrQ
* Ask on the NetBox mailing list:
  https://groups.google.com/d/forum/netbox-discuss

Please don't open an issue to open a PR.
Just submit the PR, that's good enough.

-->

## Current Behavior

<!-- describe what you did and how it misbehaved -->



## Expected Behavior

<!-- describe what you expected instead -->



## Debug Information

<!-- please fill in the following information that helps us debug your problem more quickly -->

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
If your log is very long, create a Gist instead and post the link to it: https://gist.github.com
-->

```text
LOG LOG LOG
```

The output of `cat docker-compose.override.yml`:
<!--
If this file is very long, create a Gist instead and post the link to it: https://gist.github.com
-->

```text
LOG LOG LOG
```
