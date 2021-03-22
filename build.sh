#!/bin/bash

set -xue

BASEDIR=${PWD}

# Install basic dependencies for downloading the source code and building a dev packagea
export DEBIAN_FRONTEND=noninteractive
apt-get update && apt-get install -yq \
    build-essential \
    debhelper \
    devscripts \
    equivs \
    git

# Install Rust & Cargo

# Get app version from the changelog
DEB_VERSION=$(dpkg-parsechangelog --show-field Version)
VERSION=$(echo ${DEB_VERSION} | sed -e "s/-[1-9][0-9]*$//g")

# Download source code
SOURCE_FILE_NAME="greenclip_${VERSION}.orig.tar.gz"
SOURCE_DIR="greenclip-${VERSION}"
git clone git@github.com:erebe/greenclip.git --branch ${VERSION} --depth 1 ${SOURCE_DIR}
tag -czvf ${SOURCE_FILE_NAME} ${SOURCE_DIR}

# Set up the debian dir in the source directory
mv ${BASEDIR}/debian/ ${BASEDIR}/${SOURCE_DIR}/

# Install the rest of the build dependencies

# mk-build-deps will generate two files, so we want to run it outside
# the SOURCE_DIR to not pollute it. dpkg-buildpackage or dpkg-source
# will complain is the content of the SOURCE_DIR do not match the
# `orig` tarball although I'm not familiar with the details here so
# take this information with a grain of salt. This behaviour can also
# be work around by passing the `-nc`/`--no-pre-check` flag to debuild.
#
# nocheck build profile is set so that we skip the installation of cargo
# and rustc, name of the build profile can be anything - it just needs to
# match whatever profile `cargo` and `rustc` are to be ignored for in the
# `Build-Depends` in `debian/control`
mk-build-deps \
    -t 'apt-get -o Debug::pkgProblemResolver=yes --no-install-recommends -qqy' \
    -i \
    -r \
    ${BASEDIR}/${SOURCE_DIR}/debian/control

# Don't want to sign the package at the moment and also don't want to fail
# on the build-deps check because we're installing cargo manually.
cd ${BASEDIR}/${SOURCE_DIR}
debuild \
    --unsigned-source \
    --unsigned-changes

# Construct the full path to the built debian package
GREENCLIP_DEB_PATH="${BASEDIR}/greenclip_${DEB_VERSION}_$(dpkg-architecture -q DEB_TARGET_ARCH).deb"

# Finally copy the output debian package into a separate folder
mkdir -p ${BASEDIR}/output/
mv ${GREENCLIP_DEB_PATH} ${BASEDIR}/output/

# ...and write version information somewhere where the GitHub Actions job will be able to access them
echo -n "${DEB_VERSION}" > ${BASEDIR}/gh_version_info
