# We need some upstream stuff
RUN apt-get install -y python3-yaml python3-distutils python3-cryptography
RUN apt-get install -y file

RUN mkdir -p /hcp/client
COPY client/*.sh /hcp/client/
RUN chmod 755 /hcp/client/*.sh
