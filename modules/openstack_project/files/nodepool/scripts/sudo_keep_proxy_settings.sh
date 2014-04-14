cat >/etc/sudoers.d/60_keep_proxy <<EOF
Defaults env_keep += "http_proxy https_proxy no_proxy"
EOF
chmod 440 /etc/sudoers.d/60_keep_proxy
visudo -c

