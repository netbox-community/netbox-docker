# cloud.docker.com Configuration

The automatic build is configured in cloud.docker.com.

The following build configuration is expected:

```yaml
Source Repository: github.com/netbox-community/netbox-docker
Build Location: Build on Docker Hub's infrastructure
Autotest: Internal and External Pull Requests
Repository Links: Enable for Base Image
Build Rules:
- Source Type: Branch
  Source: master
  Docker Tag: branches
  Dockerfile location: Dockerfile
- Source Type: Branch
  Source: master
  Docker Tag: prerelease
  Dockerfile location: Dockerfile
- Source Type: Branch
  Source: master
  Docker Tag: release
  Dockerfile location: Dockerfile
Build Environment Variables:
# Create an app on Github and use it's OATH credentials here
- Key: GITHUB_OAUTH_CLIENT_ID
  Value: <secret>
- Key: GITHUB_OAUTH_CLIENT_SECRET
  Value: <secret>
Build Triggers:
- Name: Cron Trigger
# Use this trigger in combination with e.g. https://cron-job.org in order to regularly schedule builds
```

## Background Knowledge

The build system of cloud.docker.com is not made for this kind of project.
But we found a way to make it work, and this is how:

1. The docker hub build system [allows to overwrite the scripts that get executed
   for `build`, `test` and `push`](overwrite). See `/hooks/*`.
2. Shared functionality of the scripts `build`, `test` and `push` is extracted to `/hooks/common`.
3. The `build` script runs `run_build()` from `/hooks/common`.
   This triggers either `/build-branches.sh`, `/build-latest.sh` or directly `/build.sh`.
4. The `test` script just invokes `docker-compose` commands.
5. The `push` script runs `run_build()` from `hooks/common` with a `--push-only` flag.
   This causes the `build.sh` script to not re-build the Docker image, but just the just built image.

The _Docker Tag_ configuration setting (`$DOCKER_TAG`) is only used to select the type (_release_, _prerelease_, _branches_) of the build in `hooks/common`.
Because it has a different meaning in all the other build scripts, it is `unset` after it has served it's purpose.

[overwrite]: https://docs.docker.com/docker-hub/builds/advanced/#override-build-test-or-push-commands
