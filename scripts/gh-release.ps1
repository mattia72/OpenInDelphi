. "$PSScriptRoot\..\..\..\..\delphi\RipGrepper\deploy\GitHubReleaseUtils.ps1" 

function New-GitHubRelease {
    param(
        [string]$Repo, # e.g. "mattia72/OpenInDelphi"
        [string]$TagName,
        [string]$ReleaseName,
        [string]$ReleaseNotes,
        [string]$VsixFile,
        [string]$GithubToken,
        [switch]$SkipCreateRelease,
        [switch]$DryRun
    )

    try {
        
        $owner, $repoName = $repo.Split('/', 2)
        $url = "https://api.github.com/repos/$owner/$repoName/releases"
        $headers = @{
            "Content-Type"         = "application/json"
            Accept                 = "application/vnd.github+json"
            Authorization          = "Bearer $githubToken"
            "X-GitHub-Api-Version" = "2022-11-28"
        }

        if (-not $SkipCreateRelease) {
            $release = New-Release -url $url -headers $headers -version $tagName -description $releaseNotes -preRelease:$false -dryRun:$DryRun
            $ReleaseID = $release.id
        }
        else {
            $latest = Get-Releases  -URl $url -Headers $headers -Latest -Tag $tagName
            $ReleaseID = $($latest | Select-Object -Property id).id
        }

        # 2. Release Notes (optional)
        # $notes = New-ReleaseNotes -owner $owner -repo $repoName -headers $headers -version $tagName -prevVersion ""

        # 3. Create zip file from VSIX
        if (-not (Test-Path $vsixFile)) {
            Write-Error "FATAL: VSIX file '$vsixFile' does not exist. Cannot upload asset."
            exit 1
        } 
        $assetDir = "$PSScriptRoot\..\assets" 
        New-Item -ItemType Directory -Path "$assetDir" -Force | Out-Null
        Remove-Item "$assetDir\*" -Force -ErrorAction SilentlyContinue
        Copy-Item $vsixFile -Destination $assetDir -Force
        $zipFilePath = Join-Path $PSScriptRoot $($vsixFile -replace '\.vsix$', '.zip')

        $compress = @{
            Path             = "$assetDir\*.*"
            CompressionLevel = "Fastest"
            DestinationPath  = "$zipFilePath"
            Force            = $true
        }

        Compress-Archive @compress -Verbose
        if ( -not (Test-Path $zipFilePath)) {
            Write-Error "FATAL: Failed to create zip file '$zipFilePath'. Aborting."
            exit 1
        }

        # 3. Asset upload
        $params = @{
            Owner       = $owner
            Repo        = $repoName
            Token       = $githubToken
            ReleaseID   = $ReleaseID
            ZipFilePath = $zipFilePath
            DryRun      = $DryRun
        }
        Add-AssetToRelease @params
    }
    catch {
        Write-Error "Failed to create GitHub release. Error: $_"
        exit 1
    }
    finally {
        # Clean up temporary files
        if (Test-Path $zipFilePath -ErrorAction SilentlyContinue) {
            Remove-Item $zipFilePath -Force -ErrorAction SilentlyContinue
        }
    }
}