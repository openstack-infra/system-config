# TODO(mordred) Update the ansible to not need env vars
# This has to be done via env vars due to how the
# ansible writes out some config values.
export OS_AUTH_URL="https://auth.vexxhost.net/v3"
export OS_REGION_NAME="sjc1"
export OS_USERNAME="openstackci"
export OS_USER_DOMAIN_NAME="default"
export OS_PROJECT_NAME="openstackci"
export OS_PROJECT_DOMAIN_NAME="default"
export OS_PASSWORD=TODO-FIX-ME

export KEY="infra-root-keys"
export NAME="opendev-k8s"
export IMAGE="Ubuntu 16.04 LTS (x86_64) [2018-08-24]"
export MASTER_FLAVOR="v2-highcpu-4"
export MASTER_BOOT_FROM_VOLUME="True"
export FLOATING_IP_NETWORK_UUID="0048fce6-c715-4106-a810-473620326cb0"
export NODE_FLAVOR="v2-highcpu-8"
export NODE_AUTO_IP="True"
export NODE_BOOT_FROM_VOLUME="True"
export NODE_VOLUME_SIZE="64"
export NODE_EXTRA_VOLUME="True"
export NODE_EXTRA_VOLUME_SIZE="80"
export USE_OCTAVIA="True"
