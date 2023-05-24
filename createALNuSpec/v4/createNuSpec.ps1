[CmdletBinding()]
param()

Trace-VstsEnteringInvocation $MyInvocation
function FixBaseAppDep
{
    param(
        $AppInfo,
        $BaseAppVersion
    )
    if (-not ($AppInfo.Dependencies |Where-Object {$_.Name -eq 'Application'})) {
        $Dep = $AppInfo.Dependencies
        $BaseAppInfo = new-object PSObject -property @{AppId = 'c1335042-3002-4257-bf8a-75c898ccb1b8';
            Name = "Application";
            Publisher = "Microsoft";
            MinVersion = $BaseAppVersion;
            CompatibilityId = '0.0.0.0';
            IsPropagated = $true;
            Version = $BaseAppVersion}
        $Dep += $BaseAppInfo
        return $Dep
    } else {
        return $AppInfo.Dependencies;
    }
}
try {
    # Get inputs.
    $ContainerName = Get-VstsInput -Name 'ContainerName' -Default ''
    $ArtifactUrl = Get-VstsInput -Name 'ArtifactUrl' -Default ''
    $AppFile = Get-VstsInput -Name 'AppFile' -Default '*.app'
    $AppFileExclude = Get-VstsInput -Name 'AppFileExclude' -Default ''
    $NuspecFileName = Get-VstsInput -Name 'NuspecFileName' -Require
    $Authors = Get-VstsInput -Name 'Authors' -Default ''
    $Owners = Get-VstsInput -Name 'Owners' -Default ''
    $LicenseUrl = Get-VstsInput -Name 'LicenseUrl' -Default ''
    $ProjectUrl = Get-VstsInput -Name 'ProjectUrl' -Default ''
    $IconURL = Get-VstsInput -Name 'IconURL' -Default ''
    $ReleaseNotes = Get-VstsInput -Name 'ReleaseNotes' -Default ''
    $Description = Get-VstsInput -Name 'Description' -Default ''
    $Copyright = Get-VstsInput -Name 'Copyright' -Default ''
    $Tags = Get-VstsInput -Name 'Tags' -Default ''
    $IncludeBaseApp = Get-VstsInput -Name 'IncludeBaseApp' -AsBool
    $BaseAppVersion = Get-VstsInput -Name 'BaseAppVersion' -Default ''

    set-location $env:SYSTEM_DEFAULTWORKINGDIRECTORY

    Write-Host "Importing module NVRAppDevOps"
    Import-Module NVRAppDevOps -DisableNameChecking

    $OneAppFile = Get-ChildItem -Path $AppFile -Exclude $AppFileExclude | Select-Object -First 1

    if ($ContainerName) {
        if (Get-NavContainerPath -containerName $ContainerName -path $OneAppFile) {
            $AppInfo = Get-NavContainerAppInfoFile -ContainerName $ContainerName -AppPath $OneAppFile
        }
        else {
            # Create fast container to be able to get the al app order
            $RepoPath = Split-Path -Path $OneAppFile -Resolve
            $PWord = ConvertTo-SecureString -String 'Pass@word1' -AsPlainText -Force
            $User = $env:USERNAME
            $cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $PWord
            $InternalContainerName = 'BCPS'
            try {
                $RepoPath = $SourceFolder
                $RepoPath = Split-Path -Path $RepoPath -Resolve
                Write-Host "Creating internal container with $RepoPath shared"
                New-NavContainer -accept_eula `
                    -accept_outdated `
                    -containerName $InternalContainerName `
                    -artifactUrl (Get-BCContainerArtifactUrl -containerName $ContainerName) `
                    -doNotExportObjectsToText `
                    -alwaysPull `
                    -shortcuts "None" `
                    -auth 'Windows' `
                    -Credential $cred `
                    -memoryLimit '4GB' `
                    -updateHosts `
                    -useBestContainerOS `
                    -additionalParameters @("--volume ""$($RepoPath):c:\app""") `
                    -myScripts  @(@{"navstart.ps1" = "Write-Host 'Ready for connections!'"; "checkhealth.ps1" = "exit 0" })
                
                Write-Host 'Getting app version'
                $AppInfo = Get-NavContainerAppInfoFile -ContainerName 'BCPS' -AppPath $OneAppFile
            }
            finally {
                Write-Host 'Remove internal container'
                Remove-NavContainer -containerName $InternalContainerName
            }
        }
    }
    else {
        import-module (Get-BCModulePathFromArtifact -artifactPath ((Download-Artifacts -artifactUrl $ArtifactUrl -includePlatform)[1]))
        $AppInfo = get-navappinfo -Path $OneAppFile
    }
    if (-not $Description) {
        $Description = $AppInfo.Description
    }
    $Dependencies = FixBaseAppDep -AppInfo $AppInfo -BaseAppVersion $BaseAppVersion
    Write-Host "Dependencies in the app: $($Dependencies | ConvertTo-Json -Depth 100)"

    $AppVersion = "$($AppInfo.Version.Major).$($AppInfo.Version.Minor).$($AppInfo.Version.Build).$($AppInfo.Version.Revision)"
    Write-Host "Creating NuSpec file for $OneAppFile"
    $id = "$($AppInfo.publisher)_$($AppInfo.name)"
    Write-Verbose @"
    New-ALNuSpec -AppFile $OneAppFile `
        -AppName $($AppInfo.Name) `
        -Publisher $($AppInfo.Publisher) `
        -AppVersion $AppVersion `
        -NuspecFileName $NuspecFileName `
        -id $Id `
        -authors $Authors `
        -owners $Owners `
        -licenseUrl $LicenseUrl `
        -projectUrl $ProjectUrl `
        -iconUrl $IconURL `
        -releaseNotes $ReleaseNotes `
        -description $Description `
        -copyright $Copyright `
        -tags $Tags `
        -AppDependencies $Dependencies `
        -IdPrefix '' `
        -IncludeBaseApp $IncludeBaseApp
"@
    New-ALNuSpec -AppFile $OneAppFile `
        -AppName $AppInfo.Name `
        -Publisher $AppInfo.Publisher `
        -AppVersion $AppVersion `
        -NuspecFileName $NuspecFileName `
        -id $Id `
        -authors $Authors `
        -owners $Owners `
        -licenseUrl $LicenseUrl `
        -projectUrl $ProjectUrl `
        -iconUrl $IconURL `
        -releaseNotes $ReleaseNotes `
        -description $Description `
        -copyright $Copyright `
        -tags $Tags `
        -AppDependencies $Dependencies `
        -IdPrefix '' `
        -IncludeBaseApp $IncludeBaseApp

}
finally {
    Trace-VstsLeavingInvocation $MyInvocation
}