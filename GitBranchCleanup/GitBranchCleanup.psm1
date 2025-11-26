#Requires -Version 5.1

<#
.SYNOPSIS
    Git branch cleanup module using SOLID principles.

.DESCRIPTION
    Provides functionality to analyze and optionally delete stale local git branches using SOLID principles:
    - Single Responsibility: Each function has one clear purpose
    - Open/Closed: Extensible through strategy pattern for deletion rules
    - Liskov Substitution: Consistent interfaces for all branch analyzers
    - Interface Segregation: Small, focused function interfaces
    - Dependency Inversion: Functions depend on abstractions (parameters) not concrete implementations

.NOTES
    This refactored version demonstrates DRY and SOLID principles:
    - DRY: Centralized git command execution, error handling, message formatting
    - Single Responsibility: Each function performs one specific task
    - Open/Closed: Deletion criteria are extensible without modifying core logic
#>

#region Core Types and Constants

$script:MessageTypes = @{
    Success = 'Green'
    Warning = 'Yellow'
    Error = 'Red'
    Info = 'Cyan'
}

#endregion

#region Single Responsibility - UI Output

function Write-FormattedMessage {
    <#
    .SYNOPSIS
        Single responsibility: Format and write colored console messages.
    .DESCRIPTION
        DRY principle: Centralize message formatting logic.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [string]$Message,

        [Parameter(Mandatory)]
        [ValidateSet('Success', 'Warning', 'Error', 'Info')]
        [string]$Type
    )
    Write-Host $Message -ForegroundColor $script:MessageTypes[$Type]
}

function Write-SectionHeader {
    <#
    .SYNOPSIS
        Single responsibility: Write section headers with consistent formatting.
    .DESCRIPTION
        DRY principle: Avoid repeating header formatting logic.
    #>
    param([string]$Title)
    Write-Host ""
    Write-FormattedMessage "=== $Title ===" -Type Info
}

#endregion

#region Single Responsibility - Git Operations (DRY Principle)

function Invoke-GitCommand {
    <#
    .SYNOPSIS
        Single responsibility: Execute git commands with error handling.
    .DESCRIPTION
        DRY principle: Centralize git command execution and error checking.
        This eliminates repeated patterns of "git ... 2>&1" and "$LASTEXITCODE -eq 0" checks.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string[]]$Arguments
    )

    $result = git @Arguments 2>&1

    return @{
        Output = $result
        Success = $LASTEXITCODE -eq 0
        ExitCode = $LASTEXITCODE
    }
}

function Test-GitRepository {
    <#
    .SYNOPSIS
        Single responsibility: Validate git repository existence and state.
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Repository path does not exist: $Path"
    }

    Push-Location -LiteralPath $Path
    try {
        $result = Invoke-GitCommand -Arguments @('rev-parse', '--git-dir')
        if (-not $result.Success) {
            throw "Not a git repository: $Path"
        }
    }
    finally {
        Pop-Location
    }
}

function Get-DefaultBranch {
    <#
    .SYNOPSIS
        Single responsibility: Determine repository default branch.
    #>
    $result = Invoke-GitCommand -Arguments @('symbolic-ref', 'refs/remotes/origin/HEAD')

    if ($result.Success -and $result.Output) {
        return $result.Output -replace '^refs/remotes/origin/', ''
    }

    # Fallback: check common remote branches
    $result = Invoke-GitCommand -Arguments @('branch', '-r')
    if ($result.Success) {
        $remoteBranches = @($result.Output | ForEach-Object { $_.Trim() })
        if ($remoteBranches -contains 'origin/main') { return 'main' }
        if ($remoteBranches -contains 'origin/master') { return 'master' }
    }

    return 'main'
}

function Get-CurrentBranch {
    <#
    .SYNOPSIS
        Single responsibility: Get currently checked out branch name.
    #>
    $result = Invoke-GitCommand -Arguments @('branch', '--show-current')
    if ($result.Success -and $result.Output) {
        return $result.Output.Trim()
    }
    return $null
}

