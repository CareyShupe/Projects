<#
	My modified profile script for PowerShell.
#>

# Requirements for PowerShell cmdlets, AST, and SuppressMessageAttribute
using namespace System.Management.Automation
using namespace System.Management.Automation.Language
using namespace System.Diagnostics.CodeAnalysis
#requires -Version 7.0

# Global Variables
$gitHubApiUrl = 'https://api.github.com/repos/PowerShell/PowerShell/releases/latest'
# Set UTF-8 by default on all PowerShell version.
$PSDefaultParameterValues['Out-File:Encoding'] = 'UTF-8'
# $ModulesToLoad is defined that will be used to load the required modules.
$ModulesToLoad = @('Terminal-Icons', 'PSReadLine', 'CompletionPredictor', 'PSScriptAnalyzer')
# This is an array that containing a list of editor names.
$editors = @('nvim', 'pvim', 'vim', 'vi', 'code', 'notepad++', 'sublime_text', 'notepad')
# $EDITOR is a variable that will store the editor name.
$EDITOR = $null

# Test-CommandExists check for apps are available or not.
function Test-CommandExists {
	param (
		[string]$command
	)
	# By placing `$null` on the left side, you ensure that the comparison is always valid, even if the command does not exist.
	return $null -ne (Get-Command $command -ErrorAction SilentlyContinue -CommandType Application)
}

