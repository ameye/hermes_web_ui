# Use the official hermes-webui image as base
FROM ghcr.io/nesquena/hermes-webui:latest

USER root

# 1. Install system utilities
RUN apt-get update && apt-get install -y --no-install-recommends git curl procps && rm -rf /var/lib/apt/lists/*

# 2. Clone the latest agent source directly into /opt/hermes-agent
WORKDIR /opt
RUN rm -rf /opt/hermes-agent /opt/hermes && \
    git clone https://github.com/NousResearch/hermes-agent.git /opt/hermes-agent && \
    ln -s /opt/hermes-agent /opt/hermes

# 3. Create standard symlink where hermeswebui_init.bash looks by default
RUN mkdir -p /home/hermeswebui/.hermes && \
    ln -s /opt/hermes-agent /home/hermeswebui/.hermes/hermes-agent

# 4. Install dependencies into /app/venv
# Force standard binary wheels for pydantic and pydantic-core
ENV VIRTUAL_ENV=/app/venv
ENV PATH="/app/venv/bin:$PATH"

RUN /app/venv/bin/pip install --no-cache-dir --upgrade pip && \
    /app/venv/bin/pip install --no-cache-dir --only-binary=:all: \
        pydantic-core \
        pydantic && \
    /app/venv/bin/pip install --no-cache-dir \
        python-dotenv \
        requests \
        httpx \
        "ruamel.yaml>=0.18.0" \
        psutil \
        openai \
        rich \
        prompt-toolkit && \
    /app/venv/bin/pip install --no-cache-dir -e /opt/hermes-agent

# Verify pydantic-core loads correctly during build
RUN /app/venv/bin/python -c "import pydantic_core; print('pydantic_core successfully loaded')"

# 5. Place hermes.pth in Python site-packages
RUN /app/venv/bin/python -c "import site, os; p = site.getsitepackages()[0]; open(os.path.join(p, 'hermes_agent.pth'), 'w').write('/opt/hermes-agent\n')" && \
    if [ -d "/usr/local/lib/python3.12/site-packages" ]; then echo "/opt/hermes-agent" > /usr/local/lib/python3.12/site-packages/hermes_agent.pth; fi

# 6. Ensure correct permissions for UID 1000
RUN chown -R 1000:1000 /opt/hermes-agent /opt/hermes /app/venv /home/hermeswebui 2>/dev/null || true

# 7. Keep root so hermeswebui_init.bash handles runtime UID/GID switching
USER root

WORKDIR /app
