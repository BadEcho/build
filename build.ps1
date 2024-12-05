# Builds the Bad Echo solution.

param (
	[string]$CommitId,
	[string]$VersionDistance,
	# Used to specify the configuration build to use in place of Release to prevent attempts to package native projects.
	[string]$PackageConfiguration
)

function Execute([scriptblock]$command) {
	& $command
	if ($lastexitcode -ne 0) {
		throw ("Build command errored with exit code: " + $lastexitcode)
	}
}

function AppendCommand([string]$command, [string]$commandSuffix){
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

$versionSettings = Get-Content version.json | ConvertFrom-Json
$majorVersion = $versionSettings[0].majorVersion
$minorVersion = $versionSettings[0].minorVersion
$patchVersion = $versionSettings[0].patchVersion

$buildCommand =  { & msbuild -p:Configuration=Release -p:MajorVersion=$majorVersion -p:MinorVersion=$minorVersion -p:PatchVersion=$patchVersion }
# If there are any native projects in the solution, then a separate configuration created specifically for use during NuGet package creation needs to be made.
# This configuration needs to have all native projects excluded from being built so we don't attempt to pack them. Normally, we'd assign a value of false to the
# IsPackable element for the project, however MSBuild ignores this property and errors out anyway.
$packCommand = { & msbuild -t:Pack -p:Configuration=$PackageConfiguration -p:PackageOutputPath=$artifacts -p:NoBuild=true -p:MajorVersion=$majorVersion -p:MinorVersion=$minorVersion -p:PatchVersion=$patchVersion }

if($CommitId -and $VersionDistance) {	
	$prereleaseId = $versionSettings[0].prereleaseId		
	$versionCommand = "-p:BuildMetadata=$CommitId -p:PrereleaseId=$prereleaseId -p:BuildNumber=$VersionDistance"

	$buildCommand = AppendCommand($buildCommand.ToString(), $versionCommand)
	$packCommand = AppendCommand($packCommand.ToString(), $versionCommand)
}

Execute { & msbuild -p:Configuration=Release -t:Clean }
Execute { & msbuild -p:Configuration=Release -t:Restore }
Execute $buildCommand 
Execute $packCommand