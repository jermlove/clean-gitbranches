# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2026-06-15

### Fixed
- `Get-CandidateBranches` now uses `git for-each-ref` instead of parsing
  `git branch` output, so branches checked out in a linked worktree (`+ `
  marker) and the detached-HEAD pseudo-entry no longer leak through as
  bogus branch names and crash with `fatal: ambiguous argument`.
- `Get-MergedBranches` strips both the `* ` (current) and `+ ` (worktree)
  status markers.

### Added
- New private `Get-WorktreeBranches` helper; worktree-checked-out branches
  are excluded from cleanup candidates (git cannot delete them).
- Pester 5 regression tests covering worktree and detached-HEAD parsing.
- 5.1-compatible `Join-Path` calls in the test suite so it runs on both
  Windows PowerShell 5.1 and PowerShell 7.

## [1.0.0] - 2025-11-26

### Added
- Initial release of GitBranchCleanup module
- Smart branch cleanup with configurable deletion criteria
- Support for merged, orphaned, and in-sync branch detection
- Dry-run mode for safe previewing
- Interactive confirmation mode
- Age-based filtering (minimum age threshold)
- Protected branches configuration
- Automatic remote fetching with pruning
- WhatIf/Confirm support via ShouldProcess
- Color-coded console output
- Comprehensive error handling
- SOLID principles architecture
- DRY pattern implementation

### Features
- `Invoke-BranchCleanup` - Main function for branch cleanup operations
- Deletion strategies:
  - Merged branches (default: enabled)
  - Orphaned branches (default: enabled)
  - In-sync branches (default: disabled)
- Default protection for common branches (main, master, develop, dev, test, staging, release)
- Configurable minimum age threshold (default: 7 days)

### Documentation
- Comprehensive README with examples
- Module manifest with metadata
- Inline help documentation for all public functions
- Architecture documentation

## [Unreleased]

### Planned
- Pester unit tests
- CI/CD pipeline with GitHub Actions
- PowerShell Gallery publication
- Support for multiple remote repositories
- Batch processing across multiple repositories
- JSON/CSV export of analysis results
- Custom deletion criteria via scriptblocks
- Undo/restore deleted branches
- Performance optimizations for large repositories
