FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV HOSTNAME=ws-employee.cyberlab.local

RUN apt-get update && apt-get install -y --no-install-recommends \
    samba \
    samba-common \
    curl \
    tcpdump \
    net-tools \
    netcat \
    dnsutils \
    python3 \
    iproute2 \
    && rm -rf /var/lib/apt/lists/*

# Copy configuration files
COPY smb-config.sh /usr/local/bin/
COPY startup.sh /usr/local/bin/
COPY smb.conf /etc/samba/smb.conf
COPY create-shares.sh /usr/local/bin/

RUN chmod +x /usr/local/bin/*.sh

# Create required directories
RUN mkdir -p /var/samba-shares/public
RUN mkdir -p /var/samba-shares/data
RUN mkdir -p /var/log/cyberlab

EXPOSE 135 139 445

ENTRYPOINT ["/usr/local/bin/startup.sh"]
