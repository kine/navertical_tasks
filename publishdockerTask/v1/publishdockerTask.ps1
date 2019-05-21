[CmdletBinding()]
param()

Trace-VstsEnteringInvocation $MyInvocation

try{
    # Get inputs.
    $containername = Get-VstsInput -Name 'containername' -Require
    $appfile = Get-VstsInput -Name 'appfile' -Default '*.app'
    $appfileexclude = Get-VstsInput -Name 'appfileexclude' -Default ''
    $appname = Get-VstsInput -Name 'appname' -Require
    $skipverify = Get-VstsInput -Name 'skipverify' -AsBool -Default $false

    Write-Host "Importing module NVRAppDevOps"
    Import-Module NVRAppDevOps -DisableNameChecking

    $dockerapp = Get-NavContainerAppInfo -containerName $containername  -tenantSpecificProperties | where-object {$_.Name -eq $appname}
    $app = Get-ChildItem $appfile -Recurse -Filter *.app -Exclude $appfileexclude | Select-Object -Last 1
    $install = -not $dockerapp
    if ($install) {
        Write-Host "App not exists on server, will install by default"
    } else {
        Write-Host "Another version exists on server, will do upgrade"
    }
    Publish-NavContainerApp -containerName $containername -appFile $app.FullName -SkipVerification:$skipverify -sync -install:$install

    if ($dockerapp) {
        $dockerapp = Get-NavContainerAppInfo -containerName $containername -tenantSpecificProperties | where-object {$_.Name -eq $appname}
        if ($dockerapp.Count -gt 1) {
            foreach($app in $dockerapp) {
                if ($app.IsInstalled) {
                    $previousVersion = $app
                }
                if ($appfile.FullName.Contains($app.Version)) {
                    Write-Host "Upgrading from ${$previousVersion.Version} to ${$app.Version}"
                    Start-NavContainerAppDataUpgrade -containerName $containername -appName $appname -appVersion $app.Version
                    $newInstalledApp = $app
                }
            }

            foreach($app in $dockerapp) {
                if ($app.Version -ne $newInstalledApp.Version) {
                    Write-Host "Unpublishing version $($app.Version)"
                    Unpublish-NavContainerApp -containerName $containername -appName $appname -version $app.Version
                }
            }
        }
    }

} finally {
    Trace-VstsLeavingInvocation $MyInvocation
}