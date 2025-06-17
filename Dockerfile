FROM ubuntu:22.04

# Set agent version and Java/Maven environment
ARG AGENT_VERSION=4.255.0
ENV AGENT_VERSION=${AGENT_VERSION} \
    JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64 \
    JAVA_HOME_11_X64=/usr/lib/jvm/java-11-openjdk-amd64 \
    MAVEN_HOME=/usr/share/maven \
    M2_HOME=/usr/share/maven \
    PATH=${PATH}:${MAVEN_HOME}/bin

# 1) Install base packages, OpenJDK 11, and Maven
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      bash \
      curl \
      tar \
      git \
      ca-certificates \
      libssl-dev \
      openjdk-11-jdk-headless \
      maven && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# 3) Create /azp, download & unzip the agent
RUN mkdir /azp
WORKDIR /azp
RUN curl -LsS \
      https://download.agent.dev.azure.com/agent/${AGENT_VERSION}/vsts-agent-linux-x64-${AGENT_VERSION}.tar.gz \
    | tar -xz --no-same-owner

# 4) Install all missing .NET dependencies
RUN /azp/bin/installdependencies.sh

# 4.1) Azure CLI
# (After base package install)
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash && \
    apt-get install -y azure-cli && \
    curl -sL https://aka.ms/downloadazcopy-v10-linux | tar -xz && \
    cp ./azcopy_linux_amd64_*/azcopy /usr/bin/ && \
    chmod +x /usr/bin/azcopy && \
    rm -rf azcopy_linux_amd64_*


# 5) Create and configure 'agent' user
RUN useradd --create-home agent \
    && mkdir -p /azp/_work /azp/_tool \
    && chown -R agent:agent /azp

# 6) Copy start.sh and set permissions
COPY ./start.sh /azp/start.sh
RUN chmod +x /azp/start.sh \
    && chown agent:agent /azp/start.sh

# 7) Switch to non-root user
USER agent

# 8) Start entrypoint
ENTRYPOINT ["/azp/start.sh"]