# Check if I'm running with administration priviledge.
function Test-Administrator {
	return [System.Security.Principal.WindowsPrincipal]::new([System.Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Test GitHub.com connectivity
function Test-GitHubConnection {
	param (
		[string]$url = 'github.com'
	)
	# Initial GitHub.com connectivity check with 1 second timeout
	return Test-Connection $url -Count 1 -Quiet -TimeoutSeconds 1
}

# Get the latest PowerShell version from GitHub API
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

function Update-PowerShell {
	# Check GitHub.com connectivity
	if (-not (Test-GitHubConnection -url 'github.com')) {
		Write-Host 'Skipping PowerShell update check due to GitHub.com not responding within 1 second.' -ForegroundColor Yellow
		return
	}
}

# Get the current and latest PowerShell versions
Write-Host 'Checking for PowerShell updates...' -ForegroundColor Cyan
$currentVersion = [Version]$PSVersionTable.PSVersion.ToString()
$latestVersion = Get-LatestPowerShellVersion -apiUrl $gitHubApiUrl

# Check if the latest version is null
if ($null -eq $latestVersion) {
	Write-Host 'Could not determine the latest PowerShell version.' -ForegroundColor Red
	return
}

if ($currentVersion -lt $latestVersion) {
	Write-Host 'Updating PowerShell...' -ForegroundColor Yellow
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
	} else {
		Write-Host 'Your PowerShell is up to date.' -ForegroundColor Green
	}
}

# Function to install a PowerShell module if it is not already installed
function Install-ModuleAsNeeded {
	param (
		[string]$moduleName
	)
	if (-not (Get-Module -ListAvailable -Name $moduleName)) {
		try {
			Write-Host "Installing module $moduleName..."
			Install-Module -Name $moduleName -Scope CurrentUser -Force -SkipPublisherCheck -ErrorAction Stop
		} catch {
			Write-Error "Failed to install module $moduleName : $_"
		}
	}
}

# Load the required modules
If (-not $ModulesToLoad) {
	$ModulesToLoad
}

# Loop through each module in $ModulesToLoad and install if not available
foreach ($module in $ModulesToLoad) {
	if (-not (Get-Module -ListAvailable -Name $module)) {
		Install-ModuleAsNeeded -moduleName $module
	}
}

# Map PSDrives to other registry hives
$registryDrives = @(
	@{ Name = 'HKCR'; Root = 'HKEY_CLASSES_ROOT' },
	@{ Name = 'HKU'; Root = 'HKEY_USERS' }
)

foreach ($drive in $registryDrives) {
	if (!(Test-Path "$($drive.Name):")) {
		$null = New-PSDrive -Name $drive.Name -PSProvider Registry -Root $drive.Root
	}
}

# Calling the Update-PowerShell function
Update-PowerShell

# Example usage of Test-Administrator function
if (!(Test-Administrator)) {
	$Host.UI.RawUI.WindowTitle = 'User: '
	Start-Process PowerShell -Verb RunAsUser
}

# Set the default prompt to the Oh-My-Posh prompt
oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\blueish.omp.json" | Invoke-Expression

# Loop through the list of editors and check if the command exists.
foreach ($editor in $editors) {
	# If the command exists, set the $EDITOR variable to the editor name and break the loop.
	if (Test-CommandExists $editor) {
		# Set the $EDITOR variable to the editor name and break the loop.
		$EDITOR = $editor
		break
	}
}
# If the $EDITOR variable is still null, set it to 'notepad'.
if (-not $EDITOR) {
	$EDITOR = 'notepad'
}

# The Edit-Profile use $PROFILE variable to the path of the current user's profile to edit the script.
function Edit-Profile {
	vim $PROFILE
}

function Sync-Profile {
	try {
		# The dot operator is used to source the profile script.
		. $PROFILE
		# Writes to the console to indicate that the profile has been reloaded successfully or not.
		Write-Output 'Profile reloaded successfully.'
	} catch {
		Write-Output "Failed to reload profile: $_"
		Write-Error $_
	}
}

# Most of this came from the Sample PSReadLineProfile.ps1 at GitHub, Microsoft, YouTube and Google searching.
# The $PSROptions = @{} has helper in booting my Profile quicker.
$PSReadLineOptions = @{
	ContinuationPrompt            = ' '
	Colors                        = @{
		Command            = $PSStyle.Foreground.BrightYellow
		Comment            = $PSStyle.Foreground.BrightGreen
		ContinuationPrompt = $PSStyle.Foreground.BrightWhite
		Default            = $PSStyle.Foreground.BrightWhite
		Emphasis           = $PSStyle.Foreground.Cyan
		Error              = $PSStyle.Foreground.Red
		Keyword            = $PSStyle.Foreground.Magenta
		Member             = $PSStyle.Foreground.Cyan
		Number             = $PSStyle.Foreground.Magenta
		Operator           = $PSStyle.Foreground.White
		Parameter          = $PSStyle.Foreground.White
		Selection          = $PSStyle.Foreground.White + $PSStyle.Background.Cyan
		String             = $PSStyle.Foreground.Yellow
		Type               = $PSStyle.Foreground.Blue
		Variable           = $PSStyle.Foreground.Cyan
	}
	PredictionSource              = 'HistoryandPlugin'
	PredictionViewStyle           = 'ListView'
	EditMode                      = 'Windows'
	HistorySaveStyle              = 'SaveIncrementally'
	HistoryNoDuplicates           = $true
	HistorySearchCursorMovesToEnd = $true
	ShowToolTips                  = $true

	MaximumHistoryCount           = 4000
	BellStyle                     = 'Audible'
	DingTone                      = 1234
	DingDuration                  = 100
	AddToHistoryHandler           = {
		param($line)
		if ($line -match '^\s*#') {
			return
		}
		$line
	}

}

# Function to clear the cache
function Clear-Cache {
	try {
		Write-Host 'Starting Cache Clearing...' -ForegroundColor Green

		# Clear Windows Prefetch
		Write-Host 'Clearing Windows Prefetch...' -ForegroundColor Yellow
		Remove-Item -Path "$env:SystemRoot\Prefetch\*" -Force -ErrorAction SilentlyContinue

		# Clear Windows Temp
		Write-Host 'Clearing Windows Temp...' -ForegroundColor Yellow
		Remove-Item -Path "$env:SystemRoot\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue

		# Clear User Temp
		Write-Host 'Clearing User Temp...' -ForegroundColor Yellow
		Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue

		# Clear Internet Explorer Cache
		Write-Host 'Clearing Internet Explorer Cache...' -ForegroundColor Yellow
		Remove-Item -Path "$env:LOCALAPPDATA\Microsoft\Windows\INetCache\*" -Recurse -Force -ErrorAction SilentlyContinue

		# Clear Recycle Bin
		Write-Host 'Clearing Recycle Bin...' -ForegroundColor Yellow
		Clear-RecycleBin -Force

		# Clear Google Chrome Caches
		Write-Host 'Clearing Google Caches...' -ForegroundColor Yellow
		Remove-Item -Path "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache\*" -Recurse -Force -ErrorAction SilentlyContinue
		Remove-Item -Path "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache2\entries\*" -Recurse -Force -ErrorAction SilentlyContinue

		Write-Host 'Cache clearing completed successfully.' -ForegroundColor Green
	} catch {
		Write-Error "Failed to clear cache: $_"
	}
}

# Function to list all files in the current directory
function ll() {
 Get-ChildItem | Format-Table
}
function la() {
 Get-ChildItem | Format-Wide
}
function lb() {
 Get-ChildItem | Format-List
}
function which($name) {
	Get-Command $name | Select-Object -ExpandProperty Definition
}
# Set Aliases to the functions la, lb.
Set-Alias ls la
Set-Alias l lb
