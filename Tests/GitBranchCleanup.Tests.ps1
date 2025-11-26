# Sample Pester test file
# Install Pester 5.x: Install-Module -Name Pester -MinimumVersion 5.0.0 -Force

BeforeAll {
    # Import the module
    $ModulePath = Join-Path $PSScriptRoot '..' 'GitBranchCleanup' 'GitBranchCleanup.psd1'
    Import-Module $ModulePath -Force
}

Describe 'GitBranchCleanup Module' {
    Context 'Module Structure' {
        It 'Should import successfully' {
            $module = Get-Module -Name GitBranchCleanup
            $module | Should -Not -BeNullOrEmpty
        }
        
        It 'Should export Invoke-BranchCleanup function' {
            $commands = Get-Command -Module GitBranchCleanup
            $commands.Name | Should -Contain 'Invoke-BranchCleanup'
        }
        
        It 'Should have valid manifest' {
            $manifest = Test-ModuleManifest -Path (Join-Path $PSScriptRoot '..' 'GitBranchCleanup' 'GitBranchCleanup.psd1')
            $manifest | Should -Not -BeNullOrEmpty
            $manifest.Version | Should -Be '1.0.0'
        }
    }
    
    Context 'Invoke-BranchCleanup Parameters' {
        BeforeAll {
            $command = Get-Command Invoke-BranchCleanup
        }
        
        It 'Should have DryRun parameter' {
            $command.Parameters.Keys | Should -Contain 'DryRun'
        }
        
        It 'Should have Interactive parameter' {
            $command.Parameters.Keys | Should -Contain 'Interactive'
        }
        
        It 'Should have ProtectedBranches parameter' {
            $command.Parameters.Keys | Should -Contain 'ProtectedBranches'
        }
        
        It 'Should have RepositoryPath parameter' {
            $command.Parameters.Keys | Should -Contain 'RepositoryPath'
        }
        
        It 'Should have FetchFirst parameter' {
            $command.Parameters.Keys | Should -Contain 'FetchFirst'
        }
        
        It 'Should have DeleteMerged parameter' {
            $command.Parameters.Keys | Should -Contain 'DeleteMerged'
        }
        
        It 'Should have DeleteOrphaned parameter' {
            $command.Parameters.Keys | Should -Contain 'DeleteOrphaned'
        }
        
        It 'Should have DeleteInSync parameter' {
            $command.Parameters.Keys | Should -Contain 'DeleteInSync'
        }
        
        It 'Should have MaxAge parameter' {
            $command.Parameters.Keys | Should -Contain 'MaxAge'
        }
        
        It 'Should support ShouldProcess (WhatIf/Confirm)' {
            $command.Parameters.Keys | Should -Contain 'WhatIf'
            $command.Parameters.Keys | Should -Contain 'Confirm'
        }
    }
}

# Additional tests would go here for:
# - Repository validation
# - Branch detection
# - Deletion criteria logic
# - Error handling
# - etc.
