# Create /hcp/common and put our stuff in there
RUN mkdir /hcp/common
COPY common/*.sh /hcp/common/
RUN chmod 755 /hcp/common/*.sh

# Copy, extract, and remove the tarballs we need to inject
COPY common/install.tar.gz /
RUN tar zxf install.tar.gz && rm install.tar.gz
COPY common/safeboot.tar.gz /
RUN tar zxf safeboot.tar.gz && rm safeboot.tar.gz
