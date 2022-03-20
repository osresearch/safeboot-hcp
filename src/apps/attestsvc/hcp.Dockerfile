RUN useradd -m -s /bin/bash hcp_user

RUN mkdir -p /hcp/attestsvc
COPY attestsvc/*.sh /hcp/attestsvc/
RUN chmod 755 /hcp/attestsvc/*.sh
