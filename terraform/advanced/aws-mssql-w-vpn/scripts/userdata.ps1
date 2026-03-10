<powershell>
# ═══════════════════════════════════════════════════════
# EC2 Bootstrap — SQL Server Configuration + SSMS Install
#
# SQL Server 2022 Developer is pre-installed on the AMI.
# This script:
#   1. Enables TCP/IP protocol for remote connections
#   2. Enables mixed-mode authentication (Windows + SA)
#   3. Sets the SA password
#   4. Opens Windows Firewall for port 1433
#   5. Downloads and installs SSMS (silent)
#   6. Installs sqlcmd (ODBC 18 + sqlcmd)
# ═══════════════════════════════════════════════════════

$ErrorActionPreference = "Continue"
$logFile = "C:\bootstrap-log.txt"

function Log {
    param([string]$msg)
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$ts - $msg" | Tee-Object -FilePath $logFile -Append
}

Log "=== Bootstrap started ==="

# ─── 1. Enable TCP/IP for SQL Server ──────────────────
Log "Enabling TCP/IP protocol..."
try {
    Import-Module SQLPS -DisableNameChecking -ErrorAction SilentlyContinue

    # Use WMI to enable TCP/IP
    $wmi = New-Object Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer $env:COMPUTERNAME
    $tcp = $wmi.ServerInstances['MSSQLSERVER'].ServerProtocols['Tcp']
    $tcp.IsEnabled = $true
    $tcp.Alter()

    # Set TCP port to 1433 explicitly on all IPs
    foreach ($ipAddress in $tcp.IPAddresses) {
        $ipAddress.IPAddressProperties['TcpPort'].Value = '1433'
        $ipAddress.IPAddressProperties['TcpDynamicPorts'].Value = ''
    }
    $tcp.Alter()

    Log "TCP/IP enabled on port 1433"
} catch {
    Log "TCP/IP config via WMI failed: $_"
    Log "Trying registry-based approach..."

    # Fallback: enable via registry
    $regPath = (Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server" -Recurse |
        Where-Object { $_.PSPath -like "*SuperSocketNetLib\Tcp" -and $_.PSPath -like "*MSSQLSERVER*" } |
        Select-Object -First 1).PSPath

    if ($regPath) {
        Set-ItemProperty -Path $regPath -Name "Enabled" -Value 1
        Log "TCP/IP enabled via registry at $regPath"
    } else {
        Log "WARNING: Could not find TCP registry path"
    }
}

# ─── 2. Enable Mixed Mode Authentication ──────────────
Log "Enabling mixed-mode authentication..."
try {
    # Find the correct MSSQL instance registry path
    $sqlInstance = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL").MSSQLSERVER
    $regPath = "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$sqlInstance\MSSQLServer"

    Set-ItemProperty -Path $regPath -Name "LoginMode" -Value 2
    Log "Mixed mode auth enabled (LoginMode=2)"
} catch {
    Log "WARNING: Could not set LoginMode: $_"
}

# ─── 3. Restart SQL Server to apply changes ────────────
Log "Restarting SQL Server..."
Restart-Service -Name "MSSQLSERVER" -Force
Start-Sleep -Seconds 10

# Wait for SQL Server to be ready
$maxRetries = 30
for ($i = 0; $i -lt $maxRetries; $i++) {
    try {
        $result = Invoke-Sqlcmd -Query "SELECT 1 AS test" -ServerInstance "localhost" -TrustServerCertificate -ErrorAction Stop
        Log "SQL Server is ready"
        break
    } catch {
        Start-Sleep -Seconds 5
    }
}

# ─── 4. Set SA Password ───────────────────────────────
Log "Configuring SA login..."
try {
    $saPass = '${sa_password}'
    Invoke-Sqlcmd -Query "ALTER LOGIN [sa] ENABLE;" -ServerInstance "localhost" -TrustServerCertificate
    Invoke-Sqlcmd -Query "ALTER LOGIN [sa] WITH PASSWORD = N'$saPass', CHECK_POLICY = OFF;" -ServerInstance "localhost" -TrustServerCertificate
    Log "SA login enabled and password set"
} catch {
    Log "WARNING: SA config failed: $_"
}

