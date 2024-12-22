# Creates a Git tag for a new release.

param (
    [string]$ProductName
)

$versionSettings = Get-Content version.json | ConvertFrom-Json
$releaseTag = "v{0}.{1}.{2}" -f $versionSettings.majorVersion, $versionSettings.minorVersion, $versionSettings.patchVersion
git tag -a $releaseTag HEAD -m "$ProductName $releaseTag"
git push origin $releaseTag

return $releaseTag