RUN apt-get install -y python3-yaml python3-distutils python3-cryptography json-glib-tools
RUN apt-get install -y python3-requests python3-openssl

RUN mkdir -p /hcp/swtpmsvc
COPY swtpmsvc/*.sh swtpmsvc/*.py /hcp/swtpmsvc/
RUN chmod 755 /hcp/swtpmsvc/*.sh /hcp/swtpmsvc/*.py
