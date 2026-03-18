# Builds Bad Echo solutions.

param (
	# If set, then a stable release build, as opposed to a pre-release build, is packaged.
	[switch]$ReleaseBuild,
	# Used to specify the configuration build to use in place of Release to prevent attempts to package native projects.
	[string]$PackageConfiguration,
	# Used to define additional MSBuild properties to use during package restoration.
	[string[]]$AdditionalRestoreProperties,
	# If set, MSBuild will be used to run the Restore target instead of dotnet.
	[switch]$UseMSBuildRestore
)

function Execute([scriptblock]$command) {
	$commandDescription = "$($command.ToString().TrimStart("& "))"
	Write-Host "Executing build command: $($commandDescription)"
	& $command
	if ($lastexitcode -ne 0) {			
		throw("Failed: $($commandDescription)")
	}
}

function AppendCommand([string]$command, [string]$commandSuffix) {
	return [ScriptBlock]::Create($command + $commandSuffix)
}

if (!$PackageConfiguration) {
	$PackageConfiguration = "Release"
}

New-Item -ItemType Directory -Force .\artifacts
$artifacts = Resolve-Path .\artifacts\ | Select-Object -ExpandProperty Path

if (Test-Path $artifacts) {
	Remove-Item $artifacts -Force -Recurse
}

$versionDistance = git rev-list --count "$(git log -1 --pretty=format:"%H" version.json)..HEAD"

$buildCommand = { & msbuild -p:Configuration=Release -p:BuildNumber=$versionDistance }
# If there are any native projects in the solution, then a separate configuration created specifically for use during NuGet package creation needs to be made.
# This configuration needs to have all native projects excluded from being built so we don't attempt to pack them. Normally, we'd assign a value of false to the
# IsPackable element for the project, however MSBuild ignores this property and errors out anyway.
$packCommand = { & msbuild -t:Pack -p:Configuration=$PackageConfiguration -p:PackageOutputPath=$artifacts -p:BuildNumber=$versionDistance }

if ($UseMSBuildRestore) {
	$restoreCommand = { & msbuild -t:Restore }
}
else {
	$restoreCommand = { & dotnet restore }
}

$restoreCommand = AppendCommand($restoreCommand.ToString(), "/p:DisableWarnForInvalidRestoreProjects=true /p:Configuration=Release")

if ($AdditionalRestoreProperties) {
	$restoreCommandProperties = Join-String -FormatString " /p:{0}" -InputObject $AdditionalRestoreProperties	
	$restoreCommand = AppendCommand($restoreCommand.ToString(), $restoreCommandProperties)
}

if (-Not $ReleaseBuild) {
	$commitId = git rev-parse --short HEAD
	$versionCommand = "-p:BuildMetadata=$commitId"

	$buildCommand = AppendCommand($buildCommand.ToString(), $versionCommand)
	$packCommand = AppendCommand($packCommand.ToString(), $versionCommand)
}

Execute { & msbuild -p:Configuration=Release -t:Clean }
Execute $restoreCommand
Execute $buildCommand 
Execute $packCommand