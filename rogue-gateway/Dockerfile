FROM python:3.11-slim

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    nodejs \
    npm \
    git \
    && rm -rf /var/lib/apt/lists/*

# Install OpenCode CLI (first adapter)
RUN curl -fsSL https://opencode.ai/install.sh | sh

COPY pyproject.toml uv.lock ./
COPY rogue-gateway/ ./rogue-gateway/

RUN pip install --no-cache-dir uv && \
    cd rogue-gateway && \
    uv sync --frozen --no-dev

ENV ROGUE_PORT=8787

EXPOSE 8787

CMD ["python", "-m", "uvicorn", "rogue_gateway.main:app", "--host", "0.0.0.0", "--port", "8787"]
