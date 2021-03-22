# Debian package builder for greenclip

This repository contains Debian packaging files, build scripts and a GitHub Actions workflow for building a greenclip Debian package.

# Usage
The `build.sh` script is meant to be called from within a docker/podman container because we want a clean environment to build in. An alternative approach would be to use `pbuilder` or `sbuild` which build the package in a chroot environment.

Docker:
```sh
docker run \
    --rm \
    -v $PWD:/build \
    -w /build \
    ubuntu:20.10 \
    bash build.sh
```

# Creating a new release

Creating new releases via GitHub Actions is as simple as updating the changelog with:
```sh
dch --controlmaint --newversion 0.7.2-1 --distribution $(lsb_release -c -s) --urgency low
```
or with the shorter version:
```sh
dch -M -v 0.7.2-1 -D $(lsb_release -c -s) -u low
```

And then pushing the changes to GitHub.

The `--controlmain`/`-M` option will populate the new changelog entry with maintainer information from the `debian/control` file. Omit the flag if that is not desired.

**IMPORTANT**: Version numbers should always be in the following format: `${GREENCLIP_VERSION}-([1-9][0-9]*)`. This format is expected by the build script so that it can fetch the correct greenclip git tag.

# TODOs
* Sign the packages produced by GitHub Actions
* Push the packages directly into a PPA instead of creating releases.
