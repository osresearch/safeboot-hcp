RUN mkdir -p /hcp/soakhost
COPY soak.sh greeting.sh /hcp/soakhost/
RUN chmod 755 /hcp/soakhost/*.sh

RUN echo "/hcp/soakhost/greeting.sh" >> /etc/bash.bashrc
