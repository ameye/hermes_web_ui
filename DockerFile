# Use the official hermes-webui image as base
FROM ghcr.io/nesquena/hermes-webui:latest

# Set working dir
WORKDIR /opt

# Copy your hermes-agent source into the image
# Ensure the directory you copy contains setup.py or pyproject.toml
#COPY hermes-agent /opt/hermes-agent

#33

RUN git clone https://github.com/NousResearch/hermes-agent.git /opt/hermes-agent
# Install the agent into the WebUI venv
# Adjust the venv python path if the base image uses a different path
RUN if [ -x "/app/venv/bin/python" ]; then \
      /app/venv/bin/python -m pip install --upgrade pip setuptools wheel && \
      /app/venv/bin/python -m pip install -e /opt/hermes-agent ; \
    else \
      python3 -m pip install --upgrade pip setuptools wheel && \
      python3 -m pip install -e /opt/hermes-agent ; \
    fi

# (Optional) ensure permissions for non-root user if needed
# RUN chown -R 1000:1000 /opt/hermes-agent

# Keep the original entrypoint/command
