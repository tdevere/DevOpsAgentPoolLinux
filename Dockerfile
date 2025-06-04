FROM ubuntu:22.04

# 1) Install base packages (bash, curl, tar, etc.)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      bash \
      curl \
      tar \
      ca-certificates \
      libssl-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# 2) Set agent version
ARG AGENT_VERSION=4.255.0
ENV AGENT_VERSION=${AGENT_VERSION}

# 3) Create /azp, download & unzip the agent
RUN mkdir /azp
WORKDIR /azp
RUN curl -LsS \
      https://vstsagentpackage.azureedge.net/agent/${AGENT_VERSION}/vsts-agent-linux-x64-${AGENT_VERSION}.tar.gz \
    | tar -xz --no-same-owner

# 4) Install all missing .NET dependencies (including libicu, krb, etc.)
RUN /azp/bin/installdependencies.sh

# 5) Create and chown the “agent” user
RUN useradd --create-home agent \
    && chown -R agent:agent /azp

# 6) Copy start.sh and set permissions (still as root)
COPY ./start.sh /azp/start.sh
RUN chmod +x /azp/start.sh \
    && chown agent:agent /azp/start.sh

# 7) Switch to non-root “agent”
USER agent

ENTRYPOINT ["/azp/start.sh"]
