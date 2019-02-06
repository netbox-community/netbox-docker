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
  Docker Tag: branches-main
  Dockerfile location: Dockerfile
- Source Type: Branch
  Source: master
  Docker Tag: branches-ldap
  Dockerfile location: Dockerfile.ldap
- Source Type: Branch
  Source: master
  Docker Tag: prerelease-main
  Dockerfile location: Dockerfile
- Source Type: Branch
  Source: master
  Docker Tag: prerelease-ldap
  Dockerfile location: Dockerfile.ldap
- Source Type: Branch
  Source: master
  Docker Tag: release-main
  Dockerfile location: Dockerfile
- Source Type: Branch
  Source: master
  Docker Tag: release-ldap
  Dockerfile location: Dockerfile.ldap
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
   for `build`, `test` and `push`](overwrite). See `hooks/*`.
2. Shared functionality of the scripts `build`, `test` and `push` is extracted to `hooks/common`.
3. The `build` script runs `run_build()` from `hooks/common`.
   This triggers either `build-branches.sh`, `build-latest.sh` or directly `build.sh`.
4. The `test` script just invokes `docker-compose` commands.
5. The `push` script runs `run_build()` from `hooks/common` with a `--push-only` flag.
   This causes the `build.sh` script to not re-build the Docker image, but just the just built image.

The _Docker Tag_ configuration setting is misused to select the type (_release_, _prerelease_, _branches_) of the build as well as the variant (_main_, _ldap_).

The _Dockerfile location_ configuration setting is completely ignored by the build scripts.

[overwrite]: https://docs.docker.com/docker-hub/builds/advanced/#override-build-test-or-push-commands
