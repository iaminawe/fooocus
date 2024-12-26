FROM python:3.10-slim

RUN apt-get update && \
    apt-get install --no-install-recommends -y \
    git \
    libgl1 \
    libglib2.0-0 \
    curl \
    build-essential && \
    rm -rf /var/lib/apt/lists/*

# Install specific pip version and required base packages
RUN pip install --no-cache-dir pip==23.3.2 && \
    pip install --no-cache-dir virtualenv packaging numpy>=1.19

WORKDIR /bootstrap

COPY ./bootstrap.sh /bootstrap/bootstrap.sh
RUN chmod +x "/bootstrap/bootstrap.sh"

# Set environment variable to bind to all interfaces
ENV HOST=0.0.0.0
ENV PYTHONUNBUFFERED=1

ENTRYPOINT [ "/bootstrap/bootstrap.sh" ]
