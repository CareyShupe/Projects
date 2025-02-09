# PowerShell GitHub API URL
$gitHubApiUrl = 'https://api.github.com/repos/PowerShell/PowerShell/releases/latest'

# Test GitHub.com connectivity
function Test-GitHubConnection {
	param (
		[string]$url = 'github.com'
	)
	# Initial GitHub.com connectivity check with 1 second timeout
	return Test-Connection $url -Count 1 -Quiet -TimeoutSeconds 1
}

# Get the latest PowerShell version from GitHub
function Get-LatestPowerShellVersion {
	param (
		[string]$apiUrl
	)
	try {
		$latestReleaseInfo = Invoke-RestMethod -Uri $apiUrl -TimeoutSec 5
		return [Version]$latestReleaseInfo.tag_name.Trim('v')
	} catch {
		Write-Error "Failed to retrieve the latest PowerShell version. Error: $_"
		return $null
	}
}

# Update PowerShell if a newer version is available.
function Update-PowerShell {
	# Check GitHub.com connectivity
	if (-not (Test-GitHubConnection -url 'github.com')) {
		Write-Host 'Skipping PowerShell update check due to GitHub.com not responding within 1 second.' -ForegroundColor Yellow
		return
	}

	# Get the current and latest PowerShell versions
	Write-Host 'Checking for PowerShell updates...' -ForegroundColor Cyan
	$currentVersion = $PSVersionTable.PSVersion
	$latestVersion = Get-LatestPowerShellVersion -apiUrl $gitHubApiUrl

	# Check if the latest version is null
	if ($null -eq $latestVersion) {
		Write-Host 'Could not determine the latest PowerShell version.' -ForegroundColor Red
		return
	}

	# Check if the current version is less than the latest version.
	# You can reverse the logic and check $latestVersion -gt $currentVersion and if the latest version is greater than the current version.
	# Both works either way.
	if ($currentVersion -lt $latestVersion) {
		Write-Host "Updating PowerShell from version $currentVersion to $latestVersion." -ForegroundColor Yellow
		$packageManagers = @('winget', 'choco', 'scoop')
		$updated = $false
		# Loop through the package managers to find the first one that is available
		foreach ($pm in $packageManagers) {
			if (Test-CommandExists $pm) {
				try {
					# Use the package manager to update PowerShell
					switch ($pm) {
						'winget' {
							winget upgrade 'Microsoft.PowerShell' --accept-source-agreements --accept-package-agreements
						}
						'choco' {
							choco upgrade powershell-core -y
						}
						'scoop' {
							scoop install powershell-core
						}
					}
					Write-Host 'PowerShell has been updated. Please restart your shell to reflect changes' -ForegroundColor Magenta
					$updated = $true
					break
				} catch {
					Write-Error "Failed to update PowerShell using $pm. Error: $_"
				}
			}
		}
		if (-not $updated) {
			Write-Error 'No supported package manager found to update PowerShell.'
		}
	} else {
		# No update required
		Write-Host "PowerShell is up-to-date. Current version: $currentVersion." -ForegroundColor Blue
	}
}

# This function Test-CommandExists is used to check for apps is available or not.
function Test-CommandExists {
	param (
		[string]$command
	)
	# By placing `$null` on the left side, you ensure that the comparison is always valid, even if the command does not exist.
	return $null -ne (Get-Command $command -ErrorAction SilentlyContinue -CommandType Application)
}

# Run the update check
Update-PowerShell