function Invoke-RemoteFetch {
    <#
    .SYNOPSIS
        Single responsibility: Fetch and prune from all remotes.
    #>
    Write-FormattedMessage "Fetching from all remotes..." -Type Info

    $result = Invoke-GitCommand -Arguments @('fetch', '--all', '--prune')

    if ($result.Success) {
        Write-FormattedMessage "Fetch completed" -Type Success
    } else {
        Write-FormattedMessage "Fetch had issues (continuing anyway)" -Type Warning
    }
    Write-Host ""
}

#endregion

#region Single Responsibility - Branch Analysis

function Get-BranchAge {
    <#
    .SYNOPSIS
        Single responsibility: Calculate branch age from last commit.
    #>
    param(
        [Parameter(Mandatory)]
        [string]$BranchName
    )

    $result = Invoke-GitCommand -Arguments @('log', '-1', '--format=%ci', $BranchName)

    if ($result.Success -and $result.Output) {
        try {
            $commitDate = [DateTime]::Parse($result.Output)
            return (Get-Date) - $commitDate
        }
        catch {
            Write-Warning "Failed to parse commit date for branch '$BranchName': $_"
        }
    }

    return [TimeSpan]::Zero
}

function Get-MergedBranches {
    <#
    .SYNOPSIS
        Single responsibility: Get list of branches merged into target.
    .DESCRIPTION
        DRY principle: Centralize merged branch detection.
    #>
    param(
        [Parameter(Mandatory)]
        [string]$TargetBranch
    )

    $result = Invoke-GitCommand -Arguments @('branch', '--merged', $TargetBranch)

    if ($result.Success) {
        return @($result.Output | ForEach-Object { $_.Trim() -replace '^\* ', '' })
    }

    return @()
}

function Get-RemoteTrackingInfo {
    <#
    .SYNOPSIS
        Single responsibility: Retrieve remote tracking configuration for a branch.
    #>
    param(
        [Parameter(Mandatory)]
        [string]$BranchName
    )

    $remoteResult = Invoke-GitCommand -Arguments @('config', "branch.$BranchName.remote")
    if (-not $remoteResult.Success -or -not $remoteResult.Output) {
        return $null
    }

    $mergeResult = Invoke-GitCommand -Arguments @('config', "branch.$BranchName.merge")
    if (-not $mergeResult.Success -or -not $mergeResult.Output) {
        return $null
    }

    $trackingBranch = $remoteResult.Output
    $remoteBranch = $mergeResult.Output -replace '^refs/heads/', ''
    $fullRemoteBranch = "$trackingBranch/$remoteBranch"

    $verifyResult = Invoke-GitCommand -Arguments @('show-ref', '--verify', '--quiet', "refs/remotes/$fullRemoteBranch")

    return @{
        Exists = $verifyResult.Success
        Remote = $trackingBranch
        Branch = $remoteBranch
        FullName = $fullRemoteBranch
    }
}

function Get-CommitHash {
    <#
    .SYNOPSIS
        Single responsibility: Get commit hash for a branch reference.
    .DESCRIPTION
        DRY principle: Centralize commit hash retrieval.
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Reference
    )

    $result = Invoke-GitCommand -Arguments @('rev-parse', $Reference)
    if ($result.Success) {
        return $result.Output
    }
    return $null
}

function Get-CandidateBranches {
    <#
    .SYNOPSIS
        Single responsibility: Filter branches eligible for cleanup.
    #>
    param(
        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [string[]]$ProtectedBranches,

        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$CurrentBranch
    )

    $result = Invoke-GitCommand -Arguments @('branch')

    if (-not $result.Success) {
        return @()
    }

    return @($result.Output |
        ForEach-Object { $_.Trim() -replace '^\* ', '' } |
        Where-Object {
            $_ -and
            $_ -ne $CurrentBranch -and
            $ProtectedBranches -notcontains $_
        })
}

