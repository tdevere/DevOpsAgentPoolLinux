# Use Microsoft’s Ubuntu-based Azure Pipelines agent image
FROM ubuntu:22.04

# Switch to root to install extra packages if needed
USER root

# Install common tools (e.g. bash, curl, ca-certs)
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      bash \
      curl \
      jq \
      ca-certificates \
 && rm -rf /var/lib/apt/lists/*

# Copy entrypoint
COPY start.sh /azp/start.sh
RUN chmod +x /azp/start.sh

# Switch to the agent working directory
WORKDIR /azp

# Entrypoint
ENTRYPOINT ["bash", "/azp/start.sh"]
