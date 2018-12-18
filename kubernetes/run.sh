# TODO(mordred) Turn this in to a playbook. This file is here to record
# the general sequence needed.
kubectl apply -f rook-operator.yaml
kubectl apply -f rook-cluster.yaml
kubectl apply -f rook-toolbox.yaml
kubectl apply -f rook-filesystem.yaml
kubectl apply -f gitea-namespace.yaml
kubectl apply -f mariadb-secret.yaml
kubectl apply -f mariadb-pv.yaml
kubectl apply -f mariadb.yaml
kubectl apply -f gitea.yaml

source env.sh
ansible-playbook site.yaml
