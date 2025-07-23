# release.ps1
param(
    [ValidateSet("patch", "minor", "major")]
    [string]$versionType = "patch",
    [switch]$debug
)

# Stop script on first error
$ErrorActionPreference = "Stop"

Write-Host "Starting release process with version type: $versionType..."

# 1. Bump version and create the .vsix package
if ($debug) {
    Write-Host "Bumping version and packaging debug version..."
    vsce package 
}
else {
    Write-Host "Bumping version and packaging $versionType version..."
    vsce package $versionType
}

# 2. Get the new version and VSIX filename from package.json
$packageJson = Get-Content ./package.json | ConvertFrom-Json
$newVersion = $packageJson.version
$vsixFile = "openindelphi-$newVersion.vsix"
$tagName = "v$newVersion"

Write-Host "New version: $newVersion"
Write-Host "VSIX file: $vsixFile"

if (-not $debug) {
    # 3. Add, commit, and tag the new version
    Read-Host "Committing and tagging version... Press Enter to continue"
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
    # get text from changelog started from the first ## [x.y.z] version
    $changelogFileContent = Get-Content ./CHANGELOG.md
    $changeLogStartLine = ($changelogFileContent  | Select-String -Pattern "## \[$newVersion\]").LineNumber 
    if (-not $changeLogStartLine) {
        Write-Error "FATAL: Could not find changelog entry for version '$newVersion'. Aborting."
        exit 1
    }
    $changeLogText = $changelogFileContent[$changeLogStartLine..($changelogFileContent.Length - 1)] -join "`n"

    # 6. Create GitHub Release and upload the .vsix file
    Write-Host "Creating GitHub Release and uploading package..."
    try {
        gh release create $tagName --title "Release $tagName" --notes "Release version $newVersion `n`n$changeLogText"
        gh release upload $tagName "$vsixFile" --clobber
    }
    catch {
        Write-Error "Failed to create GitHub release. Please check your 'gh' CLI authentication and permissions."
        Write-Error "You can verify your status by running: gh auth status"
        exit 1
    }
    finally {
        Write-Host "Release $tagName successfully published to GitHub!"
    }
}

