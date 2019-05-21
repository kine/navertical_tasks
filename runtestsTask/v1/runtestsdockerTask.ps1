[CmdletBinding()]
param()

Trace-VstsEnteringInvocation $MyInvocation

try{
    # Get inputs.
    $containername = Get-VstsInput -Name 'containername' -Require
    $testfile = Get-VstsInput -Name 'testfile' -Require
    $testsuite = Get-VstsInput -Name 'testsuite' -Default "DEFAULT"
    $tenant  = Get-VstsInput -Name 'tenant' -Default "default"
    $resultonerror  = Get-VstsInput -Name 'resultonerror' -Default "error"
    $auth  = Get-VstsInput -Name 'auth' -Default "Windows"
    $username  = Get-VstsInput -Name 'username' -Default $env:USERNAME
    $password  = Get-VstsInput -Name 'password' -Default ""

    Write-Host "Importing module NVRAppDevOps"
    Import-Module NVRAppDevOps -DisableNameChecking

    $FullPath = [System.IO.Path]::GetFullPath($testfile)
    Run-ALTestInContainer -ContainerName $containername -detailed -AzureDevOps $resultonerror -XUnitResultFileName "$FullPath" -testSuite $testsuite -Auth $auth -Username $username -Password $password -tenant $tenant

} finally {
    Trace-VstsLeavingInvocation $MyInvocation
}