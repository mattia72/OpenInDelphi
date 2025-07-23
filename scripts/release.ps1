# release.ps1
param(
    [ValidateSet("patch", "minor", "major")]
    [string]$versionType = "patch",
    [switch]$debug
)

# Stop script on first error
$ErrorActionPreference = "Stop"

function Build-ReleaseNotes {
    param(
        [string]$newVersion,
        [string]$changelogPath = "./CHANGELOG.md"
    )
    
    Write-Host "Building release notes for version $newVersion..."
    
    # Get changelog content
    $changelogFileContent = Get-Content $changelogPath
    $changeLogStartLine = ($changelogFileContent | Select-String -Pattern "## \[$newVersion\]").LineNumber 
    
    if (-not $changeLogStartLine) {
        Write-Error "FATAL: Could not find changelog for '$newVersion'. Aborting."
        exit 1
    }
    
    # Find the next version section to limit the changelog text
    $nextVersionLine = $null
    for ($i = $changeLogStartLine; $i -lt $changelogFileContent.Length; $i++) {
        if ($changelogFileContent[$i] -match "^## \[" -and $i -gt $changeLogStartLine - 1) {
            $nextVersionLine = $i
            break
        }
    }
    
    # Extract changelog text for current version only
    if ($nextVersionLine) {
        $changeLogText = $changelogFileContent[($changeLogStartLine - 1)..($nextVersionLine - 2)] -join "`n"
    }
    else {
        $changeLogText = $changelogFileContent[($changeLogStartLine - 1)..($changelogFileContent.Length - 1)] -join "`n"
    }
    
    # Escape special characters in changelog text
    $escapedChangeLogText = $changeLogText -replace '"', '\"' -replace '`', '\`'
    $releaseNotes = "Release version $newVersion`n`n$escapedChangeLogText"
    
    # Write to temporary file
    $tempNotesFile = "temp_release_notes.txt"
    $releaseNotes | Out-File -FilePath $tempNotesFile -Encoding UTF8
    
    Write-Host "Changelog text preview:"
    Write-Host "========================"
    Write-Host $changeLogText
    Write-Host "========================"
    
    return $tempNotesFile
}

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

Write-Host "Verifying that VSIX file '$vsixFile' exists..."
if (-not (Test-Path $vsixFile)) {
    Write-Error "FATAL: VSIX file '$vsixFile' was not found after packaging. Aborting."
    exit 1
}

if (-not $debug) {
    try { 
        # Build release notes using the separate function
        $tempNotesFile = Build-ReleaseNotes -newVersion $newVersion
    
        Write-Host "Creating release with tag: $tagName"
        Write-Host "Title: Release $tagName"
        Write-Host $(Get-Content $tempNotesFile)

        Read-Host "Do you want to continue with release creation? (Y/N)" -OutVariable userInput
        if ($userInput -inotmatch "Y") {
            Write-Host "Release creation aborted."
            exit 0
        }
    
        try {
            # Create release with notes from file
            Write-Host "Creating GitHub Release and uploading package..."
            # Check if gh.exe is installed (filter out aliases)
            $ghCommand = Get-Command gh -ErrorAction SilentlyContinue -CommandType Application
            if (-not $ghCommand) {
                Write-Error "FATAL: 'gh.exe' CLI is not installed or not found in PATH. Please install it from https://cli.github.com/ and ensure it's in your PATH."
                exit 1
            }
            & $ghCommand.Source release create $tagName --title "Release $tagName" --notes-file $tempNotesFile "$vsixFile"
            Write-Host "Release $tagName successfully created and asset uploaded!"
        }
        catch {
            Write-Error "Failed to create GitHub release. Error: $_"
            Write-Error "Please check your 'gh' CLI authentication and permissions."
            Write-Error "You can verify your status by running: gh auth status"
            exit 1
        }
    }
    finally {
        # Clean up temporary file
        if (Test-Path $tempNotesFile) {
            Remove-Item $tempNotesFile -Force
        }
    }
}

