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
        Write-Output "Your PowerShell version ($currentVersion) is up to date."
        return $true
    } else {
        Write-Output "A new version of PowerShell ($latestVersion) is available. Your current version is $currentVersion."
        return $false
    }
}

# Check if PowerShell is up to date
if (Get-PowerShellUpdate) {
    Write-Output 'Your PowerShell is up to date...'
} else {
    Write-Output 'A new version of PowerShell is available.'
}
