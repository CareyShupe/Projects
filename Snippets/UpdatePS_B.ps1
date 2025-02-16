# PowerShell GitHub API URL
$gitHubApiUrl = 'https://api.github.com/repos/PowerShell/PowerShell/releases/latest'

# Function to check for PowerShell updates
function Get-PowerShellUpdate {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false)]
        [ValidatePattern('^https://api\.github\.com/repos/.+/releases/latest$')]
        [string]$ApiUrl = $gitHubApiUrl
    )

    Write-Output 'Checking for PowerShell updates...' 
    $currentVersion = $PSVersionTable.PSVersion

    try {
        $response = Invoke-RestMethod -Uri $ApiUrl
        $latestVersion = [System.Version]($response.tag_name.TrimStart('v'))
    } catch {
        Write-Output 'Failed to retrieve the latest version information.' -ForegroundColor Red
        return $false
    } finally {
        Write-Verbose 'Completed version check.'
    }

    if ($currentVersion -eq $latestVersion) {
        Write-Output "Your PowerShell version ($currentVersion) is up to date."
        return $true
    } else {
        Write-Output "A new version of PowerShell ($latestVersion) is available. Your current version is $currentVersion."
        return $false
    }
}

# Check if PowerShell is up to date
#if (Get-PowerShellUpdate -Verbose) {
    Write-Output 'Your PowerShell is up to date...'
#} else {
#    Write-Output 'A new version of PowerShell is available.'
#}
Get-PowerShellUpdate
