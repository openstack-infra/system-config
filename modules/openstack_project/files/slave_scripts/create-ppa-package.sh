#!/bin/bash -xe

if [ -z "$PROJECT" ]
then
	echo '$PROJECT not set.'
	exit 1
fi

case "$ZUUL_REFNAME" in
    master)
        export PPAS="ppa:openstack-ppa/bleeding-edge"
        ;;
    milestone-proposed)
        export PPAS="ppa:openstack-ppa/milestone-proposed"
        ;;
    *)
        echo "No PPA defined for branch $ZUUL_REFNAME"
        exit 0
esac

HUDSON=http://localhost:8080/
# We keep packaging for openstack trunk in lp:~o-u-p/$project/ubuntu
# For a release (diablo, essex), it's in lp:~o-u-p/$project/$release
OPENSTACK_RELEASE=${OPENSTACK_RELEASE:-ubuntu}
BZR_BRANCH=${BZR_BRANCH:-lp:~openstack-ubuntu-packagers/$PROJECT/${OPENSTACK_RELEASE}}
PPAS=${PPAS:-ppa:$PROJECT-core/trunk}
PACKAGING_REVNO=${PACKAGING_REVNO:--1}
series=${series:-lucid}

cd build

tarball="$(echo dist/$PROJECT*.tar.gz)"
version="${tarball%.tar.gz}"
version="${version#*$PROJECT-}"
base_version=$version
if [ -n "${EXTRAVERSION}" ]
then
    version="${version%~*}${EXTRAVERSION}~${version#*~}"
fi
tar xvzf "${tarball}"
echo ln -s "${tarball}" "${PROJECT}_${version}.orig.tar.gz"
ln -s "${tarball}" "${PROJECT}_${version}.orig.tar.gz"

# Overlay packaging
# (Intentionally using the natty branch. For these PPA builds, we don't need to diverge
# (yet, at least), so it makes the branch management easier this way.
# Note: Doing a checkout and deleting .bzr afterwards instead of just doing an export,
# because export refuses to overlay over an existing directory, so this was easier.
# (We need to not have the .bzr in there, otherwise vcsversion.py might get overwritten)
echo bzr checkout -r ${PACKAGING_REVNO} --lightweight $BZR_BRANCH $PROJECT-*
bzr checkout -r ${PACKAGING_REVNO} --lightweight $BZR_BRANCH $PROJECT-*
cd $PROJECT-*
if [ -d .git ]
then
    PACKAGING_REVNO="$(git log --oneline | wc -l)"
    rm -rf .git
else
    PACKAGING_REVNO="$(bzr revno --tree)"
    rm -rf .bzr
fi

# Please don't change this. It's the only way I'll get notified
# if an upload fails.
export DEBFULLNAME="Soren Hansen"
export DEBEMAIL="soren@openstack.org"

buildno=$BUILD_NUMBER
pkgversion="${version}-0ubuntu0~${series}${buildno}"
dch -b --force-distribution --v "${pkgversion}" "Automated PPA build. Packaging revision: ${PACKAGING_REVNO}." -D $series
dpkg-buildpackage -rfakeroot -S -sa -nc -k32EE128C
if ! [ "$DO_UPLOAD" = "no" ]
then
    for ppa in $PPAS
    do
        dput --force $ppa "../${PROJECT}_${pkgversion}_source.changes"
    done
fi
cd ..