#endregion

#region Open/Closed Principle - Deletion Strategies

function Test-BranchDeletionCriteria {
    <#
    .SYNOPSIS
        Open/Closed: Evaluate branch against deletion criteria using strategy pattern.
    .DESCRIPTION
        This function is closed for modification but open for extension through
        the deletion strategy parameters. New deletion rules can be added without
        modifying the core logic.
    #>
    param(
        [Parameter(Mandatory)]
        [string]$BranchName,

        [Parameter(Mandatory)]
        [string]$DefaultBranch,

        [Parameter(Mandatory)]
        [hashtable]$Config
    )

    $result = @{
        ShouldDelete = $false
        Reason = $null
    }

    # Strategy 1: Merged branches
    if ($Config.DeleteMerged) {
        $mergedBranches = Get-MergedBranches -TargetBranch $DefaultBranch
        if ($mergedBranches -contains $BranchName) {
            $result.ShouldDelete = $true
            $result.Reason = "Fully merged into $DefaultBranch"
            return $result
        }
    }

    # Strategy 2: Orphaned branches
    if ($Config.DeleteOrphaned) {
        $tracking = Get-RemoteTrackingInfo -BranchName $BranchName
        if ($tracking -and -not $tracking.Exists) {
            $result.ShouldDelete = $true
            $result.Reason = "Remote tracking branch '$($tracking.FullName)' no longer exists"
            return $result
        }
    }

    # Strategy 3: In-sync branches
    if ($Config.DeleteInSync) {
        $tracking = Get-RemoteTrackingInfo -BranchName $BranchName
        if ($tracking -and $tracking.Exists) {
            $localCommit = Get-CommitHash -Reference $BranchName
            $remoteCommit = Get-CommitHash -Reference $tracking.FullName

            if ($localCommit -and $remoteCommit -and $localCommit -eq $remoteCommit) {
                $result.ShouldDelete = $true
                $result.Reason = "Identical to upstream '$($tracking.FullName)'"
                return $result
            }
        }
    }

    return $result
}

#endregion

#region Single Responsibility - Branch Processing

function Get-BranchAnalysis {
    <#
    .SYNOPSIS
        Single responsibility: Analyze a single branch for deletion eligibility.
    #>
    param(
        [Parameter(Mandatory)]
        [string]$BranchName,

        [Parameter(Mandatory)]
        [string]$DefaultBranch,

        [Parameter(Mandatory)]
        [int]$MinimumAge,

        [Parameter(Mandatory)]
        [hashtable]$DeletionConfig
    )

    $age = Get-BranchAge -BranchName $BranchName
    $ageRounded = [math]::Round($age.TotalDays, 1)

    if ($age.Days -lt $MinimumAge) {
        return @{
            Branch = $BranchName
            Age = $ageRounded
            ShouldDelete = $false
            Reason = "Too young (only $ageRounded days old, minimum $MinimumAge days)"
            Action = 'Skip'
        }
    }

    $criteria = Test-BranchDeletionCriteria -BranchName $BranchName -DefaultBranch $DefaultBranch -Config $DeletionConfig

    return @{
        Branch = $BranchName
        Age = $ageRounded
        ShouldDelete = $criteria.ShouldDelete
        Reason = $criteria.Reason
        Action = if ($criteria.ShouldDelete) { 'Delete' } else { 'Keep' }
    }
}

function Write-BranchAnalysisResult {
    <#
    .SYNOPSIS
        Single responsibility: Display branch analysis results.
    .DESCRIPTION
        DRY principle: Centralize output formatting for branch analysis.
    #>
    param(
        [Parameter(Mandatory)]
        [hashtable]$Analysis
    )

    $message = switch ($Analysis.Action) {
        'Skip' { "Skipping $($Analysis.Branch) ($($Analysis.Reason))" }
        'Delete' { "DELETE: $($Analysis.Branch) - $($Analysis.Reason) ($($Analysis.Age) days old)" }
        'Keep' { "KEEP: $($Analysis.Branch) - Keeping ($($Analysis.Age) days old)" }
    }

    $type = switch ($Analysis.Action) {
        'Skip' { 'Info' }
        'Delete' { 'Warning' }
        'Keep' { 'Success' }
    }

    Write-FormattedMessage $message -Type $type
}

