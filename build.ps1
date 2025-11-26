# Build script for GitBranchCleanup module
#Requires -Version 5.1

[CmdletBinding()]
param(
    [ValidateSet('Build', 'Test', 'Clean', 'Publish')]
    [string]$Task = 'Build',
    
    [string]$NuGetApiKey,
    
    [switch]$UpdateVersion
)

$ModuleName = 'GitBranchCleanup'
$ModulePath = Join-Path $PSScriptRoot $ModuleName
$TestPath = Join-Path $PSScriptRoot 'Tests'

function Build {
    Write-Host "Building $ModuleName..." -ForegroundColor Cyan
    
    # Validate module manifest
    $manifestPath = Join-Path $ModulePath "$ModuleName.psd1"
    $manifest = Test-ModuleManifest -Path $manifestPath -ErrorAction Stop
    Write-Host "  ✓ Manifest valid - Version $($manifest.Version)" -ForegroundColor Green
    
    # Import module
    Import-Module $manifestPath -Force
    Write-Host "  ✓ Module imported successfully" -ForegroundColor Green
    
    # Verify exported functions
    $commands = Get-Command -Module $ModuleName
    Write-Host "  ✓ Exported functions: $($commands.Name -join ', ')" -ForegroundColor Green
}

function Test {
    Write-Host "Running tests..." -ForegroundColor Cyan
    
    # Check if Pester is installed
    $pester = Get-Module -ListAvailable -Name Pester | Where-Object { $_.Version -ge '5.0.0' }
    if (-not $pester) {
        Write-Host "  Installing Pester 5.x..." -ForegroundColor Yellow
        Install-Module -Name Pester -MinimumVersion 5.0.0 -Force -SkipPublisherCheck
    }
    
    # Run tests
    $result = Invoke-Pester -Path $TestPath -PassThru
    
    if ($result.FailedCount -gt 0) {
        throw "  ✗ $($result.FailedCount) test(s) failed"
    }
    
    Write-Host "  ✓ All tests passed ($($result.PassedCount) tests)" -ForegroundColor Green
}

function Clean {
    Write-Host "Cleaning build artifacts..." -ForegroundColor Cyan
    
    # Remove imported module
    Remove-Module $ModuleName -ErrorAction SilentlyContinue
    Write-Host "  ✓ Cleaned" -ForegroundColor Green
}

function Publish {
    Write-Host "Publishing $ModuleName to PowerShell Gallery..." -ForegroundColor Cyan
    
    if (-not $NuGetApiKey) {
        throw "NuGetApiKey parameter is required for publishing"
    }
    
    # Run build and tests first
    Build
    Test
    
    # Publish to PowerShell Gallery
    $publishParams = @{
        Path        = $ModulePath
        NuGetApiKey = $NuGetApiKey
        Verbose     = $true
        Force       = $true
    }
    
    Publish-Module @publishParams
    Write-Host "  ✓ Published successfully" -ForegroundColor Green
}

# Execute task
switch ($Task) {
    'Build' { Build }
    'Test' { Test }
    'Clean' { Clean }
    'Publish' { Publish }
}

Write-Host "`n$Task completed successfully!" -ForegroundColor Green
