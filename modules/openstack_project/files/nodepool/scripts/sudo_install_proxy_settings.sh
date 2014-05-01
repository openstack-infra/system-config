#!/bin/bash
cat >/etc/apt/apt.conf <<EOF
Acquire::http::Proxy \"$http_proxy\";
EOF

cat >>/etc/environment <<EOF
http_proxy=$http_proxy
https_proxy=$https_proxy
no_proxy=$no_proxy
EOF

cat >>/etc/profile <<EOF
export http_proxy=$http_proxy
export https_proxy=$https_proxy
export no_proxy=$no_proxy
EOF

mkdir -p ~/.pip/
cat >~/.pip/pip.conf <<EOF
[global]
proxy = $http_proxy
EOF
