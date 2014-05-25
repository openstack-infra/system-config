FROM ubuntu

RUN apt-get update && apt-get install -y kpartx qemu-utils curl python wget git

RUN curl -O https://bootstrap.pypa.io/get-pip.py && python get-pip.py

RUN pip install diskimage-builder pyyaml
