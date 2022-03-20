RUN mkdir -p /hcp/client
COPY client/*.sh /hcp/client/
RUN chmod 755 /hcp/client/*.sh
