# syntax=docker/dockerfile:1
# Dockerfile for DigitalOcean App Platform deployment
# Axie Studio - Complete Application Build

################################
# BUILDER-BASE
# Used to build deps + create our virtual environment
################################

# Use standard Python image
FROM python:3.12.3-slim AS builder

# Install the project into `/app`
WORKDIR /app

RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install --no-install-recommends -y \
    # deps for building python deps
    build-essential \
    git \
    # npm
    npm \
    # gcc
    gcc \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install UV for dependency export only
RUN pip install uv

# Copy the package configuration files and source code
COPY src/backend/base/pyproject.toml /app/
COPY src/backend/base/uv.lock /app/
COPY src/backend/base/README.md /app/
COPY src/backend/base/axiestudio/ /app/axiestudio/

# Create virtual environment
RUN python -m venv /app/.venv
ENV PATH="/app/.venv/bin:$PATH"

# Export dependencies from uv.lock to requirements.txt and install with pip
RUN uv export --no-dev --no-hashes > requirements.txt && \
    pip install --no-cache-dir -r requirements.txt

# Install the local package in editable mode
RUN pip install --no-cache-dir -e .

# Copy frontend files
COPY src/frontend/ /app/src/frontend/

# Build frontend
WORKDIR /app/src/frontend
RUN npm ci \
    && npm run build \
    && cp -r build /app/axiestudio/frontend

# Return to app directory
WORKDIR /app

# Install PostgreSQL dependencies for database connectivity
RUN pip install --no-cache-dir "sqlalchemy[postgresql_psycopg2binary]>=2.0.38,<3.0.0" "sqlalchemy[postgresql_psycopg]>=2.0.38,<3.0.0"

################################
# RUNTIME
# Setup user, utilities and copy the virtual environment only
################################
FROM python:3.12.3-slim AS runtime

RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y curl git libpq5 gnupg \
    && curl -fsSL https://deb.nodesource.com/setup_18.x | bash - \
    && apt-get install -y nodejs \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && useradd user -u 1000 -g 0 --no-create-home --home-dir /app/data

COPY --from=builder --chown=1000 /app/.venv /app/.venv

# Place executables in the environment at the front of the path
ENV PATH="/app/.venv/bin:$PATH"

# Labels for container metadata
LABEL org.opencontainers.image.title=axiestudio
LABEL org.opencontainers.image.authors=['Axie Studio']
LABEL org.opencontainers.image.licenses=MIT
LABEL org.opencontainers.image.url=https://github.com/OGGsd/properaxiestudio
LABEL org.opencontainers.image.source=https://github.com/OGGsd/properaxiestudio

USER user
WORKDIR /app

# Environment variables for Axie Studio
ENV AXIESTUDIO_HOST=0.0.0.0
ENV AXIESTUDIO_PORT=7860

# Expose the port
EXPOSE 7860

# Start the application
CMD ["axiestudio", "run"]
