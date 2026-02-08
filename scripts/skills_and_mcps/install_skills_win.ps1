# Install recommended Cursor Skills to user-level .cursor/skills/
# Run from project root or any folder. Requires: git, PowerShell 5.1+

$ErrorActionPreference = "Stop"
$CURSOR_HOME = if ($env:CURSOR_USER_HOME) { $env:CURSOR_USER_HOME } else { Join-Path $env:USERPROFILE ".cursor" }
$SKILLS_DIR = Join-Path $CURSOR_HOME "skills"
$TEMP_DIR = Join-Path $env:TEMP "cursor-skills-install-$(Get-Random)"

$REPOS = @(
    @{ Repo = "dadbodgeoff/drift";            Name = "drift" },
    @{ Repo = "vercel-labs/agent-skills";     Name = "vercel-agent-skills" }
)

Write-Host "Cursor Skills installer (user-level)" -ForegroundColor Cyan
Write-Host "Target: $SKILLS_DIR" -ForegroundColor Gray
Write-Host ""

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: git is required. Install Git and try again." -ForegroundColor Red
    exit 1
}

New-Item -ItemType Directory -Force -Path $SKILLS_DIR | Out-Null
New-Item -ItemType Directory -Force -Path $TEMP_DIR | Out-Null

try {
    foreach ($r in $REPOS) {
        $repoUrl = "https://github.com/$($r.Repo).git"
        $clonePath = Join-Path $TEMP_DIR $r.Name
        Write-Host "Cloning $($r.Repo) ..." -ForegroundColor Yellow
        & git clone --depth 1 --quiet $repoUrl $clonePath 2>$null
        if ($LASTEXITCODE -ne 0) {
            Write-Host "  Skip (clone failed or repo not found)." -ForegroundColor DarkYellow
            continue
        }
        $skillDirs = Get-ChildItem -Path $clonePath -Recurse -Filter "SKILL.md" -ErrorAction SilentlyContinue | ForEach-Object { $_.Directory }
        if ($skillDirs.Count -eq 0) {
            $parent = Get-Item $clonePath
            if (Test-Path (Join-Path $clonePath "SKILL.md")) {
                $dest = Join-Path $SKILLS_DIR $r.Name
                if (Test-Path $dest) { Remove-Item $dest -Recurse -Force }
                Copy-Item -Path $clonePath -Destination $dest -Recurse -Force
                Write-Host "  Installed as $($r.Name)" -ForegroundColor Green
            } else {
                Write-Host "  Skip (no SKILL.md found)." -ForegroundColor DarkYellow
            }
        } else {
            foreach ($d in $skillDirs) {
                $destName = $d.Name
                $dest = Join-Path $SKILLS_DIR $destName
                if (Test-Path $dest) { Remove-Item $dest -Recurse -Force }
                Copy-Item -Path $d.FullName -Destination $dest -Recurse -Force
                Write-Host "  Installed skill: $destName" -ForegroundColor Green
            }
        }
    }
    Write-Host ""
    Write-Host "Done. Restart Cursor to see new skills (or use / in Agent chat)." -ForegroundColor Cyan
} finally {
    if (Test-Path $TEMP_DIR) { Remove-Item $TEMP_DIR -Recurse -Force -ErrorAction SilentlyContinue }
}
