# PowerShell GitHub API URL
$gitHubApiUrl = 'https://api.github.com/repos/PowerShell/PowerShell/releases/latest'

# Function to check for PowerShell updates
function Get-PowerShellUpdate {
	Write-Host 'Checking for PowerShell updates...' -ForegroundColor Cyan
	$currentVersion = $PSVersionTable.PSVersion
	$latestVersion = [System.Version]((Invoke-RestMethod -Uri $gitHubApiUrl).tag_name.TrimStart('v'))

	if ($currentVersion -eq $latestVersion) {
		return $true
	} else {
		return $false
	}
}

# Check if PowerShell is up to date
if (Get-PowerShellUpdate) {
	Write-Host 'Your PowerShell is up to date...'
} else {
	Write-Host 'A new version of PowerShell is available.'
}
