FROM alpine:3.18

ENV DEVICE_TYPE=ipmi
ENV DEVICE_ID=bmc-lab-01
ENV DEFAULT_USER=admin
ENV DEFAULT_PASS=CyberLab@123

RUN apk add --no-cache \
    bash \
    curl \
    netcat-openbsd \
    tcpdump \
    net-tools \
    python3

# Copy IoT device simulation startup
COPY startup.sh /usr/local/bin/

RUN chmod +x /usr/local/bin/startup.sh

# Create log directory
RUN mkdir -p /var/log/cyberlab

EXPOSE 623 5900 8080

ENTRYPOINT ["/usr/local/bin/startup.sh"]
