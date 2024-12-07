# Increments a version component in a repository's version file.

param (
    [ValidateSet('Major', 'Minor', 'Patch')]$ComponentToBump
)

$versionSettings = Get-Content version.json | ConvertFrom-Json

switch ($ComponentToBump) {
    Major {
        $versionSettings.majorVersion++
        $versionSettings.minorVersion = 0
        $versionSettings.patchVersion = 0
    }
    Minor {
        $versionSettings.minorVersion++
        $versionSettings.patchVersion = 0
    }
    Patch {
        $versionSettings.patchVersion++
    }
}

$versionSettings.prereleaseId = 'alpha'

ConvertTo-Json $versionSettings | Set-Content version1.json

git add version1.json
git commit -m "Bumping $($ComponentToBump.ToLower()) version component" 
git push origin