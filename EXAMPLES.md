# Quick Start Examples

## Installation

```powershell
# Clone the repository
git clone https://github.com/yourusername/GitBranchCleanup.git
cd GitBranchCleanup

# Import the module
Import-Module ./GitBranchCleanup/GitBranchCleanup.psd1
```

## Basic Usage

### 1. Preview Mode (Safe - No Changes)
```powershell
# Preview what would be deleted (default behavior)
Invoke-BranchCleanup
```

**Output:**
```
=== Git Branch Cleanup Script ===
Repository: C:\Projects\MyRepo
Mode: DRY RUN (preview only)

Fetching from all remotes...
Fetch completed

Default branch: main
Current branch: develop
Protected branches: main, master, develop, dev, test, staging, release
Analyzing 5 candidate branches...

DELETE: feature/old-feature - Fully merged into main (45.2 days old)
DELETE: bugfix/temp-fix - Remote tracking branch 'origin/bugfix/temp-fix' no longer exists (30.1 days old)
KEEP: feature/new-feature - Keeping (3.5 days old)
Skipping feature/wip (only 2.1 days old, minimum 7 days)

=== SUMMARY ===
Total branches analyzed: 5
Branches to delete: 2

Branches marked for deletion:
  * feature/old-feature - Fully merged into main
  * bugfix/temp-fix - Remote tracking branch no longer exists

DRY RUN MODE - No branches were actually deleted
To perform the actual cleanup, run with: -DryRun:$false
```

### 2. Interactive Cleanup
```powershell
# Clean up with confirmation prompt
Invoke-BranchCleanup -DryRun:$false

# You'll be prompted:
# Do you want to delete these 2 branches? (y/N):
```

### 3. Automated Cleanup (Non-Interactive)
```powershell
# Clean up without prompts (use with caution!)
Invoke-BranchCleanup -DryRun:$false -Interactive:$false
```

## Common Scenarios

### Clean up merged branches older than 30 days
```powershell
Invoke-BranchCleanup -DeleteMerged -MaxAge 30 -DryRun:$false
```

### Clean up only orphaned branches
```powershell
Invoke-BranchCleanup -DeleteMerged:$false -DeleteOrphaned -DryRun:$false
```

### Include branches that are in sync with remote
```powershell
Invoke-BranchCleanup -DeleteMerged -DeleteOrphaned -DeleteInSync -DryRun:$false
```

### Custom protected branches
```powershell
Invoke-BranchCleanup -ProtectedBranches @('main', 'develop', 'production', 'hotfix') -DryRun:$false
```

### Clean specific repository
```powershell
Invoke-BranchCleanup -RepositoryPath "C:\Projects\MyOtherRepo" -DryRun:$false
```

### Skip remote fetch (faster, but may be outdated)
```powershell
Invoke-BranchCleanup -FetchFirst:$false -DryRun:$false
```

### Use WhatIf for safety
```powershell
# PowerShell's built-in safety mechanism
Invoke-BranchCleanup -DryRun:$false -WhatIf
```

## Automation Example

Create a script to clean multiple repositories:

```powershell
# cleanup-all-repos.ps1
Import-Module ./GitBranchCleanup/GitBranchCleanup.psd1

$repositories = @(
    'C:\Projects\WebApp'
    'C:\Projects\API'
    'C:\Projects\Mobile'
)

foreach ($repo in $repositories) {
    Write-Host "`nCleaning repository: $repo" -ForegroundColor Cyan
    Invoke-BranchCleanup -RepositoryPath $repo -DryRun:$false -Interactive:$false
}
```

## Best Practices

1. **Always test with dry-run first**
   ```powershell
   Invoke-BranchCleanup  # Preview mode
   ```

2. **Use appropriate age thresholds**
   ```powershell
   # For active projects
   Invoke-BranchCleanup -MaxAge 7
   
   # For stable projects
   Invoke-BranchCleanup -MaxAge 30
   ```

3. **Customize protected branches for your workflow**
   ```powershell
   $protected = @('main', 'develop', 'staging', 'production', 'release/*')
   Invoke-BranchCleanup -ProtectedBranches $protected
   ```

4. **Use interactive mode when uncertain**
   ```powershell
   Invoke-BranchCleanup -DryRun:$false -Interactive:$true
   ```

5. **Combine with WhatIf for extra safety**
   ```powershell
   Invoke-BranchCleanup -DryRun:$false -WhatIf
   ```

## Troubleshooting

### Module not found
```powershell
# Make sure you're in the right directory
Get-Location

# Import with full path
Import-Module C:\Path\To\GitBranchCleanup\GitBranchCleanup.psd1 -Force
```

### No branches detected
```powershell
# Ensure you're in a git repository
git status

# Or specify the path
Invoke-BranchCleanup -RepositoryPath "C:\Path\To\Repo"
```

### Branches not showing as merged
```powershell
# Update remote tracking info
Invoke-BranchCleanup -FetchFirst
```
