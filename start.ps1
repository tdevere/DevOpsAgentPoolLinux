function Print-Header ($header) {
  Write-Host "`n${header}`n" -ForegroundColor Cyan
}

if (-not $Env:AZP_URL) {
  Write-Error "missing AZP_URL"
  exit 1
}
if (-not $Env:AZP_TOKEN) {
  Write-Error "missing AZP_TOKEN"
  exit 1
}

# Persist token to a file and remove it from env
$tokenFile = "C:\azp\.token"
$Env:AZP_TOKEN | Out-File -Encoding ASCII -FilePath $tokenFile
Remove-Item Env:AZP_TOKEN

# Prepare work directory
if ($Env:AZP_WORK) {
  New-Item -ItemType Directory -Path $Env:AZP_WORK -Force | Out-Null
}

New-Item -ItemType Directory -Path "C:\azp\agent" -Force | Out-Null
$Env:VSO_AGENT_IGNORE = "AZP_TOKEN,AZP_TOKEN_FILE"
Set-Location C:\azp\agent

Print-Header "1. Downloading Azure Pipelines agent..."
$base64Auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$(Get-Content $tokenFile)"))
$pkg = Invoke-RestMethod -Headers @{ Authorization = "Basic $base64Auth" } `
  "$($Env:AZP_URL)/_apis/distributedtask/packages/agent?platform=win-x64&`$top=1"
$downloadUrl = $pkg.value[0].downloadUrl

$wc = New-Object System.Net.WebClient
$wc.DownloadFile($downloadUrl, "agent.zip")
Expand-Archive -Path "agent.zip" -DestinationPath "C:\azp\agent"

Print-Header "2. Configuring agent..."
.\config.cmd --unattended `
  --agent    "${Env:AZP_AGENT_NAME:-$(hostname)}" `
  --url      "$Env:AZP_URL" `
  --auth     PAT `
  --token    "$(Get-Content $tokenFile)" `
  --pool     "${Env:AZP_POOL:-Default}" `
  --work     "${Env:AZP_WORK:-_work}" `
  --replace

Print-Header "3. Running agent..."
.\run.cmd
