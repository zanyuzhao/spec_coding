# Verify that recommended MCP server commands are available (npx can run them).
# This does NOT start MCPs for Cursor - Cursor starts MCPs automatically when you use them.
# Use this script only to check that install_mcp_win.ps1 was applied and commands work.

$ErrorActionPreference = "Continue"
Write-Host "Checking MCP commands (quick smoke test)..." -ForegroundColor Cyan
Write-Host ""

$checks = @(
    @{ Name = "fetch";  Command = "npx"; Args = @("-y", "@modelcontextprotocol/server-fetch") },
    @{ Name = "shadcn"; Command = "npx"; Args = @("shadcn@latest", "mcp") }
)

foreach ($c in $checks) {
    Write-Host "  $($c.Name) ... " -NoNewline
    $p = Start-Process -FilePath $c.Command -ArgumentList $c.Args -PassThru -NoWindow -RedirectStandardError "NUL"
    Start-Sleep -Seconds 2
    if (-not $p.HasExited) {
        $p.Kill()
        Write-Host "OK" -ForegroundColor Green
    } else {
        Write-Host "exit $($p.ExitCode)" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "MCPs are started by Cursor when needed. No need to run them at boot." -ForegroundColor Gray
