# Increments a component of a version in a repository's version file.

param (
    [ValidateSet('Major', 'Minor', 'Patch')]$ComponentToBump
)

$versionSettings = Get-Content version.json | ConvertFrom-Json

        switch (Patch) {
            Major {
                $versionSettings[0].majorVersion++
            }
            Minor {
                $versionSettings[0].minorVersion++
            }
            Patch {
                $versionSettings[0].patchVersion++
            }
        }

ConvertTo-Json $versionSettings | Set-Content version1.json

git add version1.json
git commit -m "Bumping version" 
git push origin