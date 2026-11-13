# GitHub520 hosts updater (Windows)
# Fetch the latest hosts from GitHub520, save a local copy, back up the current
# system hosts file, then replace only the GitHub520 block inside it.

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$HostsPath = Join-Path $env:SystemRoot 'System32\drivers\etc\hosts'
$BeginMark = '# GitHub520 Host Start'
$EndMark   = '# GitHub520 Host End'
$Stamp     = Get-Date -Format 'yyyyMMdd-HHmmss'
$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
$SavedFile = Join-Path $ScriptDir "github520-$Stamp.hosts"

function Write-Step($msg) { Write-Host "==> $msg" -ForegroundColor Cyan }

# ---------- 1. administrator check ----------
$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host '[ERROR] Administrator privileges are required. Run the .bat launcher instead.' -ForegroundColor Red
    Read-Host 'Press Enter to exit'
    exit 1
}

# ---------- 2. download latest hosts ----------
$sources = @(
    'https://ghfast.top/https://raw.githubusercontent.com/521xueweihan/GitHub520/main/hosts',
    'https://gh-proxy.com/https://raw.githubusercontent.com/521xueweihan/GitHub520/main/hosts',
    'https://gh.llkk.cc/https://raw.githubusercontent.com/521xueweihan/GitHub520/main/hosts',
    'https://raw.githubusercontent.com/521xueweihan/GitHub520/main/hosts'
)

$content = $null
foreach ($url in $sources) {
    Write-Step "Downloading: $url"
    try {
        $resp = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 20
        if ($resp.StatusCode -eq 200 -and $resp.Content -match 'GitHub520 Host Start') {
            $content = $resp.Content
            Write-Host '    OK' -ForegroundColor Green
            break
        }
        Write-Host '    Unexpected content, trying next source...' -ForegroundColor Yellow
    }
    catch {
        Write-Host "    Failed: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

if ([string]::IsNullOrWhiteSpace($content)) {
    Write-Host '[ERROR] All sources failed. Check your network and run again.' -ForegroundColor Red
    Read-Host 'Press Enter to exit'
    exit 1
}

# ---------- 3. save a copy next to this script ----------
$content | Set-Content -LiteralPath $SavedFile -Encoding ASCII
Write-Step "Saved copy: $SavedFile"

# ---------- 4. back up the current system hosts ----------
$Backup = Join-Path $ScriptDir "hosts-backup-$Stamp.txt"
Copy-Item -LiteralPath $HostsPath -Destination $Backup -Force
Write-Step "Backed up: $Backup"

# ---------- 5. strip the old GitHub520 block, then append the new one ----------
$oldLines  = @(Get-Content -LiteralPath $HostsPath -ErrorAction SilentlyContinue)
$final     = New-Object System.Collections.Generic.List[string]
$skipping  = $false

foreach ($line in $oldLines) {
    if ($line -match '^\s*#\s*GitHub520 Host Start') { $skipping = $true;  continue }
    if ($line -match '^\s*#\s*GitHub520 Host End')   { $skipping = $false; continue }
    if (-not $skipping) { $final.Add($line) }
}

$newLines = @($content -split "\r?\n" |
    Where-Object { $_ -notmatch 'GitHub520 Host (Start|End)' } |
    Where-Object { $_.Trim() -ne '' })

while ($final.Count -gt 0 -and $final[$final.Count - 1].Trim() -eq '') {
    $final.RemoveAt($final.Count - 1)
}

if ($final.Count -gt 0) { $final.Add('') }
$final.Add($BeginMark)
foreach ($l in $newLines) { $final.Add($l) }
$final.Add($EndMark)
$final.Add('')

try { Set-ItemProperty -LiteralPath $HostsPath -Name IsReadOnly -Value $false -ErrorAction SilentlyContinue } catch { }
Set-Content -LiteralPath $HostsPath -Value $final -Encoding Default
Write-Step "hosts updated: $($newLines.Count) entries written"

# ---------- 6. flush DNS cache ----------
ipconfig /flushdns | Out-Null
Write-Step 'DNS cache flushed'

Write-Host ''
Write-Host 'Done. Open https://github.com to verify. If it still fails, close and reopen the browser.' -ForegroundColor Green
