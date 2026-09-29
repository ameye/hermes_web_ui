# Use the official hermes-webui image as base
FROM ghcr.io/nesquena/hermes-webui:latest

USER root

# 1. Install git and curl if not present
RUN apt-get update && apt-get install -y --no-install-recommends git curl && rm -rf /var/lib/apt/lists/*

# 2. Clone the latest agent source directly into the image
WORKDIR /opt
RUN rm -rf /opt/hermes-agent && \
    git clone https://github.com/NousResearch/hermes-agent.git /opt/hermes-agent

# 3. Create /app/venv explicitly and install agent + runtime requirements using uv
RUN uv venv /app/venv --python /usr/local/bin/python3 && \
    uv pip install --system=false --python /app/venv/bin/python -e /opt/hermes-agent && \
    uv pip install --system=false --python /app/venv/bin/python python-dotenv requests httpx

# 4. Fix permissions so the unprivileged runtime user (1000:1000) owns both folders
RUN chown -R 1000:1000 /opt/hermes-agent /app/venv

# 5. Switch back to hermeswebui user
USER hermeswebui

WORKDIR /app