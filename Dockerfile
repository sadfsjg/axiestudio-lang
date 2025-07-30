# syntax=docker/dockerfile:1
# Keep this syntax directive! It's used to enable Docker BuildKit

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
    build-essential \
    git \
    npm \
    gcc \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Copy dependency files first for better caching
COPY uv.lock pyproject.toml ./
COPY src/backend/base/uv.lock src/backend/base/pyproject.toml ./src/backend/base/

# Install Python dependencies
RUN uv sync --frozen --no-editable --extra postgresql

# Copy source code
COPY ./src /app/src

# Build frontend
COPY src/frontend /tmp/src/frontend
WORKDIR /tmp/src/frontend
RUN npm ci \
    && NODE_OPTIONS="--max-old-space-size=4096" npm run build \
    && cp -r build /app/src/backend/base/axiestudio/frontend \
    && rm -rf /tmp/src/frontend

WORKDIR /app

# Install the backend package with entry points (like original Langflow)
RUN cd src/backend/base && uv pip install --editable .[postgresql]

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

# Copy source code to runtime (needed for the package to work)
COPY --from=builder --chown=1000 /app/src /app/src

# Place executables in the environment at the front of the path
ENV PATH="/app/.venv/bin:$PATH"

# Health check
HEALTHCHECK --interval=30s --timeout=30s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:7860/health || exit 1

LABEL org.opencontainers.image.title=axiestudio
LABEL org.opencontainers.image.authors=['Axie Studio']
LABEL org.opencontainers.image.licenses=MIT
LABEL org.opencontainers.image.url=https://github.com/axiestudio-ai/axiestudio
LABEL org.opencontainers.image.source=https://github.com/axiestudio-ai/axiestudio

USER user
WORKDIR /app

ENV AXIESTUDIO_HOST=0.0.0.0
ENV AXIESTUDIO_PORT=7860

CMD ["axiestudio", "run"]
