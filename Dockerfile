# Use the official hermes-webui image as base
FROM ghcr.io/nesquena/hermes-webui:latest

USER root

# 1. Install git and curl if not present
RUN apt-get update && apt-get install -y --no-install-recommends git curl && rm -rf /var/lib/apt/lists/*

# 2. Clone the latest agent source directly into the image
WORKDIR /opt
RUN rm -rf /opt/hermes-agent && \
    git clone https://github.com/NousResearch/hermes-agent.git /opt/hermes-agent

# 3. Create /app/venv explicitly and install packages into it
ENV VIRTUAL_ENV=/app/venv
RUN uv venv /app/venv --python /usr/local/bin/python3 && \
    uv pip install -e /opt/hermes-agent && \
    uv pip install python-dotenv requests httpx

# 4. Fix permissions
RUN chown -R 1000:1000 /opt/hermes-agent /app/venv 2>/dev/null || true

# 5. Keep as root so the base image entrypoint can initialize UID/GID correctly
USER root

WORKDIR /app