[CmdletBinding()]
param()

Trace-VstsEnteringInvocation $MyInvocation

try{
    # Get inputs.
    $containername = Get-VstsInput -Name 'containername' -Require

    Write-Host "Importing module NVRAppDevOps"
    Import-Module NVRAppDevOps -DisableNameChecking

    Write-Host "Removing container $containername"
    Remove-ALEnvironment -ContainerName $containername
        
} finally {
    Trace-VstsLeavingInvocation $MyInvocation
}