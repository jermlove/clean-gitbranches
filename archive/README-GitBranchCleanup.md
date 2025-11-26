# Git Branch Cleanup Script

A comprehensive PowerShell script to safely clean up stale local git branches.

## Features

- **Safe by default**: Dry-run mode previews changes without making them
- **Multiple cleanup criteria**:
  - Branches fully merged into main/master
  - Branches whose remote tracking branch has been deleted
  - Branches identical to their upstream (optional)
- **Safety protections**:
  - Never deletes current branch or protected branches
  - Age filter (only considers branches older than specified days)
  - Interactive confirmation for deletions
- **Comprehensive reporting**: Shows what will be deleted and why

## Quick Start

```powershell
# Preview what would be cleaned (safe - no changes made)
.\Clean-GitBranches.ps1

# Actually perform the cleanup with confirmation
.\Clean-GitBranches.ps1 -DryRun:$false

# Fully automated cleanup (no prompts)
.\Clean-GitBranches.ps1 -DryRun:$false -Interactive:$false
```

## Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `DryRun` | `$true` | Preview mode - shows what would be deleted |
| `Interactive` | `$true` | Prompt for confirmation before deletions |
| `ProtectedBranches` | `@('main', 'master', 'develop', 'dev', 'staging', 'release')` | Branches to never delete |
| `RepositoryPath` | Current directory | Path to git repository |
| `FetchFirst` | `$true` | Fetch from remotes before analyzing |
| `DeleteMerged` | `$true` | Delete branches merged into default branch |
| `DeleteOrphaned` | `$true` | Delete branches with deleted remotes |
| `DeleteInSync` | `$false` | Delete branches identical to upstream |
| `MaxAge` | `7` | Only consider branches older than N days |

## Usage Examples

### Basic Usage
```powershell
# See what would be cleaned up (safe preview)
.\Clean-GitBranches.ps1

# Actually clean up with confirmation
.\Clean-GitBranches.ps1 -DryRun:$false
```

### Advanced Usage
```powershell
# Include branches identical to upstream, 14+ day minimum age
.\Clean-GitBranches.ps1 -DeleteInSync:$true -MaxAge 14

# Custom repository and protected branches
.\Clean-GitBranches.ps1 -RepositoryPath "C:\Dev\MyRepo" -ProtectedBranches @('main', 'staging', 'hotfix')

# Fully automated (use with caution)
.\Clean-GitBranches.ps1 -DryRun:$false -Interactive:$false -MaxAge 30
```

### Typical Workflow
```powershell
# 1. First, see what would be cleaned
.\Clean-GitBranches.ps1

# 2. If the preview looks good, do the actual cleanup  
.\Clean-GitBranches.ps1 -DryRun:$false

# 3. For regular maintenance, add to a scheduled task or alias
```

## What Gets Deleted

The script identifies branches for deletion based on these criteria:

1. **Merged Branches**: Local branches fully merged into the default branch (main/master)
2. **Orphaned Branches**: Local branches whose remote tracking branch has been deleted
3. **In-Sync Branches** (optional): Local branches identical to their upstream branch

## Safety Features

- **Protected Branches**: Never deletes main, master, develop, dev, staging, release (customizable)
- **Current Branch Protection**: Never deletes the currently checked out branch
- **Age Filter**: Only considers branches older than specified days (default: 7 days)
- **Dry Run Default**: Preview mode by default - you must explicitly opt-in to deletions
- **Interactive Confirmation**: Prompts before making changes (can be disabled)
- **Detailed Logging**: Shows exactly what will be deleted and why

## Output Example

```
=== Git Branch Cleanup Script ===
Repository: C:\Dev\MyProject
Mode: DRY RUN (preview only)

Fetching from all remotes...
✓ Fetch completed

Default branch: main
Current branch: feature/new-stuff  
Protected branches: main, master, develop, dev, staging, release
Analyzing 8 candidate branches...

✓ feature/important-work - Keeping (3.2 days old)
🗑 feature/old-completed - Fully merged into main (12.5 days old)
🗑 bugfix/ticket-123 - Remote tracking branch 'origin/bugfix/ticket-123' no longer exists (8.1 days old)
✓ feature/wip - Keeping (2.0 days old)

=== SUMMARY ===
Total branches analyzed: 8
Branches to delete: 2

Branches marked for deletion:
  • feature/old-completed - Fully merged into main
  • bugfix/ticket-123 - Remote tracking branch 'origin/bugfix/ticket-123' no longer exists

🔍 DRY RUN MODE - No branches were actually deleted
To perform the actual cleanup, run with: -DryRun:$false
```

## Installation & Setup

1. Save the script as `Clean-GitBranches.ps1`
2. Make it easily accessible by adding to your PATH or creating an alias
3. Run `Set-ExecutionPolicy RemoteSigned` if needed to allow local script execution

### PowerShell Profile Alias
Add to your PowerShell profile (`$PROFILE`):
```powershell
function Clean-Branches { 
    & "C:\Dev\_scripts\Clean-GitBranches.ps1" @args 
}
```

Then use with: `Clean-Branches -DryRun:$false`

## Requirements

- PowerShell 5.1 or later
- Git command-line tools
- Must be run from within a git repository (or specify `-RepositoryPath`)

## Safety Notes

⚠️ **Always run in dry-run mode first** to preview changes
⚠️ **Back up important work** before running cleanup
⚠️ **Customize protected branches** for your workflow
⚠️ **Test the script** on a non-critical repository first

The script is designed to be safe, but git branch deletion is permanent for local branches.