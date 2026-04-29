# Use an official Python runtime as a parent image
FROM python:3.11-slim

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

# Set the working directory in the container
WORKDIR /app

# Install system dependencies needed for building uWSGI and Pillow, plus curl for healthcheck
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    python3-dev \
    libjpeg-dev \
    zlib1g-dev \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY requirements.txt .
# We install Pillow and uWSGI explicitly as they are required for production
# but were missing from the provided requirements.txt
RUN pip install --no-cache-dir -r requirements.txt Pillow uWSGI

# Copy the rest of the application code
COPY . .

# Adjust wsgi.ini for Docker:
# 1. Remove plugins line (pip-installed uWSGI has them built-in)
# 2. Remove req-logger line (we want to log to stdout)
RUN sed -i '/plugins =/d' wsgi.ini && \
    sed -i '/req-logger =/d' wsgi.ini

# Expose the port uWSGI is configured to listen on
EXPOSE 8000

# Add a healthcheck to ensure the app is responding
HEALTHCHECK --interval=30s --timeout=3s \
  CMD curl -f http://localhost:8000/ || exit 1

# Run uWSGI using the modified wsgi.ini
# We log to stdout for better Docker integration
CMD ["uwsgi", "--ini", "wsgi.ini", "--req-logger", "stdio"]
