FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV HOSTNAME=linux-server.cyberlab.local

# Update system
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    wget \
    openssh-server \
    openssh-client \
    apache2 \
    openssl \
    proftpd-basic \
    dnsmasq \
    tcpdump \
    net-tools \
    vim \
    nano \
    git \
    build-essential \
    python3 \
    python3-pip \
    telnet \
    netcat \
    dnsutils \
    iproute2 \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# Create application directories
RUN mkdir -p /var/www/html /var/ftp /data/cyberlab /var/log/cyberlab

# Copy configuration files
COPY ssh-config.sh /usr/local/bin/
COPY apache-config.sh /usr/local/bin/
COPY proftpd-config.sh /usr/local/bin/
COPY startup.sh /usr/local/bin/
COPY health-check.sh /usr/local/bin/
COPY web-content/ /var/www/html/

# Copy vulnerable application (intentional)
COPY app/ /var/www/app/

# Copy ProFTPD configuration
COPY proftpd.conf /etc/proftpd/proftpd.conf

RUN chmod +x /usr/local/bin/*.sh

# Create lab users
COPY create-users.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/create-users.sh && /usr/local/bin/create-users.sh

# Set default root password for lab access
RUN echo "root:cyberlab" | chpasswd

# Create network interface for internal network
RUN ip link add eth1 type dummy || true

EXPOSE 22 80 443 21 20 53 53/udp

ENTRYPOINT ["/usr/local/bin/startup.sh"]
