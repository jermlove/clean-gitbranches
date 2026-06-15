param(
    [string]$Root = 'C:\Dev',
    [switch]$Live
)

Import-Module 'C:\Dev\_scripts\clean-gitbranches\GitBranchCleanup\GitBranchCleanup.psd1' -Force

# Discover repos: any dir containing a .git folder, depth-limited
$gitDirs = Get-ChildItem -Path $Root -Directory -Recurse -Force -Filter '.git' -Depth 4 -ErrorAction SilentlyContinue
$repos = $gitDirs | ForEach-Object { $_.Parent.FullName } |
    Where-Object { $_ -notlike '*\clean-gitbranches' } |
    Sort-Object -Unique

Write-Host "Found $($repos.Count) repositories under $Root" -ForegroundColor Cyan
Write-Host ("=" * 70)

$report = [System.Collections.Generic.List[object]]::new()

foreach ($repo in $repos) {
    $name = Split-Path $repo -Leaf
    try {
        # ErrorAction 'Continue' (not 'Stop'): in Windows PowerShell 5.1, a native
        # command writing to stderr under $ErrorActionPreference='Stop' throws a
        # terminating NativeCommandError even on exit 0 (e.g. 'origin/HEAD is not a
        # symbolic ref' on repos with a dead remote). Continue lets the module's
        # default-branch fallback run; genuine 'throw's still propagate to the catch.
        $params = @{
            RepositoryPath = $repo
            FetchFirst     = $false
            Interactive    = $false
            ErrorAction    = 'Continue'
        }
        if (-not $Live) { $params['DryRun'] = $true } else { $params['DryRun'] = $false }

        $out = Invoke-BranchCleanup @params 6>&1 5>&1 4>&1 3>&1 2>&1 | Out-String

        $marked = @()
        foreach ($line in ($out -split "`r?`n")) {
            if ($line -match '^\s*\*\s+(\S+)\s+-\s+(.+)$') {
                $marked += [pscustomobject]@{ Branch = $Matches[1].Trim(); Reason = $Matches[2].Trim() }
            }
        }
        $deleted = @()
        foreach ($line in ($out -split "`r?`n")) {
            if ($line -match 'Deleted branch:\s*(\S+)') { $deleted += $Matches[1].Trim() }
        }

        $report.Add([pscustomobject]@{
            Repo    = $name
            Path    = $repo
            Marked  = $marked
            Deleted = $deleted
            Error   = $null
        })
    }
    catch {
        $report.Add([pscustomobject]@{
            Repo    = $name
            Path    = $repo
            Marked  = @()
            Deleted = @()
            Error   = $_.Exception.Message
        })
    }
}

Write-Host ""
Write-Host ("=" * 70)
Write-Host "SUMMARY" -ForegroundColor Cyan
Write-Host ("=" * 70)

$withWork = $report | Where-Object { $_.Marked.Count -gt 0 -or $_.Deleted.Count -gt 0 }
$errored  = $report | Where-Object { $_.Error }

if ($withWork.Count -eq 0) {
    Write-Host "No branches marked for cleanup in any repository." -ForegroundColor Green
}
foreach ($r in $withWork) {
    Write-Host ""
    Write-Host ("[{0}]  {1}" -f $r.Repo, $r.Path) -ForegroundColor Yellow
    foreach ($m in $r.Marked)  { Write-Host ("    would delete: {0}  ({1})" -f $m.Branch, $m.Reason) }
    foreach ($d in $r.Deleted) { Write-Host ("    DELETED: {0}" -f $d) -ForegroundColor Magenta }
}

if ($errored.Count -gt 0) {
    Write-Host ""
    Write-Host "Errors / skipped:" -ForegroundColor Red
    foreach ($e in $errored) { Write-Host ("    {0}: {1}" -f $e.Repo, $e.Error) }
}

$totalMarked = ($report | ForEach-Object { $_.Marked.Count } | Measure-Object -Sum).Sum
$totalDeleted = ($report | ForEach-Object { $_.Deleted.Count } | Measure-Object -Sum).Sum
Write-Host ""
Write-Host ("Repos scanned: {0} | repos with candidates: {1} | branches marked: {2} | deleted: {3} | errors: {4}" -f `
    $report.Count, $withWork.Count, $totalMarked, $totalDeleted, $errored.Count) -ForegroundColor Cyan
