RUN apt-get install -y git
RUN apt-get install -y python3-yaml python3-flask
RUN apt-get install -y uwsgi-plugin-python3

ARG HCP_USER
RUN useradd -m -s /bin/bash $HCP_USER
ENV HCP_USER=$HCP_USER

RUN mkdir -p /hcp/attestsvc
COPY attestsvc/*.sh /hcp/attestsvc/
RUN chmod 755 /hcp/attestsvc/*.sh
