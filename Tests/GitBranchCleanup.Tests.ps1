# Sample Pester test file
# Install Pester 5.x: Install-Module -Name Pester -MinimumVersion 5.0.0 -Force

BeforeAll {
    # Import the module
    $ModulePath = Join-Path (Join-Path (Join-Path $PSScriptRoot '..') 'GitBranchCleanup') 'GitBranchCleanup.psd1'
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
            $manifest = Test-ModuleManifest -Path (Join-Path (Join-Path (Join-Path $PSScriptRoot '..') 'GitBranchCleanup') 'GitBranchCleanup.psd1')
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

Describe 'Worktree-aware branch parsing' {
    # Regression tests for the parser fix: branches checked out in a linked
    # worktree (git marks them '+ ') and the detached-HEAD pseudo-entry used to
    # leak through as bogus branch names and crash downstream git calls with
    # "fatal: ambiguous argument". All git calls are mocked, so these are hermetic.

    Context 'Get-WorktreeBranches' {
        It 'extracts branches checked out in worktrees and ignores detached worktrees' {
            InModuleScope GitBranchCleanup {
                Mock Invoke-GitCommand {
                    @{
                        Success  = $true
                        ExitCode = 0
                        Output   = @(
                            'worktree C:/repo'
                            'HEAD 0a91a68'
                            'branch refs/heads/fix/PE-835'
                            ''
                            'worktree C:/repo/.wt/feature'
                            'HEAD a8d1661'
                            'branch refs/heads/claude/gifted-williamson'
                            ''
                            'worktree C:/repo/.wt/detached'
                            'HEAD abc1234'
                            'detached'
                        )
                    }
                } -ParameterFilter { $Arguments[0] -eq 'worktree' }

                $result = Get-WorktreeBranches

                $result | Should -Contain 'fix/PE-835'
                $result | Should -Contain 'claude/gifted-williamson'
                @($result).Count | Should -Be 2
            }
        }

        It 'returns an empty collection when the git command fails' {
            InModuleScope GitBranchCleanup {
                Mock Invoke-GitCommand { @{ Success = $false; ExitCode = 128; Output = @() } } `
                    -ParameterFilter { $Arguments[0] -eq 'worktree' }

                @(Get-WorktreeBranches).Count | Should -Be 0
            }
        }
    }

    Context 'Get-CandidateBranches' {
        It 'excludes current, protected, and worktree-checked-out branches' {
            InModuleScope GitBranchCleanup {
                Mock Invoke-GitCommand {
                    @{
                        Success  = $true
                        ExitCode = 0
                        Output   = @(
                            'activity-import-changes'
                            'add-netline-provider'
                            'cerebro-3093_mappings'
                            'claude/gifted-williamson'
                            'dev'
                            'dev-base'
                            'epic/CEREBRO-2754'
                            'feat/CEREBRO-2874'
                            'fix/PE-835'
                            'master'
                            'task/CEREBRO-2883'
                            'test'
                        )
                    }
                } -ParameterFilter { $Arguments[0] -eq 'for-each-ref' }

                Mock Invoke-GitCommand {
                    @{
                        Success  = $true
                        ExitCode = 0
                        Output   = @(
                            'worktree C:/repo'
                            'branch refs/heads/fix/PE-835'
                            ''
                            'worktree C:/repo/.wt/a'
                            'branch refs/heads/add-netline-provider'
                            ''
                            'worktree C:/repo/.wt/b'
                            'branch refs/heads/cerebro-3093_mappings'
                            ''
                            'worktree C:/repo/.wt/c'
                            'branch refs/heads/claude/gifted-williamson'
                        )
                    }
                } -ParameterFilter { $Arguments[0] -eq 'worktree' }

                $candidates = Get-CandidateBranches `
                    -ProtectedBranches @('main', 'master', 'dev', 'test') `
                    -CurrentBranch 'fix/PE-835'

                $expected = @(
                    'activity-import-changes'
                    'dev-base'
                    'epic/CEREBRO-2754'
                    'feat/CEREBRO-2874'
                    'task/CEREBRO-2883'
                )
                @($candidates).Count | Should -Be $expected.Count
                foreach ($branch in $expected) { $candidates | Should -Contain $branch }

                # Worktree branches must never appear as candidates (git can't delete them).
                $candidates | Should -Not -Contain 'add-netline-provider'
                $candidates | Should -Not -Contain 'claude/gifted-williamson'
            }
        }

        It 'never emits status markers or the detached-HEAD pseudo-entry' {
            InModuleScope GitBranchCleanup {
                # for-each-ref yields clean names, so a detached HEAD (no current branch)
                # produces real candidates only - no '(HEAD detached ...)' entry.
                Mock Invoke-GitCommand {
                    @{ Success = $true; ExitCode = 0; Output = @('main', 'feature-old') }
                } -ParameterFilter { $Arguments[0] -eq 'for-each-ref' }

                Mock Invoke-GitCommand {
                    @{ Success = $true; ExitCode = 0; Output = @() }
                } -ParameterFilter { $Arguments[0] -eq 'worktree' }

                $candidates = Get-CandidateBranches -ProtectedBranches @('main') -CurrentBranch ''

                $candidates | Should -Contain 'feature-old'
                $candidates | Should -Not -Contain 'main'
                foreach ($c in $candidates) {
                    $c | Should -Not -Match '^[*+]'
                    $c | Should -Not -Match 'HEAD detached'
                }
            }
        }
    }

    Context 'Get-MergedBranches' {
        It 'strips both the current (*) and worktree (+) status markers' {
            InModuleScope GitBranchCleanup {
                Mock Invoke-GitCommand {
                    @{
                        Success  = $true
                        ExitCode = 0
                        Output   = @(
                            '  feature-merged'
                            '* current-branch'
                            '+ worktree-merged'
                            '  master'
                        )
                    }
                } -ParameterFilter { $Arguments[0] -eq 'branch' -and $Arguments[1] -eq '--merged' }

                $merged = Get-MergedBranches -TargetBranch 'master'

                $merged | Should -Contain 'feature-merged'
                $merged | Should -Contain 'current-branch'
                $merged | Should -Contain 'worktree-merged'
                $merged | Should -Contain 'master'
                foreach ($m in $merged) { $m | Should -Not -Match '^[*+]' }
            }
        }
    }
}
