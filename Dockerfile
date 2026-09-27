FROM python:3.11-slim

# Install Node.js and npm for the terminal server
RUN apt-get update && apt-get install -y \
    curl \
    nodejs \
    npm \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy all local files into the container
COPY . .

# Install Node dependencies for terminal server
WORKDIR /app/student-portal
RUN npm install || true

# Expose ports
EXPOSE 3000 3001

# Run both services
CMD ["sh", "-c", "python3 -m http.server 3000 --directory /app/student-portal &  cd /app/student-portal && node server.js"]
