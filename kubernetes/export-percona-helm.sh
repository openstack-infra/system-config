#!/bin/bash

# Assumes helm is installed in the path. Can be downloaded from
# wget https://storage.googleapis.com/kubernetes-helm/helm-v2.12.0-linux-amd64.tar.gz

K8S_DIR=$(pwd)
BUILD_DIR=$(mktemp -d)

pushd $BUILD_DIR

helm fetch stable/percona-xtradb-cluster --untar
helm template --name=gitea --set allowRootFrom=127.0.0.1,mysqlRootPassword=CHANGEMEROOTPASSWORD,xtraBackupPassword=CHANGEMEXTRABACKUP,mysqlUser=gitea,mysqlPassword=CHANGEMEPASSWORD,mysqlDatabase=gitea,persistence.enabled=true,persistence.storageClass=cinder --namespace gitea --output-dir $K8S_DIR percona-xtradb-cluster

popd
rm -rf $BUILD_DIR
# Remove trailing whitespace
rm -rf percona-xtradb-cluster/templates/test
mv percona-xtradb-cluster/templates/*yaml percona-xtradb-cluster
find percona-xtradb-cluster -type f | xargs -n1 sed -i 's/ *$//'
