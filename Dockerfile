# Use the official hermes-webui image as base
FROM ghcr.io/nesquena/hermes-webui:latest

USER root

# 1. Install git in case the base image doesn't have it
RUN apt-get update && apt-get install -y --no-install-recommends git curl && rm -rf /var/lib/apt/lists/*

# 2. Clone the latest agent source directly into the image
WORKDIR /opt
RUN rm -rf /opt/hermes-agent && \
    git clone https://github.com/NousResearch/hermes-agent.git /opt/hermes-agent

# 3. Install the agent and critical runtime tool dependencies into WebUI's venv
RUN /app/venv/bin/pip install --no-cache-dir --upgrade pip setuptools wheel && \
    /app/venv/bin/pip install --no-cache-dir -e /opt/hermes-agent && \
    /app/venv/bin/pip install --no-cache-dir python-dotenv requests httpx

# 4. Fix permissions so the unprivileged runtime user (hermeswebui: 1000:1000) owns everything
RUN chown -R 1000:1000 /opt/hermes-agent /app/venv

# 5. Switch back to the unprivileged hermeswebui user
USER hermeswebui

WORKDIR /app