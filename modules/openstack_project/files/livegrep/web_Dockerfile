
FROM livegrep

EXPOSE 9999

ADD server.json /server.json

CMD  cd /opt/livegrep && /opt/livegrep/bin/livegrep -logtostderr -listen 0.0.0.0:8910 /server.json