#endregion

#region Single Responsibility - Deletion Operations

function Invoke-BranchDeletion {
    <#
    .SYNOPSIS
        Single responsibility: Delete a single branch.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$BranchName
    )

    if (-not $PSCmdlet.ShouldProcess($BranchName, "Delete git branch")) {
        return @{ Success = $false; Skipped = $true }
    }

    $result = Invoke-GitCommand -Arguments @('branch', '-D', $BranchName)

    if ($result.Success) {
        Write-FormattedMessage "  Deleted $BranchName" -Type Success
    } else {
        Write-FormattedMessage "  Failed to delete $BranchName" -Type Error
    }

    return @{
        Success = $result.Success
        Skipped = $false
    }
}

function Invoke-BranchDeletions {
    <#
    .SYNOPSIS
        Single responsibility: Orchestrate deletion of multiple branches.
    #>
    param(
        [Parameter(Mandatory)]
        [array]$Branches
    )

    Write-FormattedMessage "Deleting branches..." -Type Info

    $stats = @{
        Deleted = 0
        Failed = 0
        Skipped = 0
    }

    foreach ($branch in $Branches) {
        $result = Invoke-BranchDeletion -BranchName $branch.Name

        if ($result.Skipped) {
            $stats.Skipped++
        }
        elseif ($result.Success) {
            $stats.Deleted++
        }
        else {
            $stats.Failed++
        }
    }

    return $stats
}

#endregion

#region Single Responsibility - User Interaction

function Get-UserConfirmation {
    <#
    .SYNOPSIS
        Single responsibility: Get user confirmation for deletions.
    #>
    param(
        [Parameter(Mandatory)]
        [int]$Count
    )

    $response = Read-Host "Do you want to delete these $Count branches? (y/N)"
    return $response -match '^y(es)?$'
}

function Write-Summary {
    <#
    .SYNOPSIS
        Single responsibility: Display operation summary.
    #>
    param(
        [Parameter(Mandatory)]
        [hashtable]$Stats
    )

    Write-SectionHeader "SUMMARY"
    Write-FormattedMessage "Total branches analyzed: $($Stats.Analyzed)" -Type Info
    Write-FormattedMessage "Branches to delete: $($Stats.ToDelete)" -Type Info
}

function Write-DeletionResults {
    <#
    .SYNOPSIS
        Single responsibility: Display deletion results.
    #>
    param(
        [Parameter(Mandatory)]
        [hashtable]$Stats
    )

    Write-Host ""
    Write-FormattedMessage "Cleanup completed!" -Type Success
    Write-FormattedMessage "  Deleted: $($Stats.Deleted) branches" -Type Success

    if ($Stats.Failed -gt 0) {
        Write-FormattedMessage "  Failed: $($Stats.Failed) branches" -Type Warning
    }
}

#endregion

#region Main Orchestration

