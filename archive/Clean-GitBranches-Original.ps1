#Requires -Version 5.1

[CmdletBinding(SupportsShouldProcess)]
param(
    [switch]$DryRun = $true,
    [switch]$Interactive = $true,
    [string[]]$ProtectedBranches = @('main', 'master', 'develop', 'dev', 'staging', 'release'),
    [string]$RepositoryPath = $PWD.Path,
    [switch]$FetchFirst = $true,
    [switch]$DeleteMerged = $true,
    [switch]$DeleteOrphaned = $true,
    [switch]$DeleteInSync,
    [int]$MaxAge = 7
)

function Write-ColoredMessage {
    param([string]$Message, [string]$Type)
    $color = switch ($Type) {
        'Success' { 'Green' }
        'Warning' { 'Yellow' }
        'Error' { 'Red' }
        'Info' { 'Cyan' }
    }
    Write-Host $Message -ForegroundColor $color
}

function Test-GitRepository {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Repository path does not exist: $Path"
    }
    Push-Location -LiteralPath $Path
    try {
        $null = git rev-parse --git-dir 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw "Not a git repository: $Path"
        }
    }
    finally {
        Pop-Location
    }
}

function Get-DefaultBranch {
    $defaultBranch = git symbolic-ref refs/remotes/origin/HEAD 2>$null
    if ($LASTEXITCODE -eq 0 -and $defaultBranch) {
        return $defaultBranch -replace '^refs/remotes/origin/', ''
    }
    $remoteBranches = @(git branch -r 2>$null | ForEach-Object { $_.Trim() })
    if ($remoteBranches -contains 'origin/main') {
        return 'main'
    }
    if ($remoteBranches -contains 'origin/master') {
        return 'master'
    }
    return 'main'
}

function Get-CurrentBranch {
    $branch = git branch --show-current 2>$null
    if ($branch) {
        return $branch.Trim()
    }
    return $null
}

function Get-BranchAge {
    param([string]$BranchName)
    $lastCommitDate = git log -1 --format="%ci" $BranchName 2>$null
    if ($LASTEXITCODE -eq 0 -and $lastCommitDate) {
        try {
            $commitDate = [DateTime]::Parse($lastCommitDate)
            return (Get-Date) - $commitDate
        }
        catch {
            Write-Warning "Failed to parse commit date for branch '$BranchName': $_"
        }
    }
    return [TimeSpan]::Zero
}

function Test-BranchMerged {
    param([string]$BranchName, [string]$DefaultBranch)
    $mergedBranches = @(git branch --merged $DefaultBranch 2>$null | 
        ForEach-Object { $_.Trim() -replace '^\* ', '' })
    return $mergedBranches -contains $BranchName
}

function Get-RemoteTrackingInfo {
    param([string]$BranchName)
    $trackingBranch = git config "branch.$BranchName.remote" 2>$null
    if (-not $trackingBranch -or $LASTEXITCODE -ne 0) {
        return $null
    }
    $remoteBranch = git config "branch.$BranchName.merge" 2>$null
    if (-not $remoteBranch -or $LASTEXITCODE -ne 0) {
        return $null
    }
    $remoteBranch = $remoteBranch -replace '^refs/heads/', ''
    $fullRemoteBranch = "$trackingBranch/$remoteBranch"
    $null = git show-ref --verify --quiet "refs/remotes/$fullRemoteBranch" 2>$null
    return @{
        Exists = $LASTEXITCODE -eq 0
        Remote = $trackingBranch
        Branch = $remoteBranch
        FullName = $fullRemoteBranch
    }
}

function Test-BranchInSync {
    param([string]$BranchName)
    $tracking = Get-RemoteTrackingInfo -BranchName $BranchName
    if (-not $tracking -or -not $tracking.Exists) {
        return $false
    }
    $localCommit = git rev-parse $BranchName 2>$null
    $remoteCommit = git rev-parse $tracking.FullName 2>$null
    return ($LASTEXITCODE -eq 0 -and $localCommit -eq $remoteCommit)
}

function Get-LocalBranches {
    param([string[]]$ProtectedBranches, [string]$CurrentBranch)
    $allBranches = @(git branch 2>$null | ForEach-Object { $_.Trim() -replace '^\* ', '' })
    return $allBranches | Where-Object {
        $_ -and $_ -ne $CurrentBranch -and $ProtectedBranches -notcontains $_
    }
}

