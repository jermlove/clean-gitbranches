# GitBranchCleanup

A PowerShell module for intelligently cleaning up stale, merged, and orphaned local Git branches with configurable criteria and built-in safety features.

[![PowerShell Gallery](https://img.shields.io/powershellgallery/v/GitBranchCleanup.svg)](https://www.powershellgallery.com/packages/GitBranchCleanup)
[![License](https://img.shields.io/github/license/yourusername/GitBranchCleanup.svg)](LICENSE)

## Features

- 🎯 **Smart Detection**: Automatically identifies branches that are:
  - Fully merged into the default branch
  - Orphaned (remote tracking branch deleted)
  - In sync with their remote counterparts
- 🛡️ **Safety First**: Dry-run mode by default, protected branches, age thresholds
- 🎨 **SOLID Design**: Built following software engineering best practices
- 🔧 **Highly Configurable**: Customize deletion criteria, protected branches, and behavior
- 📊 **Interactive Mode**: Review and confirm before deletions
- ✅ **WhatIf Support**: PowerShell ShouldProcess integration

## Installation

### From PowerShell Gallery (when published)
```powershell
Install-Module -Name GitBranchCleanup -Scope CurrentUser
```

### Manual Installation
```powershell
# Clone the repository
git clone https://github.com/yourusername/GitBranchCleanup.git

# Import the module
Import-Module ./GitBranchCleanup/GitBranchCleanup.psd1
```

## Quick Start

### Preview what would be deleted (default dry-run mode)
```powershell
Invoke-BranchCleanup
```

### Clean up merged branches (interactive confirmation)
```powershell
Invoke-BranchCleanup -DryRun:$false
```

### Clean up specific repository
```powershell
Invoke-BranchCleanup -RepositoryPath "C:\Projects\MyRepo"
```

### Non-interactive cleanup
```powershell
Invoke-BranchCleanup -DryRun:$false -Interactive:$false
```

## Usage Examples

### Clean up merged and orphaned branches older than 30 days
```powershell
Invoke-BranchCleanup -DeleteMerged -DeleteOrphaned -MaxAge 30 -DryRun:$false
```

### Include branches that are in sync with remote
```powershell
Invoke-BranchCleanup -DeleteMerged -DeleteOrphaned -DeleteInSync -DryRun:$false
```

### Custom protected branches
```powershell
Invoke-BranchCleanup -ProtectedBranches @('main', 'develop', 'production') -DryRun:$false
```

### Skip remote fetch (faster but potentially outdated)
```powershell
Invoke-BranchCleanup -FetchFirst:$false
```

### Use with WhatIf
```powershell
Invoke-BranchCleanup -DryRun:$false -WhatIf
```

## Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `DryRun` | Switch | `$true` | Preview mode - doesn't delete branches |
| `Interactive` | Switch | `$true` | Ask for confirmation before deleting |
| `ProtectedBranches` | String[] | `@('main', 'master', 'develop', 'dev', 'test', 'staging', 'release')` | Branches that should never be deleted |
| `RepositoryPath` | String | Current directory | Path to Git repository |
| `FetchFirst` | Switch | `$true` | Fetch from remotes before analyzing |
| `DeleteMerged` | Switch | `$true` | Delete branches merged into default branch |
| `DeleteOrphaned` | Switch | `$true` | Delete branches whose remote tracking branch is gone |
| `DeleteInSync` | Switch | `$false` | Delete branches identical to their remote |
| `MaxAge` | Int | `7` | Minimum age in days before considering deletion |

## How It Works

1. **Validation**: Verifies the repository path and Git status
2. **Fetch** (optional): Updates remote tracking information
3. **Discovery**: Identifies candidate branches (excludes current and protected)
4. **Analysis**: Evaluates each branch against deletion criteria:
   - Age check (must be older than `MaxAge` days)
   - Merge status (if `DeleteMerged` enabled)
   - Orphaned status (if `DeleteOrphaned` enabled)
   - Sync status (if `DeleteInSync` enabled)
5. **Review**: Shows summary of branches to be deleted
6. **Confirmation** (if interactive): Prompts for user approval
7. **Deletion**: Removes approved branches and reports results

## Architecture

This module is built following **SOLID principles** and **DRY** (Don't Repeat Yourself) patterns:

- **Single Responsibility**: Each function has one clear purpose
- **Open/Closed**: Deletion strategies are extensible without modifying core logic
- **Liskov Substitution**: Consistent interfaces across all functions
- **Interface Segregation**: Small, focused function contracts
- **Dependency Inversion**: High-level logic depends on abstractions

See [ARCHITECTURE.md](ARCHITECTURE.md) for detailed design documentation.

## Requirements

- PowerShell 5.1 or higher
- Git command-line tools
- Local Git repository

## Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

### Development Setup
```powershell
# Clone the repository
git clone https://github.com/yourusername/GitBranchCleanup.git
cd GitBranchCleanup

# Run tests
Invoke-Pester ./Tests

# Import module for testing
Import-Module ./GitBranchCleanup/GitBranchCleanup.psd1 -Force
```

## Testing

```powershell
# Run all tests
Invoke-Pester ./Tests

# Run with coverage
Invoke-Pester ./Tests -CodeCoverage ./GitBranchCleanup/GitBranchCleanup.psm1
```

## Troubleshooting

### "Not a git repository" error
Ensure you're running the command from within a Git repository or specify `-RepositoryPath`.

### Branches not being detected as merged
Try running with `-FetchFirst` to update remote tracking information.

### Protected branch being suggested for deletion
Add it to the `-ProtectedBranches` parameter.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history and changes.

## Acknowledgments

Built with modern software engineering practices:
- DRY (Don't Repeat Yourself)
- SOLID Principles
- Test-Driven Development
- Semantic Versioning

## Support

- 🐛 [Report a bug](https://github.com/yourusername/GitBranchCleanup/issues)
- 💡 [Request a feature](https://github.com/yourusername/GitBranchCleanup/issues)
- 📖 [Documentation](https://github.com/yourusername/GitBranchCleanup/wiki)
