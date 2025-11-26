# Contributing to GitBranchCleanup

Thank you for your interest in contributing to GitBranchCleanup! This document provides guidelines and instructions for contributing.

## Code of Conduct

This project adheres to a code of conduct. By participating, you are expected to uphold this code. Please be respectful and constructive in all interactions.

## How to Contribute

### Reporting Bugs

Before creating bug reports, please check existing issues to avoid duplicates. When creating a bug report, include:

- **Clear title and description**
- **Steps to reproduce** the behavior
- **Expected behavior**
- **Actual behavior**
- **PowerShell version** (`$PSVersionTable.PSVersion`)
- **Git version** (`git --version`)
- **Operating system**
- **Error messages** (full output)

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion, include:

- **Clear title and description**
- **Use case** - why is this enhancement needed?
- **Proposed solution** - how should it work?
- **Alternatives considered**
- **Additional context** - screenshots, examples, etc.

### Pull Requests

1. **Fork the repository** and create your branch from `main`
2. **Make your changes** following the coding standards
3. **Add or update tests** as needed
4. **Update documentation** if you changed functionality
5. **Ensure tests pass** (`Invoke-Pester ./Tests`)
6. **Write a clear commit message**
7. **Submit the pull request**

## Development Guidelines

### Coding Standards

- **Follow PowerShell best practices**
  - Use approved verbs (`Get-Verb`)
  - Use PascalCase for function names
  - Use camelCase for variables
  - Use `[CmdletBinding()]` for advanced functions
- **Apply SOLID principles**
  - Single Responsibility - one purpose per function
  - Open/Closed - extensible without modification
  - Liskov Substitution - consistent interfaces
  - Interface Segregation - focused contracts
  - Dependency Inversion - depend on abstractions
- **Follow DRY principle** - don't repeat yourself
- **Write self-documenting code**
  - Clear function and variable names
  - Comment-based help for all public functions
  - Inline comments for complex logic only

### Function Structure

```powershell
function Verb-Noun {
    <#
    .SYNOPSIS
        Brief description.
    
    .DESCRIPTION
        Detailed description.
    
    .PARAMETER ParameterName
        Parameter description.
    
    .EXAMPLE
        Verb-Noun -ParameterName Value
        Description of what this example does.
    
    .NOTES
        Additional information.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ParameterName
    )
    
    # Implementation
}
```

### Testing

- Write Pester tests for all new functionality
- Ensure existing tests pass
- Aim for high code coverage (>80%)
- Test edge cases and error conditions

```powershell
Describe 'Function-Name' {
    Context 'When condition' {
        It 'Should expected behavior' {
            # Arrange
            $param = 'value'
            
            # Act
            $result = Function-Name -Parameter $param
            
            # Assert
            $result | Should -Be 'expected'
        }
    }
}
```

### Code Quality

This project uses PSScriptAnalyzer to maintain code quality. Configuration is in `PSScriptAnalyzerSettings.psd1`.

**Intentionally suppressed rules:**
- `PSAvoidUsingWriteHost` - Write-Host is used for colored user-facing output in this interactive tool
- `PSUseSingularNouns` - Plural nouns are appropriate for internal functions returning collections
- `PSUseProcessBlockForPipelineCommand` - Simple pipeline parameter doesn't require process block

**Run analysis locally:**
```powershell
# Install PSScriptAnalyzer
Install-Module -Name PSScriptAnalyzer -Force

# Run analysis
Invoke-ScriptAnalyzer -Path ./GitBranchCleanup -Recurse -Settings ./PSScriptAnalyzerSettings.psd1
```

The CI/CD pipeline will fail if PSScriptAnalyzer finds any errors or warnings (after applying the settings file suppressions).

### Documentation

- Update README.md for user-facing changes
- Update CHANGELOG.md following Keep a Changelog format
- Add/update comment-based help
- Update examples as needed

### Commit Messages

Follow the [Conventional Commits](https://www.conventionalcommits.org/) specification:

- `feat: add support for custom deletion criteria`
- `fix: correct age calculation for branches`
- `docs: update installation instructions`
- `refactor: extract deletion logic into separate function`
- `test: add tests for orphaned branch detection`
- `chore: update dependencies`

## Project Structure

```
GitBranchCleanup/
├── .github/
│   └── workflows/          # GitHub Actions CI/CD
├── GitBranchCleanup/
│   ├── GitBranchCleanup.psd1  # Module manifest
│   └── GitBranchCleanup.psm1  # Module implementation
├── Tests/
│   └── GitBranchCleanup.Tests.ps1  # Pester tests
├── CHANGELOG.md
├── CONTRIBUTING.md
├── LICENSE
└── README.md
```

## Development Setup

```powershell
# Clone your fork
git clone https://github.com/yourusername/GitBranchCleanup.git
cd GitBranchCleanup

# Create a feature branch
git checkout -b feature/your-feature-name

# Make changes and test
Import-Module ./GitBranchCleanup/GitBranchCleanup.psd1 -Force
Invoke-Pester ./Tests

# Commit and push
git add .
git commit -m "feat: your feature description"
git push origin feature/your-feature-name
```

## Release Process

1. Update version in `GitBranchCleanup.psd1`
2. Update `CHANGELOG.md`
3. Create git tag: `git tag -a v1.0.0 -m "Release 1.0.0"`
4. Push tag: `git push origin v1.0.0`
5. GitHub Actions will handle the rest

## Questions?

Feel free to open an issue for questions or clarifications.

Thank you for contributing! 🎉
