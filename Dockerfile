# Use a lightweight Python image
FROM alpine:latest

# Install Python3
RUN apk add --no-cache python3 py3-pip kubectl

# Install Flask
RUN pip3 install Flask --break-system-packages
COPY . /app
RUN pip3 install prometheus_flask_exporter --break-system-packages
COPY . /app

# Set the working directory in the container
WORKDIR /app

# Copy the Python script into the container
COPY print-timestamp.py .

# Command to run the Python script
CMD ["python", "print-timestamp.py"]

