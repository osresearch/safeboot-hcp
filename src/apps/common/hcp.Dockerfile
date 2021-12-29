# Copy, extract, and remove the tarballs we need to inject
COPY common/install.tar.gz /
RUN tar zxf install.tar.gz && rm install.tar.gz
COPY common/safeboot.tar.gz /
RUN tar zxf safeboot.tar.gz && rm safeboot.tar.gz
