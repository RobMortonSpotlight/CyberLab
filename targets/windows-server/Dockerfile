FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV HOSTNAME=server.cyberlab.local

RUN apt-get update && apt-get install -y --no-install-recommends \
    samba \
    samba-common \
    samba-client \
    winbind \
    libnss-winbind \
    libpam-winbind \
    curl \
    tcpdump \
    net-tools \
    netcat \
    dnsutils \
    python3 \
    python3-pip \
    iproute2 \
    && rm -rf /var/lib/apt/lists/*

# Copy configuration files
COPY smb.conf /etc/samba/smb.conf
COPY startup.sh /usr/local/bin/
COPY create-shares.sh /usr/local/bin/
COPY postgres-init.sh /usr/local/bin/

RUN chmod +x /usr/local/bin/*.sh

# Create required directories
RUN mkdir -p /var/samba-shares/data
RUN mkdir -p /var/samba-shares/backup
RUN mkdir -p /var/samba-shares/admin
RUN mkdir -p /var/log/cyberlab

EXPOSE 135 139 445 5432 8443

ENTRYPOINT ["/usr/local/bin/startup.sh"]
