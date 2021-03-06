FROM ubuntu:16.04

RUN apt-get update && apt-get -y dist-upgrade \
    && apt-get -y install python-pip uwsgi virtualenv sudo python-dev python3-dev libyaml-dev \
       libsasl2-dev libldap2-dev nginx uwsgi-plugin-python uwsgi-plugin-python3 libssl-dev libffi-dev xmlsec1 \
    && rm -rf /var/cache/apt/archives/*

RUN useradd -m -u 10001 -s /bin/bash iris

ADD docker/daemons /home/iris/daemons
ADD src /home/iris/src
ADD setup.py /home/iris/setup.py
ADD dev_requirements.txt /home/iris/dev_requirements.txt
ADD ./configs /home/iris/source/configs
ADD ./uid_entrypoint.sh /usr/bin

RUN chown -R iris:iris /home/iris /var/log/nginx /var/lib/nginx \
    && sudo -Hu iris mkdir -p /home/iris/config /home/iris/var/log/uwsgi /home/iris/var/log/nginx /home/iris/var/run /home/iris/var/relay \
    && sudo -Hu iris cp /home/iris/source/configs/config.dev.yaml /home/iris/config/config.yaml \
    && sudo -Hu iris virtualenv -p /usr/bin/python3 /home/iris/env \
    && sudo -Hu iris /bin/bash -c 'source /home/iris/env/bin/activate && cd /home/iris/ && pip install -r dev_requirements.txt .'

EXPOSE 16648

# uwsgi runs nginx. see uwsgi.yaml for details
CMD ["/usr/bin/uwsgi", "--yaml", "/home/iris/daemons/uwsgi.yaml:prod"]
### user name recognition at runtime w/ an arbitrary uid - for OpenShift deployments
RUN chgrp -R root /home/iris /var/log/nginx /var/lib/nginx
RUN chmod -R g=u /etc/passwd /home/iris /var/log/nginx /var/lib/nginx
RUN chmod -R g+w /home/iris/config/config.yaml
ENTRYPOINT [ "uid_entrypoint.sh" ]
USER 10001
