# Azure DevOps Self-Hosted Linux Agents

This repository provides a turnkey solution to deploy **two** self-hosted **Linux** agents into an Azure DevOps pool named **SelfHostedLinux** using Docker containers. The setup is **idempotent**, **restart-resilient**, and includes live download progress, automatic registration, and robust troubleshooting guidance.

---

## 📁 Repository Structure

```

DevOpsAgentPoolLinux/
├── .env                  # Personal Access Token and organization URL (ignored by Git)
├── Dockerfile            # Builds the Ubuntu-based Azure Pipelines agent container
├── docker-compose.yml    # Defines two agent services with restart policies and persistent volumes
├── start.sh              # Bootstrap script: download, extract, configure, run agent
└── README.md             # This documentation

````


## 🔧 Prerequisites

1. **Docker** installed (Linux containers) and running.  
2. An **Azure DevOps** organization (e.g. `https://dev.azure.com/AzDevOpsSampleOrg`).  
3. A **Personal Access Token (PAT)** with **Agent Pools (read & manage)** scope.  
4. A pool named **SelfHostedLinux** under **Organization Settings → Agent pools**.

> **Do NOT** commit your PAT or `.env` to source control—this file is ignored by Git.


## ⚙️ Configuration

1. **`.env`**  
   Create a file at the repo root:
   ```dotenv
   AZP_URL=https://dev.azure.com/AzDevOpsSampleOrg   # Your DevOps org URL
   AZP_TOKEN=YOUR_PERSONAL_ACCESS_TOKEN             # PAT with Agent Pools scope
   AZP_POOL=SelfHostedLinux                         # Target agent pool name

2. **Environment variables**

   * In `docker-compose.yml`, each service reads `AZP_URL`, `AZP_TOKEN`, `AZP_POOL`, and `AZP_AGENT_NAME`.
   * Inside the container, the bootstrap script uses these vars to install and register the agent.

3. **Persistent Volumes**

   * `agent1_work` and `agent2_work` volumes map to `/azp/_work` inside each container.
   * This preserves the agent’s workspace across restarts, avoiding repeated downloads or configuration.

4. **Restart Policy**

   * Each service uses `restart: unless-stopped` to ensure the containers auto-start on host reboot.

---

## 🚀 Getting Started

1. **Clone** this repository and `cd` into it:

   ```bash
   git clone https://github.com/tdevere/DevOpsAgentPoolLinux.git
   cd DevOpsAgentPoolLinux
   ```

2. **Create** your `.env` as described above.

3. **Launch** the agents:

   ```bash
   docker-compose up -d    # Builds images and starts agent1 & agent2
   ```

4. **Monitor logs**:

   ```bash
   docker-compose logs -f agent1
   ```

   You will see:

   * Download progress
   * Extraction and configuration steps
   * Agent connecting messages like “Listening for Jobs”

5. **Verify in Azure DevOps**:

   * Go to **Organization Settings → Agent pools → SelfHostedLinux**.
   * Both `agent-linux-1` and `agent-linux-2` should appear **Online**.

---

## 🔄 Upgrades & Maintenance

* **Updating the agent version**: The bootstrap script (`start.sh`) always pulls the latest `linux-x64` agent from Microsoft’s API. No manual downloads needed.
* **Changing agent names**: Edit `AZP_AGENT_NAME` in `docker-compose.yml` or override via `.env`.
* **Adding more agents**: Copy one service block in `docker-compose.yml`, assign unique names, and create new volumes.

---

## 🛠️ Troubleshooting

### Check container status

```bash
docker ps
docker-compose ps
```

### Inspect logs

```bash
docker-compose logs -f agent1
```

### Exec into container

```bash
docker exec -it azp-agent-linux-1 bash
# e.g., cd /azp/_work, ls, ./config.sh --help
```

### Common issues

* **Missing `config.sh` or `run.sh`**: Indicates the agent tools ZIP didn’t download. Check network or API access.
* **Invalid volume mount**: Ensure you use Linux paths (`/azp/_work`), not Windows paths.
* **Env vars not loaded**: Confirm no extra whitespace/newlines in `.env`, and run `docker-compose up` from the repo root.

---

## 📋 FAQ & Notes

**Q: Will the agent re-download on every container restart?**
A: No. With persistent volumes and the `--unattended` guard, subsequent restarts skip the install and immediately run the existing agent.

**Q: How do I remove an agent from the pool?**
A: Stop & remove the container with `docker-compose down`, then in Azure DevOps UI disable or delete the agent entry.

**Q: Can I bind-mount a host folder for the agent work directory?**
A: Yes—replace the named volume with `./agent1_work:/azp/_work`, but ensure folder permissions are correct.

---

## 🔗 References

* [Azure DevOps Agent Pools & Agents](https://docs.microsoft.com/azure/devops/pipelines/agents/pools-queues)
* [Docker Compose restart policies](https://docs.docker.com/compose/compose-file/compose-file-v3/#restart)
* [Azure Pipelines Agent API docs](https://docs.microsoft.com/azure/devops/pipelines/agents/agent-v2-linux)

---

## Line Endings / Encoding (Windows → Linux)

If you’re authoring or modifying any scripts (`*.sh`) on Windows, Git’s default behavior may convert LF (Unix) line endings to CRLF (Windows) when you commit. This can break the startup scripts inside the Linux-based agents.

1. **Add a `.gitattributes` rule**
   Make sure you have this line in your `.gitattributes` (repo root):

   ```gitattributes
   *.sh text eol=lf
   ```

   That forces Git to keep LF endings for all `.sh` files, no matter the platform.

2. **Normalize existing line endings**
   If you’ve already committed scripts with CRLF, run:

   ```bash
   git add --renormalize .
   git commit -m "Normalize line endings for shell scripts"
   ```

   This rewrites any `*.sh` to use LF on disk and in the repo. After this, you won’t see warnings like:

   ```
   warning: in the working copy of 'start.sh', LF will be replaced by CRLF the next time Git touches it
   ```

3. **Configure your local Git (optional)**
   If you prefer not to rely on `.gitattributes`, you can set:

   ```bash
   # On Windows, to stop CRLF insertion on checkout:
   git config core.autocrlf input
   ```

   * `input` means “convert CRLF→LF on commit, but leave LF alone on checkout.”
   * Alternatively, `git config core.autocrlf false` disables all conversions—Git will preserve whatever line endings are already in the repo.

**Why this matters:**

* The Azure Pipelines agent’s `start.sh` (and other helper scripts) must have LF endings so that `bash` on Linux won’t see stray carriage returns (`^M`) and fail.
* By forcing `eol=lf`, you ensure any collaborator on Windows still commits the correct format.

---

*Maintainer: tdevere — feel free to open issues or pull requests!*

```
