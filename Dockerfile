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

# Copy entire project (adjust .dockerignore to skip unnecessary files)
COPY . /app/

# Create virtual environment
RUN python -m venv /app/.venv
ENV PATH="/app/.venv/bin:$PATH"

# Install Python dependencies using pip for production reliability
WORKDIR /app/src/backend/base
RUN pip install --upgrade pip && \
    pip install -e . && \
    pip install openai>=1.0.0 redis>=5.0.0 celery>=5.3.0 flower>=2.0.0 webrtcvad>=2.0.10 && \
    pip install langchain-openai langchain-community langchain-core langchainhub && \
    pip install beautifulsoup4 cohere apify-client && \
    pip install langchain-ollama langchain-mistralai langchain-sambanova && \
    pip install langchain-unstructured langchain-nvidia-ai-endpoints && \
    pip install tiktoken cleanlab-tlm astra-assistants metaphor-python && \
    pip install litellm gitpython google-api-python-client && \
    pip install yfinance googleapiclient twelvelabs astrapy && \
    pip install toml composio mem0

# Build frontend
WORKDIR /app/src/frontend
ENV NODE_OPTIONS="--max-old-space-size=8192"
ENV NPM_CONFIG_CACHE="/tmp/.npm"
RUN npm ci --no-audit --no-fund && \
    NODE_OPTIONS="--max-old-space-size=8192" npm run build && \
    cp -r build /app/src/backend/base/axiestudio/frontend

################################
# RUNTIME STAGE
################################
FROM python:3.12.3-slim AS runtime

WORKDIR /app

# Install runtime dependencies only
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Copy virtual environment from builder
COPY --from=builder /app/.venv /app/.venv
ENV PATH="/app/.venv/bin:$PATH"

# Copy application code
COPY --from=builder /app/src/backend/base /app/src/backend/base
COPY --from=builder /app/src/backend/base/axiestudio/frontend /app/src/backend/base/axiestudio/frontend

# Set working directory to the base package
WORKDIR /app/src/backend/base

# Create necessary directories
RUN mkdir -p /app/src/backend/base/axiestudio/frontend

# Expose port
EXPOSE 7860

# Health check
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:7860/health_check || exit 1

# Set environment variables
ENV PYTHONPATH="/app/src/backend/base"
ENV AXIESTUDIO_CONFIG_DIR="/app/config"
ENV AXIESTUDIO_CACHE_DIR="/app/cache"

# Create config and cache directories
RUN mkdir -p /app/config /app/cache

# Run the application
CMD ["axiestudio", "run", "--host", "0.0.0.0", "--port", "7860"]
