# GitBranchCleanup - Project Structure

## 📁 Directory Structure

```
GitBranchCleanup/
│
├── 📂 .github/
│   └── 📂 workflows/
│       └── ci-cd.yml                    # GitHub Actions CI/CD pipeline
│
├── 📂 GitBranchCleanup/                 # Main module directory
│   ├── GitBranchCleanup.psd1            # PowerShell module manifest
│   └── GitBranchCleanup.psm1            # Module implementation (functions)
│
├── 📂 Tests/
│   └── GitBranchCleanup.Tests.ps1       # Pester unit tests
│
├── 📂 archive/                          # Original files (for reference)
│   ├── Clean-GitBranches.ps1
│   ├── Clean-GitBranches-Original.ps1
│   └── README-GitBranchCleanup.md
│
├── .gitignore                           # Git ignore patterns
├── build.ps1                            # Build/test/publish automation
├── CHANGELOG.md                         # Version history
├── CONTRIBUTING.md                      # Contribution guidelines
├── EXAMPLES.md                          # Usage examples
├── LICENSE                              # MIT License
├── PSScriptAnalyzerSettings.psd1        # Code quality rules configuration
├── PROJECT-STRUCTURE.md                 # This file
├── README.md                            # Main documentation
└── SETUP-COMPLETE.md                    # Setup completion notes
```

## 🎯 Module Architecture

### Public Functions (Exported)
- `Invoke-BranchCleanup` - Main function for branch cleanup

### Private Functions (Internal)
- **UI Layer**:
  - `Write-FormattedMessage` - Colored console output
  - `Write-SectionHeader` - Section headers
  - `Write-BranchAnalysisResult` - Branch analysis display
  - `Write-Summary` - Operation summary
  - `Write-DeletionResults` - Deletion results
  - `Get-UserConfirmation` - User input

- **Git Operations**:
  - `Invoke-GitCommand` - Git command wrapper (DRY)
  - `Test-GitRepository` - Repository validation
  - `Get-DefaultBranch` - Default branch detection
  - `Get-CurrentBranch` - Current branch
  - `Invoke-RemoteFetch` - Remote fetch & prune

- **Branch Analysis**:
  - `Get-BranchAge` - Calculate branch age
  - `Get-MergedBranches` - Merged branches list
  - `Get-RemoteTrackingInfo` - Tracking configuration
  - `Get-CommitHash` - Commit hash retrieval
  - `Get-CandidateBranches` - Filter eligible branches
  - `Get-BranchAnalysis` - Analyze single branch
  - `Test-BranchDeletionCriteria` - Strategy pattern evaluation

- **Deletion Operations**:
  - `Invoke-BranchDeletion` - Delete single branch
  - `Invoke-BranchDeletions` - Orchestrate multiple deletions

## 🔄 Workflow

```
User → Invoke-BranchCleanup
  │
  ├─→ Validate Repository
  ├─→ Fetch Remotes (optional)
  ├─→ Get Repository State
  ├─→ Filter Candidate Branches
  │
  ├─→ For Each Branch:
  │   ├─→ Get Age
  │   ├─→ Test Deletion Criteria
  │   │   ├─→ Merged?
  │   │   ├─→ Orphaned?
  │   │   └─→ In Sync?
  │   └─→ Display Result
  │
  ├─→ Display Summary
  ├─→ Confirm (if interactive)
  └─→ Delete Branches
      └─→ Display Results
```

## 🏗️ Design Principles Applied

### SOLID
- **S**ingle Responsibility - Each function has one clear purpose
- **O**pen/Closed - Deletion strategies extensible without modification
- **L**iskov Substitution - Consistent return types and interfaces
- **I**nterface Segregation - Small, focused function contracts
- **D**ependency Inversion - Depend on abstractions (parameters)

### DRY (Don't Repeat Yourself)
- Git command execution centralized in `Invoke-GitCommand`
- Message formatting unified in `Write-FormattedMessage`
- Error handling standardized via structured returns
- Section headers consistent via `Write-SectionHeader`

## 📦 Module Metadata

| Property | Value |
|----------|-------|
| Module Name | GitBranchCleanup |
| Version | 1.1.0 |
| PowerShell | 5.1+ |
| License | MIT |
| Author | Community Contributors |

## 🚀 Quick Start

```powershell
# Import module
Import-Module ./GitBranchCleanup/GitBranchCleanup.psd1

# Preview cleanup
Invoke-BranchCleanup

# Execute cleanup
Invoke-BranchCleanup -DryRun:$false
```

## 🧪 Testing

```powershell
# Run build
.\build.ps1 -Task Build

# Run tests
.\build.ps1 -Task Test

# Clean
.\build.ps1 -Task Clean
```

## 📚 Documentation Files

| File | Purpose |
|------|---------|
| README.md | Main documentation and usage guide |
| EXAMPLES.md | Practical usage examples |
| CHANGELOG.md | Version history and changes |
| CONTRIBUTING.md | Contribution guidelines |
| LICENSE | MIT License text |

## 🔧 Development Tools

| Tool | Purpose |
|------|---------|
| build.ps1 | Build, test, and publish automation |
| Pester | Unit testing framework |
| PSScriptAnalyzer | Code quality analysis |
| GitHub Actions | CI/CD automation |

## 🎓 Best Practices

1. **Always dry-run first** - Preview before executing
2. **Use appropriate age thresholds** - Don't delete recent branches
3. **Customize protected branches** - Match your workflow
4. **Test in dev repos first** - Verify behavior
5. **Keep backups** - Git reflog can recover mistakes

## 📈 Future Enhancements

- [ ] Parallel branch processing for large repos
- [ ] JSON/CSV export of analysis results
- [ ] Custom deletion criteria via scriptblocks
- [ ] Batch processing across multiple repositories
- [ ] Undo/restore functionality
- [ ] Performance optimizations
- [ ] Extended test coverage

---

**Status**: ✅ Production Ready
**Last Updated**: 2025-11-26
