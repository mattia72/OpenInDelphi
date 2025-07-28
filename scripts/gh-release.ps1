. "$PSScriptRoot\..\..\..\delphi\RipGrepper\deploy\GitHubReleaseUtils.ps1" 

function New-GitHubRelease {
    param(
        [string]$repo, # e.g. "mattia72/OpenInDelphi"
        [string]$tagName,
        [string]$releaseName,
        [string]$releaseNotes,
        [string]$vsixFile,
        [string]$githubToken
    )

    $owner, $repoName = $repo.Split('/')
    $url = "https://api.github.com/repos/$owner/$repoName/releases"
    $headers = @{
        "Content-Type"         = "application/json"
        Accept                 = "application/vnd.github+json"
        Authorization          = "Bearer $githubToken"
        "X-GitHub-Api-Version" = "2022-11-28"
    }

    # 1. Release anlegen
    $release = New-Release -url $url -headers $headers -version $tagName -description $releaseNotes -preRelease:$false
    if (-not $release.id) {
        Write-Error "Release creation failed!"
        return
    }

    # 2. Release Notes generieren (optional)
    $notes = New-ReleaseNotes -owner $owner -repo $repoName -headers $headers -version $tagName -prevVersion ""

    # 3. Asset hochladen
    Add-AssetToRelease -owner $owner -repo $repoName -token $githubToken -releaseID $release.id -zipFilePath $vsixFile
}