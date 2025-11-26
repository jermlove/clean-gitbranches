@{
    # Only report errors and warnings, not informational messages
    Severity = @('Error', 'Warning')

    # Rules to exclude
    ExcludeRules = @(
        # Write-Host is intentional for user-facing colored output in interactive tool
        'PSAvoidUsingWriteHost',
        
        # Plural nouns are appropriate for these internal functions that return collections
        'PSUseSingularNouns',
        
        # Process block not needed for simple pipeline-enabled parameter
        'PSUseProcessBlockForPipelineCommand'
    )
    
    # Include default rules
    IncludeDefaultRules = $true
}
