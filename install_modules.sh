#!/bin/bash

MODULE_PATH=/etc/puppet/modules

function remove_module {
  local SHORT_MODULE_NAME=$1
  if [ -n "$SHORT_MODULE_NAME" ]; then
    rm -Rf "$MODULE_PATH/$SHORT_MODULE_NAME"
  else
    echo "ERROR: remove_module requires a SHORT_MODULE_NAME."
  fi
}

# Array of modules to be installed key:value is module:version.
declare -A MODULES

# Array of modues to be installed from source and without dependency resolution.
# key:value is source location, revision to checkout
declare -A SOURCE_MODULES

# These modules will be installed without dependency resolution
declare -A  NONDEP_MODULES

#NOTE: if we previously installed kickstandproject-ntp we nuke it here
# since puppetlabs-ntp and kickstandproject-ntp install to the same dir
if grep kickstandproject-ntp /etc/puppet/modules/ntp/Modulefile &> /dev/null; then
  remove_module "ntp"
fi

remove_module "gearman" #remove old saz-gearman
remove_module "limits" # remove saz-limits (required by saz-gearman)

MODULES["puppetlabs-ntp"]="0.2.0"

# freenode #puppet 2012-09-25:
# 18:25 < jeblair> i would like to use some code that someone wrote,
# but it's important that i understand how the author wants me to use
# it...
# 18:25 < jeblair> in the case of the vcsrepo module, there is
# ambiguity, and so we are trying to determine what the author(s)
# intent is
# 18:30 < jamesturnbull> jeblair: since we - being PL - are the author
# - our intent was not to limit it's use and it should be Apache
# licensed
MODULES["openstackci-vcsrepo"]="0.0.8"

MODULES["puppetlabs-apache"]="0.0.4"
MODULES["puppetlabs-apt"]="1.1.0"
MODULES["puppetlabs-haproxy"]="0.4.1"
MODULES["puppetlabs-mysql"]="0.6.1"
MODULES["puppetlabs-postgresql"]="3.1.0"
MODULES["puppetlabs-stdlib"]="3.2.0"
MODULES["saz-memcached"]="2.0.2"
MODULES["spiette-selinux"]="0.5.1"
MODULES["rafaelfc-pear"]="1.0.3"
MODULES["puppetlabs-inifile"]="1.0.0"
MODULES["puppetlabs-firewall"]="0.0.4"
MODULES["puppetlabs-puppetdb"]="3.0.1"
MODULES["stankevich-python"]="1.6.6"

SOURCE_MODULES["https://github.com/nibalizer/puppet-module-puppetboard"]="2.4.0"

MODULE_LIST=`puppet module list`

# Transition away from old things
if [ -d /etc/puppet/modules/vcsrepo/.git ]
then
  rm -rf /etc/puppet/modules/vcsrepo
fi

# Install all the modules
for MOD in ${!MODULES[*]} ; do
  # If the module at the current version does not exist upgrade or install it.
  if ! echo $MODULE_LIST | grep "$MOD ([^v]*v${MODULES[$MOD]}" >/dev/null 2>&1
  then
    # Attempt module upgrade. If that fails try installing the module.
    if ! puppet module upgrade $MOD --version ${MODULES[$MOD]} >/dev/null 2>&1
    then
      # This will get run in cron, so silence non-error output
      puppet module install $MOD --version ${MODULES[$MOD]} >/dev/null
    fi
  fi
done

MODULE_LIST=`puppet module list`

# Make a second pass, just installing modules from source
for MOD in ${!SOURCE_MODULES[*]} ; do
  # get the actual name of the module
  module_name=`echo $MOD | awk -F- '{print $NF}'`
  # treat any occurrence of the module as a match
  if ! echo $MODULE_LIST | grep "${module_name}" >/dev/null 2>&1; then
    # clone modules that are not installed
    git clone $MOD "${MODULE_PATH}/${module_name}"
  fi
  pushd "${MODULE_PATH}/${module_name}" >/dev/null
    # make sure the correct revision is installed
    if [ `git rev-parse HEAD` != `git rev-parse ${SOURCE_MODULES[$MOD]}` ]; then
      # checkout correct revision
      git fetch
      git checkout ${SOURCE_MODULES[$MOD]}
    fi
  popd >/dev/null
done
