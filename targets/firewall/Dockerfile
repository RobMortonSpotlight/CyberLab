FROM alpine:3.18

RUN apk add --no-cache \
    iptables \
    ip6tables \
    iproute2 \
    curl \
    bash \
    tcpdump \
    net-tools \
    dnsmasq \
    bind-tools

# Copy firewall configuration scripts
COPY firewall.sh /usr/local/bin/
COPY dnsmasq.conf /etc/dnsmasq.conf
COPY iptables-rules.sh /usr/local/bin/
COPY health-check.sh /usr/local/bin/

RUN chmod +x /usr/local/bin/*.sh

# Create required directories
RUN mkdir -p /etc/firewall-rules /var/log/firewall

EXPOSE 53/udp 53/tcp

ENTRYPOINT ["/usr/local/bin/firewall.sh"]
