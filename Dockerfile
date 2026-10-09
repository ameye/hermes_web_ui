# Use the official hermes-webui image as base
FROM ghcr.io/nesquena/hermes-webui:latest

USER root

# 1. Install system utilities
RUN apt-get update && apt-get install -y --no-install-recommends git curl procps && rm -rf /var/lib/apt/lists/*

# 2. Clone the latest agent source and apply targeted patch to turn_scripted_prelude.py
WORKDIR /opt
RUN rm -rf /opt/hermes-agent /opt/hermes && \
    git clone https://github.com/NousResearch/hermes-agent.git /opt/hermes-agent && \
    ln -s /opt/hermes-agent /opt/hermes && \
    sed -i 's/Prelude = Generator\[tuple\[str, str, dict\], Optional\[str\]\]/Prelude = Generator[tuple[str, str, dict], Optional[str], None]/g' /opt/hermes-agent/agent/turn_scripted_prelude.py

# 3. Create standard symlink where hermeswebui_init.bash looks by default
RUN mkdir -p /home/hermeswebui/.hermes && \
    ln -s /opt/hermes-agent /home/hermeswebui/.hermes/hermes-agent

# 4. Bake dependencies into BOTH system python and /app/venv using uv
ENV VIRTUAL_ENV=/app/venv
ENV PATH="/app/venv/bin:$PATH"

# Install core runtime dependencies into system python
RUN uv pip install --system --no-cache \
        "typing_extensions>=4.12.2" \
        snowballstemmer \
        requests \
        httpx \
        "ruamel.yaml>=0.18.0" \
        psutil \
        openai \
        rich \
        prompt-toolkit \
        python-dotenv

# Initialize /app/venv and install the hermes-agent package using editable mode (-e)
RUN uv venv /app/venv --python /usr/local/bin/python3 && \
    uv pip install --python /app/venv/bin/python --no-cache \
        "typing_extensions>=4.12.2" \
        snowballstemmer \
        requests \
        httpx \
        "ruamel.yaml>=0.18.0" \
        psutil \
        openai \
        rich \
        prompt-toolkit \
        python-dotenv && \
    uv pip install --python /app/venv/bin/python --no-cache -e /opt/hermes-agent && \
    uv pip install --python /app/venv/bin/python --no-cache --upgrade \
        "pydantic>=2.7.0" \
        pydantic-core \
        "typing_extensions>=4.12.2"

# 5. Place hermes.pth in Python site-packages (both system and venv)
RUN /app/venv/bin/python -c "import site, os; p = site.getsitepackages()[0]; open(os.path.join(p, 'hermes_agent.pth'), 'w').write('/opt/hermes-agent\n')" && \
    python3 -c "import site, os; p = site.getsitepackages()[0]; open(os.path.join(p, 'hermes_agent.pth'), 'w').write('/opt/hermes-agent\n')" && \
    python3 -c "import site, os; p = site.getsitepackages()[0]; venv_p = '/app/venv/lib/python' + '.'.join(map(str, __import__('sys').version_info[:2])) + '/site-packages'; open(os.path.join(p, 'app_venv.pth'), 'w').write(venv_p + '\n')"

# 6. Runtime cleanup & environment persistence
RUN printf '#!/bin/bash\n\
export VIRTUAL_ENV=/app/venv\n\
export PATH="/app/venv/bin:$PATH"\n\
rm -rf /home/hermeswebui/.hermes/installs\n\
exec /hermeswebui_init.bash "$@"\n' > /app/start.sh && \
    chmod +x /app/start.sh

# 7. Set permissions
RUN chown -R 1000:1000 /opt/hermes-agent /opt/hermes /app/venv /home/hermeswebui 2>/dev/null || true

USER root

WORKDIR /app

ENTRYPOINT ["/app/start.sh"]
