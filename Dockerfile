# Use the official hermes-webui image as base
FROM ghcr.io/nesquena/hermes-webui:latest

USER root

# 1. Install system utilities + Rust build tools (needed if pydantic-core compiles from source)
RUN apt-get update && apt-get install -y --no-install-recommends \
    git curl procps build-essential \
    && rm -rf /var/lib/apt/lists/*

# 2. Clone the latest agent source directly into /opt/hermes-agent
WORKDIR /opt
RUN rm -rf /opt/hermes-agent /opt/hermes && \
    git clone https://github.com/NousResearch/hermes-agent.git /opt/hermes-agent && \
    ln -s /opt/hermes-agent /opt/hermes

# 3. Create standard symlink where hermeswebui_init.bash looks by default
RUN mkdir -p /home/hermeswebui/.hermes && \
    ln -s /opt/hermes-agent /home/hermeswebui/.hermes/hermes-agent

# 4. Create base /app/venv using Python 3.12
ENV VIRTUAL_ENV=/app/venv
ENV PATH="/app/venv/bin:$PATH"

RUN uv venv /app/venv --python python3.12 && \
    uv pip install --python /app/venv/bin/python --no-cache \
        python-dotenv \
        requests \
        httpx \
        "ruamel.yaml>=0.18.0" \
        psutil \
        openai \
        rich \
        prompt-toolkit && \
    uv pip install --python /app/venv/bin/python --no-cache -e /opt/hermes-agent && \
    uv pip install --python /app/venv/bin/python --no-cache --reinstall \
        pydantic-core \
        pydantic

# 5. Place hermes.pth in Python site-packages
RUN /app/venv/bin/python -c "import site, os; p = site.getsitepackages()[0]; open(os.path.join(p, 'hermes_agent.pth'), 'w').write('/opt/hermes-agent\n')"

# 6. Ensure clean permissions and clear any stale installs
RUN rm -rf /home/hermeswebui/.hermes/installs && \
    chown -R 1000:1000 /opt/hermes-agent /opt/hermes /app/venv /home/hermeswebui 2>/dev/null || true

USER root

WORKDIR /app
