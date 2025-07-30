# syntax=docker/dockerfile:1
# Dockerfile for DigitalOcean App Platform deployment
# Axie Studio - Complete Application Build

################################
# BUILDER STAGE
################################
FROM python:3.12.3-slim AS builder

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get upgrade -y && apt-get install -y --no-install-recommends \
    build-essential \
    git \
    npm \
    gcc \
 && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install UV for dependency management
RUN pip install uv

# Copy entire project (adjust .dockerignore to skip unnecessary files)
COPY . /app/

# Create virtual environment
RUN python -m venv /app/.venv
ENV PATH="/app/.venv/bin:$PATH"

# Install Python dependencies (prod only)
RUN uv sync --frozen --no-dev

# Build frontend
WORKDIR /app/src/frontend
RUN npm ci && npm run build && cp -r build /app/axiestudio/frontend

################################
# RUNTIME STAGE
################################
FROM python:3.12.3-slim AS runtime

# Create non-root user and prepare app directory
RUN useradd user -u 1000 -g 0 --no-create-home --home-dir /app \
 && mkdir -p /app && chown -R 1000:0 /app

# Install runtime dependencies
RUN apt-get update && apt-get upgrade -y && apt-get install -y \
    git \
    curl \
    libpq5 \
 && apt-get clean && rm -rf /var/lib/apt/lists/*

# Copy virtual environment from builder
COPY --from=builder --chown=1000:0 /app/.venv /app/.venv

# Set environment path
ENV PATH="/app/.venv/bin:$PATH"

# Copy application code (including frontend build)
COPY --from=builder --chown=1000:0 /app /app

# Set labels
LABEL org.opencontainers.image.title="axiestudio"
LABEL org.opencontainers.image.authors='Axie Studio'
LABEL org.opencontainers.image.licenses="MIT"
LABEL org.opencontainers.image.url="https://github.com/OGGsd/properaxiestudio"
LABEL org.opencontainers.image.source="https://github.com/OGGsd/properaxiestudio"

# Switch to non-root user
USER user
WORKDIR /app

# App env
ENV AXIESTUDIO_HOST=0.0.0.0
ENV AXIESTUDIO_PORT=7860

# Expose port
EXPOSE 7860

# Launch the app
CMD ["axiestudio", "run"]
