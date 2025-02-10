# PowerShell GitHub API URL
$gitHubApiUrl = 'https://api.github.com/repos/PowerShell/PowerShell/releases/latest'

# Function to check for PowerShell updates
function Get-PowerShellUpdate {
    Write-Output 'Checking for PowerShell updates...' -ForegroundColor Cyan
    $currentVersion = $PSVersionTable.PSVersion

    try {
        $latestVersion = [System.Version]((Invoke-RestMethod -Uri $gitHubApiUrl).tag_name.TrimStart('v'))
    } catch {
        Write-Output 'Failed to retrieve the latest version information.' -ForegroundColor Red
        return $false
    }

    if ($currentVersion -eq $latestVersion) {
        return $true
    } else {
        return $false
    }
}

# Check if PowerShell is up to date
if (Get-PowerShellgit status
Update) {
    Write-Output 'PowerShell is up to date...'
} else {
    Write-Output 'A new version of PowerShell is available.'
}
