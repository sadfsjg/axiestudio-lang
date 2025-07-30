# syntax=docker/dockerfile:1
# Dockerfile for DigitalOcean App Platform deployment
# Axie Studio - Complete Application Build

################################
# BUILDER-BASE
# Used to build deps + create our virtual environment
################################

# Use a Python image with uv pre-installed
FROM ghcr.io/astral-sh/uv:python3.12-bookworm-slim AS builder

# Install the project into `/app`
WORKDIR /app

# Enable bytecode compilation
ENV UV_COMPILE_BYTECODE=1

# Copy from the cache instead of linking since it's a mounted volume
ENV UV_LINK_MODE=copy

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

# Copy dependency files
COPY uv.lock pyproject.toml ./
COPY src/backend/base/README.md src/backend/base/README.md
COPY src/backend/base/uv.lock src/backend/base/uv.lock
COPY src/backend/base/pyproject.toml src/backend/base/pyproject.toml

# Install Python dependencies
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --frozen --no-install-project --no-editable

# Copy source code
COPY ./src /app/src

# Build frontend
COPY src/frontend /tmp/src/frontend
WORKDIR /tmp/src/frontend
RUN --mount=type=cache,target=/root/.npm \
    npm ci \
    && npm run build \
    && cp -r build /app/src/backend/axiestudio/frontend \
    && rm -rf /tmp/src/frontend

# Install the project
WORKDIR /app
COPY ./pyproject.toml /app/pyproject.toml
COPY ./uv.lock /app/uv.lock

RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --frozen --no-editable

# Install PostgreSQL dependencies for database connectivity
RUN --mount=type=cache,target=/root/.cache/uv \
    uv add "sqlalchemy[postgresql_psycopg2binary]>=2.0.38,<3.0.0" "sqlalchemy[postgresql_psycopg]>=2.0.38,<3.0.0"

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