function Invoke-BranchCleanup {
    <#
    .SYNOPSIS
        Main orchestration function following Single Responsibility.
    .DESCRIPTION
        Coordinates the cleanup process by delegating to specialized functions.
        Each step is handled by a focused, single-purpose function.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [switch]$DryRun = $true,
        [switch]$Interactive = $true,
        [string[]]$ProtectedBranches = @('main', 'master', 'develop', 'dev', 'test', 'staging', 'release'),
        [string]$RepositoryPath = $PWD.Path,
        [switch]$FetchFirst = $true,
        [switch]$DeleteMerged = $true,
        [switch]$DeleteOrphaned = $true,
        [switch]$DeleteInSync,
        [int]$MaxAge = 7
    )
    
    # Display header
    Write-SectionHeader "Git Branch Cleanup Script"
    Write-FormattedMessage "Repository: $RepositoryPath" -Type Info
    Write-FormattedMessage "Mode: $(if ($DryRun) { 'DRY RUN (preview only)' } else { 'LIVE (will delete branches)' })" -Type Info
    Write-Host ""
    
    # Validate repository
    Test-GitRepository -Path $RepositoryPath
    
    # Execute in repository context
    Push-Location -LiteralPath $RepositoryPath
    
    try {
        # Fetch remotes if requested
        if ($FetchFirst) {
            Invoke-RemoteFetch
        }
        
        # Get repository state
        $defaultBranch = Get-DefaultBranch
        $currentBranch = Get-CurrentBranch
        $candidateBranches = Get-CandidateBranches -ProtectedBranches $ProtectedBranches -CurrentBranch $currentBranch
        
        # Display configuration
        Write-FormattedMessage "Default branch: $defaultBranch" -Type Info
        Write-FormattedMessage "Current branch: $currentBranch" -Type Info
        Write-FormattedMessage "Protected branches: $($ProtectedBranches -join ', ')" -Type Info
        Write-FormattedMessage "Analyzing $($candidateBranches.Count) candidate branches..." -Type Info
        Write-Host ""
        
        # Configure deletion strategies (Open/Closed principle)
        $deletionConfig = @{
            DeleteMerged = $DeleteMerged.IsPresent
            DeleteOrphaned = $DeleteOrphaned.IsPresent
            DeleteInSync = $DeleteInSync.IsPresent
        }
        
        # Analyze branches
        $branchesToDelete = [System.Collections.Generic.List[hashtable]]::new()
        
        foreach ($branch in $candidateBranches) {
            $analysis = Get-BranchAnalysis `
                -BranchName $branch `
                -DefaultBranch $defaultBranch `
                -MinimumAge $MaxAge `
                -DeletionConfig $deletionConfig
            
            Write-BranchAnalysisResult -Analysis $analysis
            
            if ($analysis.ShouldDelete) {
                $branchesToDelete.Add(@{
                    Name = $analysis.Branch
                    Reason = $analysis.Reason
                    Age = $analysis.Age
                })
            }
        }

        # Display summary
        Write-Summary -Stats @{
            Analyzed = $candidateBranches.Count
            ToDelete = $branchesToDelete.Count
        }

        # Early exit if nothing to delete
        if ($branchesToDelete.Count -eq 0) {
            Write-FormattedMessage "No branches need cleanup!" -Type Success
            return
        }

        # Display branches marked for deletion
        Write-Host ""
        Write-FormattedMessage "Branches marked for deletion:" -Type Info
        foreach ($branch in $branchesToDelete) {
            Write-FormattedMessage "  * $($branch.Name) - $($branch.Reason)" -Type Warning
        }

        # Handle dry run
        if ($DryRun) {
            Write-Host ""
            Write-FormattedMessage "DRY RUN MODE - No branches were actually deleted" -Type Info
            Write-FormattedMessage "To perform the actual cleanup, run with: -DryRun:`$false" -Type Info
            return
        }

        # Get user confirmation if interactive
        Write-Host ""
        if ($Interactive -and -not (Get-UserConfirmation -Count $branchesToDelete.Count)) {
            Write-FormattedMessage "Cleanup cancelled by user" -Type Info
            return
        }

        # Perform deletions
        $deletionStats = Invoke-BranchDeletions -Branches $branchesToDelete

        # Display results
        Write-DeletionResults -Stats $deletionStats
    }
    catch {
        Write-FormattedMessage "Error during cleanup: $_" -Type Error
        throw
    }
    finally {
        Pop-Location
    }
}

#endregion

#region Module Exports

Export-ModuleMember -Function Invoke-BranchCleanup

#endregion
