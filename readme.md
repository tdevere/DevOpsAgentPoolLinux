# Azure DevOps Self‑Hosted Windows Agents

This repository provides a turnkey solution to deploy **two** self‑hosted Windows agents into an Azure DevOps pool named **SelfHostedWindows** using Docker containers. The setup is **idempotent**, **restart‑resilient**, and includes live download progress, automatic registration, and robust troubleshooting guidance.

---

## 📁 Repository Structure

```
AgentPoolWindows/
├── .env                  # Personal Access Token and organization URL (not checked into source)
├── Dockerfile            # Builds the Windows Server Core agent container
├── docker-compose.yml    # Defines two agent services with restart policies and persistent volumes
├── start.ps1             # Bootstrap script: download, extract, configure, run agent
└── README.md             # This documentation
```

---

## 🔧 Prerequisites

1. **Docker for Windows** (Windows containers mode) installed and configured to start on login or as a service.
2. A **Azure DevOps** organization (e.g. `https://dev.azure.com/AzDevOpsSampleOrg`).
3. A **Personal Access Token (PAT)** with **Agent Pools (read & manage)** scope.
4. A pool named **SelfHostedWindows** under **Organization Settings → Agent pools**.

> **Do NOT** commit your PAT or `.env` to the repository. This file is ignored by `.gitignore`.

---

## ⚙️ Configuration

1. **`.env`**
   Create a file at the repo root:

   ```ini
   AZP_URL=https://dev.azure.com/AzDevOpsSampleOrg   # Your DevOps org (not the ZIP URL!)
   AZP_TOKEN=YOUR_PERSONAL_ACCESS_TOKEN             # PAT with correct scopes
   AZP_POOL=SelfHostedWindows                       # Target agent pool name
   ```

2. **Environment variables**

   * In `docker-compose.yml`, each service sets `AZP_URL`, `AZP_TOKEN`, `AZP_POOL`, and `AZP_AGENT_NAME`.

   * Inside the container, PowerShell reads these as `$Env:AZP_URL`, `$Env:AZP_TOKEN`, etc.

   > **Common confusion**: `AZP_URL` must point to your **organization URL**, *not* the agent ZIP download link.

3. **Persistent Volumes**

   * `agent1_agent` and `agent1_work` volumes map to `C:\azp\agent` and `C:\azp\agent\_work` respectively.
   * This preserves the agent install and workspace across restarts, preventing repeated downloads/config.

4. **Restart Policy**

   * Each service uses `restart: always` to ensure the containers auto‑start on host reboot.

---

## 🚀 Getting Started

1. **Switch Docker to Windows containers** (if not already).

2. **Clone** this repository and `cd` into it.

3. **Create** your `.env` as above.

4. **Launch** the agents:

   ```powershell
   docker-compose up -d    # Builds images and starts agent1 & agent2
   ```

5. **Monitor logs**:

   ```powershell
   docker-compose logs -f agent1
   ```

   You will see:

   * Live BITS download progress
   * Extraction
   * Agent configuration
   * "Listening for Jobs"

6. **Verify in Azure DevOps**:

   * Go to **Organization Settings → Agent pools → SelfHostedWindows**.
   * Both `agent-win-1` and `agent-win-2` should appear **Online**.

---

## 🔄 Upgrades & Maintenance

* **Updating the agent version**: The bootstrap script always pulls the latest `win-x64` agent via the REST API. No manual ZIP updates are needed.
* **Changing agent names**: Edit `AZP_AGENT_NAME` in `docker-compose.yml`.
* **Adding more agents**: Copy one service block, give it a unique `container_name`, `AZP_AGENT_NAME`, and new volumes.

---

## 🛠️ Troubleshooting

### Container status

```powershell
docker ps
docker-compose ps
docker inspect -f "{{ .State.Running }}" azp-agent-windows-1   # true/false
```

### Inspect logs

```powershell
docker-compose logs -f agent1
```

### Exec into container

```powershell
docker exec -it azp-agent-windows-1 powershell
# e.g., dir C:\azp\agent, Get-BitsTransfer -AllUsers
```

### Common issues

* **Missing `config.cmd` / `run.cmd`**: Usually means the ZIP never downloaded. Check BITS progress or manual download in the shell.
* **Invalid volume spec**: Ensure Windows paths (`C:\azp\agent`) not Linux paths (`/azp/agent`).
* **Obsolete `version:` warning**: Docker Compose v2 ignores the `version:` line—feel free to remove it.
* **Variables not found**: Confirm `.env` has no trailing whitespace/newlines, and `docker-compose up` is run in the repo root so Compose picks up your `.env`.

---

## 📋 FAQ & Notes

* **Q: Does the agent re-download on every host reboot?**
  A: By default, yes—the full bootstrap runs each time. With persistent volumes and the `if -not (Test-Path .\config.cmd)` guard, subsequent restarts skip download/config and immediately run the already‑installed agent.

* **Q: How to remove an agent from the pool?**
  A: Stop & remove the container: `docker-compose down`. Then, in Azure DevOps UI, manually disable or delete the agent entry.

* **Q: Can I bind‑mount my existing agent install?**
  A: Yes—replace the named volume with `- 'C:\Agents\vsts-agent-win-x64-4.255.0:C:\azp\agent'` but this ties you to that exact host folder.

---

## 🔗 References

* [Azure DevOps Agent Pools & Agents](https://docs.microsoft.com/azure/devops/pipelines/agents/pools-queues)
* [Docker Compose restart policies](https://docs.docker.com/compose/compose-file/compose-file-v3/#restart)
* [BITS PowerShell examples](https://docs.microsoft.com/powershell/module/bitstransfer)

---

*Maintainer: tdevere — feel free to open issues or pull requests!*
