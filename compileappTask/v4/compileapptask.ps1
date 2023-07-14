[CmdletBinding()]
param()

Trace-VstsEnteringInvocation $MyInvocation

try {
    # Get inputs.
    $containername = Get-VstsInput -Name 'ContainerName' -Default ''
    $artifactUrl = Get-VstsInput -Name 'ArtifactUrl' -Default ''
    $enablecop = Get-VstsInput -Name 'EnableCop' -AsBool
    $repopath = Get-VstsInput -Name 'RepoPath' -Default ''
    $enablecop = Get-VstsInput -Name 'EnableCop' -AsBool
    $enableAppSourcecop = Get-VstsInput -Name 'EnableAppsourceCop' -AsBool
    $enablePerTenantExtensioncop = Get-VstsInput -Name 'EnablePerTenantExtensionCop' -AsBool
    $enableUIcop = Get-VstsInput -Name 'EnableUICop' -AsBool
    $failon = Get-VstsInput -Name 'FailOn' -Default 'error'
    $password = Get-VstsInput -Name 'Password' -Default ''
    $username = Get-VstsInput -Name 'Username' -Default ''
    $appdownloadscript = Get-VstsInput -Name 'AppDownloadScript' -Default ''
    $auth = Get-VstsInput -Name 'Auth' -Require
    $rulesetFile = Get-VstsInput -Name 'RulesetFile' -Default ''
    $asmProbingPaths = Get-VstsInput -Name 'AsmProbingPaths' -Default ''
    $usePaket = Get-VstsInput -Name 'UsePaket' -AsBool

    $sourceRepositoryUrl = $env:BUILD_REPOSITORY_URI
    $sourceCommit = $env:BUILD_SOURCEVERSION
    $buildBy = 'naverticaltasks'
    $buildUrl = "https://dev.azure.com/$($env:SYSTEM_TEAMFOUNDATIONCOLLECTIONURI)$($env:SYSTEM_TEAMPROJECT)/_build/results?buildId=$($env:BUILD_BUILDID)"

    if ((-not $containername) -and (-not $artifactUrl)) {
        Write-Error "ContainerName or ArtifactUrl must be filled in!"
    }

    Write-Host "Importing module NVRAppDevOps"
    Import-Module NVRAppDevOps -DisableNameChecking
    $NVRAppDevOpsVersion = (get-module NVRAppDevOps).Version

    if ($containername) {
        $orderedapps = Get-ALAppOrder -ContainerName $containername -Path $repopath
        Write-Host "Compiling the apps in container"
        Compile-ALProjectTree -OrderedApps $orderedapps `
            -PackagesPath $repopath `
            -ContainerName $containername `
            -EnableCodeCop $enablecop `
            -FailOn $failon `
            -Auth $auth `
            -Username $username `
            -Password $password `
            -AppDownloadScript $appdownloadscript `
            -EnableAppSourceCop $enableAppSourcecop `
            -EnablePerTenantExtensionCop $enablePerTenantExtensioncop `
            -EnableUICop $enableUIcop `
            -RulesetFile $rulesetFile `
            -AsmProbingPaths $asmProbingPaths
    }
    else {
        if ($NVRAppDevOpsVersion -ge [version]'2.3.0') {
            Write-Host "Detected NVRAppDevOps newer or equal to v2.3.0, using additional params for alc.exe"
            $AdditionalParams = @{
                SourceRepositoryUrl = $sourceRepositoryUrl
                SourceCommit        = $sourceCommit
                BuildBy             = $buildBy
                BuildUrl            = $buildUrl
            }
            Write-Host "$($AdditionalParams | convertto-json)"
        }
        else {
            $AdditionalParams = @{}
        }
        $orderedapps = Get-ALAppOrder -ArtifactUrl $artifactUrl -Path $repopath
        Write-Host "Compiling the apps without container"
        Compile-ALProjectTree -OrderedApps $orderedapps `
            -PackagesPath $repopath `
            -ArtifactUrl $artifactUrl `
            -EnableCodeCop $enablecop `
            -FailOn $failon `
            -AppDownloadScript $appdownloadscript `
            -EnableAppSourceCop $enableAppSourcecop `
            -EnablePerTenantExtensionCop $enablePerTenantExtensioncop `
            -EnableUICop $enableUIcop `
            -RulesetFile $rulesetFile `
            -AsmProbingPaths $asmProbingPaths `
            -UsePaket $usePaket `
            @AdditionalParams

    }



}
finally {
    Trace-VstsLeavingInvocation $MyInvocation
}