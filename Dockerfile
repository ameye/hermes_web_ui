# Use the official hermes-webui image as base
FROM ghcr.io/nesquena/hermes-webui:latest

USER root

# 1. Install system utilities
RUN apt-get update && apt-get install -y --no-install-recommends git curl procps && rm -rf /var/lib/apt/lists/*

# 2. Clone the latest agent source directly into the image
WORKDIR /opt
RUN rm -rf /opt/hermes-agent && \
    git clone https://github.com/NousResearch/hermes-agent.git /opt/hermes-agent

# 3. Create /app/venv and install WebUI + Agent dependencies in one shot
ENV VIRTUAL_ENV=/app/venv
RUN uv venv /app/venv --python /usr/local/bin/python3 && \
    uv pip install --python /app/venv/bin/python \
        python-dotenv \
        requests \
        httpx \
        "ruamel.yaml>=0.18.0" \
        psutil \
        openai \
        pydantic \
        rich \
        prompt-toolkit && \
    uv pip install --python /app/venv/bin/python -e /opt/hermes-agent

# 4. Permanently register /opt/hermes-agent in site-packages
RUN /app/venv/bin/python -c "import site, os; p = site.getsitepackages()[0]; open(os.path.join(p, 'hermes_agent.pth'), 'w').write('/opt/hermes-agent\n')"

# 5. Fix permissions so UID 1000 owns both directories
RUN chown -R 1000:1000 /opt/hermes-agent /app/venv 2>/dev/null || true

# 6. Keep container starting as root so hermeswebui_init.bash handles runtime UID mapping
USER root

WORKDIR /app