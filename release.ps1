# release.ps1
param(
    [ValidateSet("patch", "minor", "major")]
    [string]$versionType = "patch"
)

# Stop script on first error
$ErrorActionPreference = "Stop"

Write-Host "Starting release process with version type: $versionType..."

# 1. Bump version and create the .vsix package
Write-Host "Bumping version and packaging..."
vsce package $versionType

# 2. Get the new version and VSIX filename from package.json
$packageJson = Get-Content ./package.json | ConvertFrom-Json
$newVersion = $packageJson.version
$vsixFile = "openindelphi-$newVersion.vsix"
$tagName = "v$newVersion"

Write-Host "New version: $newVersion"
Write-Host "VSIX file: $vsixFile"

# 3. Add, commit, and tag the new version
Write-Host "Committing and tagging version..."
git add package.json
git commit -m "Release $tagName"
git tag $tagName

# 4. Push commit and tags to GitHub
Write-Host "Pushing to GitHub..."
git push
git push --tags

# 5. Verify the .vsix file exists
Write-Host "Verifying that VSIX file '$vsixFile' exists..."
if (-not (Test-Path $vsixFile)) {
    Write-Error "FATAL: VSIX file '$vsixFile' was not found after packaging. Aborting."
    exit 1
}
Write-Host "VSIX file found."

# 6. Create GitHub Release and upload the .vsix file
Write-Host "Creating GitHub Release and uploading package..."
try {
    gh release create $tagName --title "Release $tagName" --notes "Release version $newVersion" "$vsixFile"
} catch {
    Write-Error "Failed to create GitHub release. Please check your 'gh' CLI authentication and permissions."
    Write-Error "You can verify your status by running: gh auth status"
    exit 1
}

Write-Host "? Release $tagName successfully published to GitHub!"
