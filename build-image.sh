#!/bin/bash

break=after-error disk-image-create -n -x --no-tmpfs -o ubuntu ubuntu-minimal vm infra nova-agent
