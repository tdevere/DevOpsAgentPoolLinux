# escape=`
FROM mcr.microsoft.com/windows/servercore:ltsc2022

WORKDIR /azp

# Copy the agent bootstrap script
COPY start.ps1 .

# Run the bootstrap script when the container starts
ENTRYPOINT ["powershell", "-NoLogo", "-Sta", "-NoProfile", "-NonInteractive", "C:\\azp\\start.ps1"]
