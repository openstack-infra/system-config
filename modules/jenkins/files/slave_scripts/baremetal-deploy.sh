#!/bin/bash -xe

WORKSPACE=$(pwd)
mkdir -p logs
rm -f logs/*
cd $(dirname "$0")

echo "Jenkins: resetting hosts..."
for host in $HEAD_HOST ${COMPUTE_HOSTS//,/ }; do
    scp lvm-kexec-reset.sh root@$host:/var/tmp/
    ssh root@$host /var/tmp/lvm-kexec-reset.sh
    sudo rm -f /var/log/orchestra/rsyslog/$host/syslog
done

# Have rsyslog reopen log files we rm'd from under it
sudo restart rsyslog

# wait for the host to come up (2 ping responses or timeout after 5 minutes)
echo "Jenkins: Waiting for head host to return after reset..."
sleep 10
if ! timeout 300 ./ping.py $HEAD_HOST; then
    echo "Jenkins: ERROR: Head node did not come back up after reset"
    exit 1
fi

echo "Jenkins: Pre-populating PIP cache"
for host in $HEAD_HOST ${COMPUTE_HOSTS//,/ }; do
    scp -r ~/cache/pip root@$host:/var/cache/pip
done

echo "Jenkins: Caching images."
cd ~/devstack
source stackrc
for image_url in ${IMAGE_URLS//,/ }; do
    # Downloads the image (uec ami+aki style), then extracts it.
    IMAGE_FNAME=$(echo "$image_url" | python -c "import sys; print sys.stdin.read().split('/')[-1]")
    IMAGE_NAME=$(echo "$IMAGE_FNAME" | python -c "import sys; print sys.stdin.read().split('.tar.gz')[0].split('.tgz')[0]")
    if [ ! -f files/$IMAGE_FNAME ]; then
        wget -c $image_url -O files/$IMAGE_FNAME
    fi
done

echo "Jenkins: Executing build_bm_multi.sh."
./tools/build_bm_multi.sh
