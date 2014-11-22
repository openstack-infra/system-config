break=after-error disk-image-create -n -x --no-tmpfs -o ubuntu ubuntu-minimal vm infra nova-agent
qemu-img convert -O raw ubuntu.qcow ubuntu.raw
sudo docker run -v $(pwd):/images emonty/vhd-util convert -s 0 -t 1 -i /images/ubuntu.raw -o /images/intermediate.vhd
sudo docker run -v $(pwd):/images emonty/vhd-util convert -s 1 -t 2 -i /images/intermediate.vhd -o /images/ubuntu.vhd
swift upload --object-name test-monty-ubuntu.vhd images ubuntu.vhd
glane image-delete "Test Monty Ubuntu"
glance --os-image-api-version=2 task-create --type=import --input='{"import_from": "images/test-monty-ubuntu.vhd", "image_properties" : {"name": "Test Monty Ubuntu", "vm_mode": "hvm", "xenapi_use_agent": "true"}}'

