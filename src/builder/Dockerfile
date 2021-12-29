RUN apt-get install -y gcc g++ make
RUN apt-get install -y automake autoconf autoconf-archive libtool pkg-config
RUN apt-get install -y curl wget expect gawk socat help2man
RUN apt-get install -y libc-dev libssl-dev libseccomp-dev libtasn1-6-dev
RUN apt-get install -y libjson-c-dev libcurl4-openssl-dev libqrencode-dev
RUN apt-get install -y uuid-dev gnu-efi binutils-dev libjson-glib-dev
RUN apt-get install -y libfile-slurp-perl python3-cryptography

COPY git /usr/bin
RUN chmod 755 /usr/bin/git
