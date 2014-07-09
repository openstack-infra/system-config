docker.io run --privileged=true -v ~/.cache:/.cache -v $(pwd):/config -w /config -i -t diskimage-builder /bin/bash tools/build-image.sh
