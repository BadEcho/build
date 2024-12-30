# Creates a Git tag for the current version and then generates a new GitHub release.

param (
    [string]$ProductName,
    [string]$Repository
)

# Create a tag for the release version.
$versionSettings = Get-Content version.json | ConvertFrom-Json
$releaseTag = "v{0}.{1}.{2}" -f $versionSettings.majorVersion, $versionSettings.minorVersion, $versionSettings.patchVersion
git tag -a $releaseTag HEAD -m "$ProductName $releaseTag"
git push origin $releaseTag

# Create a new GitHub Release.
Compress-Archive -Path bin\rel\* -DestinationPath Binaries.zip
gh release create $releaseTag --repo="$Repository" --title="$ProductName $($releaseTag.TrimStart("v"))" --generate-notes "Binaries.zip #Binaries (zip)"