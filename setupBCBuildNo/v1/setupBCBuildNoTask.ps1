[CmdletBinding()]
param()

Trace-VstsEnteringInvocation $MyInvocation

try{
    # Get inputs.
    $SourceFolder = Get-VstsInput -Name 'SourceFolder' -Require
    $Contents = Get-VstsInput -Name 'Contents' -Default ''
    $BuildID = Get-VstsInput -Name 'BuildID' -Default $env:BUILD_BUILDID
    $UpdateAzureDevOpsBuildNo = Get-VstsInput -Name 'UpdateAzureDevOpsBuildNo' -AsBool

    Write-Host "Importing module NVRAppDevOps"
    Import-Module NVRAppDevOps -DisableNameChecking

    $version = Set-ALAppBuildNo -RepoPath $SourceFolder -UpdateDevOpsBuildNo:$UpdateAzureDevOpsBuildNo -Filters $Contents -BuildNo $BuildID
    #Write-Output "##vso[task.setvariable variable=Version;isSecret=false;isOutput=true;]$version"

    Write-Host "Setting variable Version to value $version"
    Set-VstsTaskVariable -Name Version -Value $version

} finally {
    Trace-VstsLeavingInvocation $MyInvocation
}