function Invoke-BranchCleanup {
    Write-ColoredMessage "=== Git Branch Cleanup Script ===" -Type Info
    Write-ColoredMessage "Repository: $RepositoryPath" -Type Info
    Write-ColoredMessage "Mode: $(if ($DryRun) { 'DRY RUN (preview only)' } else { 'LIVE (will delete branches)' })" -Type Info
    Write-Host ""
    
    Test-GitRepository -Path $RepositoryPath
    Push-Location -LiteralPath $RepositoryPath
    
    try {
        if ($FetchFirst) {
            Write-ColoredMessage "Fetching from all remotes..." -Type Info
            $null = git fetch --all --prune 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-ColoredMessage "Fetch completed" -Type Success
            } else {
                Write-ColoredMessage "Fetch had issues (continuing anyway)" -Type Warning
            }
            Write-Host ""
        }
        
        $defaultBranch = Get-DefaultBranch
        $currentBranch = Get-CurrentBranch
        $candidateBranches = @(Get-LocalBranches -ProtectedBranches $ProtectedBranches -CurrentBranch $currentBranch)
        
        Write-ColoredMessage "Default branch: $defaultBranch" -Type Info
        Write-ColoredMessage "Current branch: $currentBranch" -Type Info
        Write-ColoredMessage "Protected branches: $($ProtectedBranches -join ', ')" -Type Info
        Write-ColoredMessage "Analyzing $($candidateBranches.Count) candidate branches..." -Type Info
        Write-Host ""
        
        $branchesToDelete = [System.Collections.Generic.List[hashtable]]::new()
        
        foreach ($branch in $candidateBranches) {
            $age = Get-BranchAge -BranchName $branch
            $ageRounded = [math]::Round($age.TotalDays, 1)
            
            if ($age.Days -lt $MaxAge) {
                Write-ColoredMessage "Skipping $branch (only $ageRounded days old, minimum $MaxAge days)" -Type Info
                continue
            }
            
            $reason = $null
            $shouldDelete = $false
            
            if ($DeleteMerged -and (Test-BranchMerged -BranchName $branch -DefaultBranch $defaultBranch)) {
                $reason = "Fully merged into $defaultBranch"
                $shouldDelete = $true
            }
            elseif ($DeleteOrphaned) {
                $tracking = Get-RemoteTrackingInfo -BranchName $branch
                if ($tracking -and -not $tracking.Exists) {
                    $reason = "Remote tracking branch '$($tracking.FullName)' no longer exists"
                    $shouldDelete = $true
                }
            }
            elseif ($DeleteInSync -and (Test-BranchInSync -BranchName $branch)) {
                $tracking = Get-RemoteTrackingInfo -BranchName $branch
                if ($tracking -and $tracking.Exists) {
                    $reason = "Identical to upstream '$($tracking.FullName)'"
                    $shouldDelete = $true
                }
            }
            
            if ($shouldDelete) {
                $branchesToDelete.Add(@{
                    Name = $branch
                    Reason = $reason
                    Age = $age.Days
                })
                Write-ColoredMessage "DELETE: $branch - $reason ($ageRounded days old)" -Type Warning
            } else {
                Write-ColoredMessage "KEEP: $branch - Keeping ($ageRounded days old)" -Type Success
            }
        }
        
        Write-Host ""
        Write-ColoredMessage "=== SUMMARY ===" -Type Info
        Write-ColoredMessage "Total branches analyzed: $($candidateBranches.Count)" -Type Info
        Write-ColoredMessage "Branches to delete: $($branchesToDelete.Count)" -Type Info
        
        if ($branchesToDelete.Count -eq 0) {
            Write-ColoredMessage "No branches need cleanup!" -Type Success
            return
        }
        
        Write-Host ""
        Write-ColoredMessage "Branches marked for deletion:" -Type Info
        foreach ($branch in $branchesToDelete) {
            Write-ColoredMessage "  * $($branch.Name) - $($branch.Reason)" -Type Warning
        }
        
        if ($DryRun) {
            Write-Host ""
            Write-ColoredMessage "DRY RUN MODE - No branches were actually deleted" -Type Info
            Write-ColoredMessage "To perform the actual cleanup, run with: -DryRun:`$false" -Type Info
            return
        }
        
        Write-Host ""
        if ($Interactive) {
            $response = Read-Host "Do you want to delete these $($branchesToDelete.Count) branches? (y/N)"
            if ($response -notmatch '^y(es)?$') {
                Write-ColoredMessage "Cleanup cancelled by user" -Type Info
                return
            }
        }
        
        Write-ColoredMessage "Deleting branches..." -Type Info
        $deletedCount = 0
        $failedCount = 0
        
        foreach ($branch in $branchesToDelete) {
            if ($PSCmdlet.ShouldProcess($branch.Name, "Delete git branch")) {
                $null = git branch -D $branch.Name 2>&1
                
                if ($LASTEXITCODE -eq 0) {
                    Write-ColoredMessage "  Deleted $($branch.Name)" -Type Success
                    $deletedCount++
                } else {
                    Write-ColoredMessage "  Failed to delete $($branch.Name)" -Type Error
                    $failedCount++
                }
            }
        }
        
        Write-Host ""
        Write-ColoredMessage "Cleanup completed!" -Type Success
        Write-ColoredMessage "  Deleted: $deletedCount branches" -Type Success
        if ($failedCount -gt 0) {
            Write-ColoredMessage "  Failed: $failedCount branches" -Type Warning
        }
    }
    catch {
        Write-ColoredMessage "Error during cleanup: $_" -Type Error
        throw
    }
    finally {
        Pop-Location
    }
}

try {
    Invoke-BranchCleanup
}
catch {
    Write-ColoredMessage "Fatal error: $_" -Type Error
    exit 1
}
