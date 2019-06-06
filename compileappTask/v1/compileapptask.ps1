[CmdletBinding()]
param()

Trace-VstsEnteringInvocation $MyInvocation

try{
    # Get inputs.
    $containername = Get-VstsInput -Name 'containername' -Require
    $repopath = Get-VstsInput -Name 'repopath' -Default ''
    $enablecop = Get-VstsInput -Name 'enablecop' -AsBool
    $failon = Get-VstsInput -Name 'failon' -Default 'error'
    $password = Get-VstsInput -Name 'password' -Default ''
    $username = Get-VstsInput -Name 'username' -Default ''
    $appdownloadscript = Get-VstsInput -Name 'appdownloadscript' -Default ''
    $auth = Get-VstsInput -Name 'auth' -Require

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