# Development, Maintenance and Community Principals for _NetBox Docker_

This principals shall guide the development and the maintenance of _NetBox Docker_.

## Basic principals

This project is maintained on voluntary basis.
Everyone is asked to respect that.

This means, that …

- … sometimes features are not implemented as fast as one might like -- or not at all.
- … sometimes nobody is looking at bugs or they are not fixed as fast as one might like -- or not at all.
- … sometimes PRs are not reviewed for an extended period.

Everyone is welcome to provide improvements and bug fixes to the benefit of everyone else.

## Development Principals

The goal of the _NetBox Docker_ project is to provide a container to run the basic NetBox project.
The container should feel like a native container -- as if it were provided by NetBox itself:

- Configuration via environment variables where feasible.
- Configuration of secrets via secret files.
- Log output to standard out (STDOUT/&1) / standard error (STDERR/&2).
- Volumes for data and cache directories.
- Runs a non-root user by default.
- One process / role for each instance.

There is one exception for the configuration:
Whenever a `dict` is required as value of a configuration setting, then it must not be provided through an environment variable.

The container generally does not provide more features than the basic NetBox project itself provides.
It may provide additional Python dependencies than the upstream project, so that all features of NetBox can be used in the container.
It may provide helpers, so that the container feels and behaves like a native container.

The container does not come with pre-bundled plugins.

## Maintenance Principals

The main goals of maintainig _NetBox Docker_ are:

- Keeping the project on a high quality level.
- Keeping the maintenance effort minimal.
- Coordinating development efforts.

The following guidelines help us to achieve these goals:

- As many maintenance tasks as possible shall be automated or scripted.
- All manual tasks must be documented.
- All changes are reviewed by at least one maintainer.
  - Changes of maintainers are reviewed by at least one other maintainer.
- The infrastructure beyond what GitHub provides shall be kept to a minimum.
  - On request, every maintainer shall get access to infrastructure that is beyond GitHub (at the time of writing that's _Docker Hub_ and _Quay_ in particular).

## Community Principals

This project is developed by the NetBox community for the NetBox community.
We welcome contributions, as long as they are in line with the principals above.

The maintainers of NetBox Docker are not the support team.
The community is expected to help each other out.
