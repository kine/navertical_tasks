[CmdletBinding()]
param()

Trace-VstsEnteringInvocation $MyInvocation

try{
    # Get inputs.
    $containername = Get-VstsInput -Name 'ContainerName' -Require
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
                          -AppDownloadScript $appdownloadscript `
                          -EnableAppSourceCop $enableAppSourcecop `
                          -EnablePerTenantExtensionCop $enablePerTenantExtensioncop `
                          -EnableUICop $enableUIcop `
                          -RulesetFile $rulesetFile `
                          -AsmProbingPaths $asmProbingPaths



} finally {
    Trace-VstsLeavingInvocation $MyInvocation
}