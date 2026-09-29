# Use the official hermes-webui image as base
FROM ghcr.io/nesquena/hermes-webui:latest

USER root

# 1. Install git and curl
RUN apt-get update && apt-get install -y --no-install-recommends git curl && rm -rf /var/lib/apt/lists/*

# 2. Clone the latest agent source directly into the image
WORKDIR /opt
RUN rm -rf /opt/hermes-agent && \
    git clone https://github.com/NousResearch/hermes-agent.git /opt/hermes-agent

# 3. Add /opt/hermes-agent to global Python path so every venv sees it
RUN echo "/opt/hermes-agent" > /usr/local/lib/python3.12/site-packages/hermes-agent.pth

# 4. Set directory ownership for hermeswebui
RUN chown -R 1000:1000 /opt/hermes-agent

# 5. Keep as root for entrypoint initialization
USER root

WORKDIR /app