# ─── 5. Open Windows Firewall ─────────────────────────
Log "Configuring Windows Firewall..."
New-NetFirewallRule -DisplayName "SQL Server 1433 Inbound" `
    -Direction Inbound -Protocol TCP -LocalPort 1433 `
    -Action Allow -Profile Any -ErrorAction SilentlyContinue

New-NetFirewallRule -DisplayName "SQL Server 1434 UDP (Browser)" `
    -Direction Inbound -Protocol UDP -LocalPort 1434 `
    -Action Allow -Profile Any -ErrorAction SilentlyContinue

Log "Firewall rules created for 1433/tcp and 1434/udp"

# ─── 6. Download and Install SSMS ─────────────────────
Log "Downloading SSMS..."
$tempDir = "C:\temp"
New-Item -ItemType Directory -Force -Path $tempDir | Out-Null

$ssmsUrl = "https://aka.ms/ssmsfull"
$ssmsInstaller = "$tempDir\SSMS-Setup-ENU.exe"

try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $webClient = New-Object System.Net.WebClient
    $webClient.DownloadFile($ssmsUrl, $ssmsInstaller)
    Log "SSMS downloaded successfully"

    Log "Installing SSMS (this takes 10-15 minutes)..."
    $process = Start-Process -FilePath $ssmsInstaller `
        -ArgumentList "/install /quiet /norestart" `
        -Wait -PassThru -NoNewWindow

    if ($process.ExitCode -eq 0 -or $process.ExitCode -eq 3010) {
        Log "SSMS installed successfully (exit code: $($process.ExitCode))"
    } else {
        Log "WARNING: SSMS install exited with code $($process.ExitCode)"
    }
} catch {
    Log "WARNING: SSMS download/install failed: $_"
}

# ─── 7. Install ODBC Driver 18 + sqlcmd ───────────────
Log "Installing ODBC Driver 18 and sqlcmd..."
try {
    $odbcUrl = "https://go.microsoft.com/fwlink/?linkid=2249006"
    $odbcInstaller = "$tempDir\msodbcsql.msi"
    $webClient.DownloadFile($odbcUrl, $odbcInstaller)
    Start-Process -FilePath "msiexec.exe" `
        -ArgumentList "/i $odbcInstaller /quiet /norestart IACCEPTMSODBCSQLLICENSETERMS=YES" `
        -Wait -NoNewWindow
    Log "ODBC Driver 18 installed"

    $sqlcmdUrl = "https://go.microsoft.com/fwlink/?linkid=2249007"
    $sqlcmdInstaller = "$tempDir\MsSqlCmdLnUtils.msi"
    $webClient.DownloadFile($sqlcmdUrl, $sqlcmdInstaller)
    Start-Process -FilePath "msiexec.exe" `
        -ArgumentList "/i $sqlcmdInstaller /quiet /norestart IACCEPTMSSQLCMDLNUTILSLICENSETERMS=YES" `
        -Wait -NoNewWindow
    Log "sqlcmd installed"
} catch {
    Log "WARNING: ODBC/sqlcmd install failed: $_"
}

# ─── 8. Restart SQL Agent ─────────────────────────────
Log "Starting SQL Server Agent..."
Set-Service -Name "SQLSERVERAGENT" -StartupType Automatic -ErrorAction SilentlyContinue
Start-Service -Name "SQLSERVERAGENT" -ErrorAction SilentlyContinue

# ─── Done ──────────────────────────────────────────────
Log "=== Bootstrap completed ==="

# Leave a marker for easy verification
"Bootstrap completed at $(Get-Date)" | Out-File "C:\BOOTSTRAP_COMPLETE.txt"
</powershell>
