@{
    # Script module or binary module file associated with this manifest.
    RootModule = 'GitBranchCleanup.psm1'

    # Version number of this module.
    ModuleVersion = '1.1.0'

    # ID used to uniquely identify this module
    GUID = 'a7d9c4e5-f2b3-4a1d-9e8f-6c5b4a3d2e1f'

    # Author of this module
    Author = 'GitBranchCleanup Contributors'

    # Company or vendor of this module
    CompanyName = 'Community'

    # Copyright statement for this module
    Copyright = '(c) 2025 GitBranchCleanup Contributors. All rights reserved.'

    # Description of the functionality provided by this module
    Description = 'A PowerShell module for cleaning up stale, merged, and orphaned local Git branches with configurable criteria and safety features.'

    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion = '5.1'

    # Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
    FunctionsToExport = @('Invoke-BranchCleanup')

    # Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
    CmdletsToExport = @()

    # Variables to export from this module
    VariablesToExport = @()

    # Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
    AliasesToExport = @()

    # Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
    PrivateData = @{
        PSData = @{
            # Tags applied to this module. These help with module discovery in online galleries.
            Tags = @('Git', 'Branch', 'Cleanup', 'DevOps', 'SourceControl', 'Maintenance')

            # A URL to the license for this module.
            LicenseUri = 'https://github.com/yourusername/GitBranchCleanup/blob/main/LICENSE'

            # A URL to the main website for this project.
            ProjectUri = 'https://github.com/yourusername/GitBranchCleanup'

            # A URL to an icon representing this module.
            # IconUri = ''

            # ReleaseNotes of this module
            ReleaseNotes = 'Fix branch parsing for worktree-checked-out and detached-HEAD repositories; add Pester 5 regression coverage.'

            # Prerelease string of this module
            # Prerelease = 'preview'

            # Flag to indicate whether the module requires explicit user acceptance for install/update/save
            # RequireLicenseAcceptance = $false

            # External dependent modules of this module
            # ExternalModuleDependencies = @()
        }
    }
}
