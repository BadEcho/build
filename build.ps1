# Builds the Bad Echo solution.

param (
	[string]$CommitId,
	[string]$VersionDistance,
	[switch]$SkipTests
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

New-Item -ItemType Directory -Force .\artifacts
$artifacts = Resolve-Path .\artifacts\ | select -ExpandProperty Path

if (Test-Path $artifacts) {
	Remove-Item $artifacts -Force -Recurse
}

$versionSettings = Get-Content version.json | ConvertFrom-Json
$majorVersion = $versionSettings[0].majorVersion
$minorVersion = $versionSettings[0].minorVersion
$patchVersion = $versionSettings[0].patchVersion

$buildCommand =  { & dotnet build -c Release -p:MajorVersion=$majorVersion -p:MinorVersion=$minorVersion -p:PatchVersion=$patchVersion }
$packCommand = { & dotnet pack -c Release -p:PackageOutputPath=$artifacts --no-build -p:MajorVersion=$majorVersion -p:MinorVersion=$minorVersion -p:PatchVersion=$patchVersion }

if($CommitId -and $VersionDistance) {	
	$prereleaseId = $versionSettings[0].prereleaseId
		
	$versionCommand = "-p:BuildMetadata=$CommitId -p:PrereleaseId=$prereleaseId -p:BuildNumber=$VersionDistance"

	$buildCommand = AppendCommand($buildCommand.ToString(), $versionCommand)
	$packCommand = AppendCommand($packCommand.ToString(), $versionCommand)
}

Execute { & dotnet clean -c Release }
Execute $buildCommand 

if ($SkipTests -ne $true) {
	Execute { & dotnet test -c Release --results-directory $artifacts --no-build -l trx --verbosity=normal }
}

Execute $packCommand