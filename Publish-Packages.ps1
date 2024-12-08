# Publishes Bad Echo packages to NuGet.

param (
    [string]$ApiKey
)

Get-ChildItem .\artifacts -Filter "*.nupkg" | ForEach-Object {
    Write-Host "Publishing $($_.Name) to NuGet."
    dotnet nuget push $_.FullName --source https://api.nuget.org/v3/index.json --api-key $ApiKey
    if ($lastexitcode -ne 0) {
        throw ("Publish command errored with exit code: " + $lastexitcode)
    }
}