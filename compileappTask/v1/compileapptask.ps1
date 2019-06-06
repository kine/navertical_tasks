[CmdletBinding()]
param()

Trace-VstsEnteringInvocation $MyInvocation

try{
    # Get inputs.
    $containername = Get-VstsInput -Name 'ContainerName' -Require
    $repopath = Get-VstsInput -Name 'RepoPath' -Default ''
    $enablecop = Get-VstsInput -Name 'EnableCop' -AsBool
    $failon = Get-VstsInput -Name 'FailOn' -Default 'error'
    $password = Get-VstsInput -Name 'Password' -Default ''
    $username = Get-VstsInput -Name 'Username' -Default ''
    $appdownloadscript = Get-VstsInput -Name 'AppDownloadScript' -Default ''
    $auth = Get-VstsInput -Name 'Auth' -Require

    Write-Host "Importing module NVRAppDevOps"
    Import-Module NVRAppDevOps -DisableNameChecking

    $orderedapps = Get-ALAppOrder -ContainerName $containername -Path $repopath
    Write-Host "Compiling the apps"
    Compile-ALProjectTree -OrderedApps $orderedapps `
                          -PackagesPath $repopath `
                          -ContainerName $containername `
                          -EnableCodeCop $enablecop `
                          -FailOn $failon `
                          -Auth $auth `
                          -Username $username `
                          -Password $password `
                          -AppDownloadScript $appdownloadscript



} finally {
    Trace-VstsLeavingInvocation $MyInvocation
}