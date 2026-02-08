# Merge recommended MCP servers into user-level Cursor mcp.json
# Run from project root (or scripts/). Uses repo root as filesystem allowed path.

$ErrorActionPreference = "Stop"
$CURSOR_HOME = if ($env:CURSOR_USER_HOME) { $env:CURSOR_USER_HOME } else { Join-Path $env:USERPROFILE ".cursor" }
$MCP_JSON = Join-Path $CURSOR_HOME "mcp.json"

# Project root: if run from scripts/, parent is root; else current dir
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = if (Test-Path (Join-Path $scriptDir "..\backend")) { (Resolve-Path (Join-Path $scriptDir "..")).Path } else { (Get-Location).Path }
$filesystemPath = $projectRoot -replace '\\', '\\'

$RECOMMENDED = @{
    shadcn = @{
        command = "npx"
        args    = @("shadcn@latest", "mcp")
    }
    filesystem = @{
        command = "npx"
        args    = @("-y", "@modelcontextprotocol/server-filesystem", $projectRoot)
    }
    fetch = @{
        command = "npx"
        args    = @("-y", "@modelcontextprotocol/server-fetch")
    }
}

Write-Host "MCP config installer (user-level)" -ForegroundColor Cyan
Write-Host "Target: $MCP_JSON" -ForegroundColor Gray
Write-Host "Filesystem path: $projectRoot" -ForegroundColor Gray
Write-Host ""

New-Item -ItemType Directory -Force -Path $CURSOR_HOME | Out-Null

$existing = @{}
if (Test-Path $MCP_JSON) {
    try {
        $raw = Get-Content $MCP_JSON -Raw -Encoding UTF8
        $obj = $raw | ConvertFrom-Json
        $obj.PSObject.Properties | ForEach-Object { $existing[$_.Name] = $_.Value }
    } catch {
        Write-Host "Warning: Could not parse existing mcp.json. Backing up and creating new." -ForegroundColor Yellow
        Copy-Item $MCP_JSON "$MCP_JSON.bak" -Force
        $existing = @{}
    }
}

$merged = @{}
foreach ($k in $existing.Keys) { $merged[$k] = $existing[$k] }
foreach ($k in $RECOMMENDED.Keys) {
    if (-not $merged.ContainsKey($k)) {
        $merged[$k] = $RECOMMENDED[$k]
        Write-Host "Added MCP: $k" -ForegroundColor Green
    } else {
        Write-Host "Kept existing MCP: $k" -ForegroundColor Gray
    }
}

$json = $merged | ConvertTo-Json -Depth 10
[System.IO.File]::WriteAllText($MCP_JSON, $json, [System.Text.UTF8Encoding]::new($false))

Write-Host ""
Write-Host "Done. Restart Cursor so it picks up MCP config." -ForegroundColor Cyan
Write-Host "MCPs are started by Cursor automatically when you use them - no need to run anything at boot." -ForegroundColor Gray
