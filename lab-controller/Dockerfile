FROM ubuntu:22.04

RUN apt-get update && apt-get install -y --no-install-recommends \
    openjdk-17-jre-headless \
    curl \
    && rm -rf /var/lib/apt/lists/*

ENV JAVA_OPTS="-Xmx512m -Xms256m"
ENV SPRING_PROFILES_ACTIVE=production

WORKDIR /app

# Copy built application
COPY build/libs/cyberlab-controller-1.0.0.jar /app/cyberlab-controller.jar
COPY start.sh /app/

RUN chmod +x /app/start.sh

EXPOSE 8080 8443

ENTRYPOINT ["/app/start.sh"]
