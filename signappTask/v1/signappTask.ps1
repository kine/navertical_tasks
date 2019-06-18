[CmdletBinding()]
param()

Trace-VstsEnteringInvocation $MyInvocation

try{
    # Get inputs.
    $containername = Get-VstsInput -Name 'containername' -Require
    $appfile = Get-VstsInput -Name 'appfile' -Default '*.app'
    $appfileexclude = Get-VstsInput -Name 'appfileexclude' -Default ''
    $pfxpassword = Get-VstsInput -Name 'pfxpassword' -Default ''
    $certfile = Get-VstsInput -Name 'certfile' -Require
    
    Write-Host "Importing module NVRAppDevOps"
    Import-Module NVRAppDevOps -DisableNameChecking

    if (-not $pfxpassword) {
        Write-Host "Getting pfxpassword from environment $($env:SECRET_CERTPASSWORD)"
        $pfxpassword = $env:SECRET_CERTPASSWORD
    }
    $apps = Get-ChildItem $appfile -Recurse -Filter *.app -Exclude $appfileexclude 
    foreach ($app in $apps) {
        Write-Host "Signing $($app.FullName)"
        if ($pfxpassword -ne '') {
            Write-Host "Password entered, using it"
            $pfxpwd = (ConvertTo-SecureString -String $pfxpassword -AsPlainText -Force)            
            Sign-NAVContainerApp -containerName $containername -appFile $app.FullName -pfxFile $certfile -pfxPassword $pfxpwd
        } else {
            Write-Host "No password entered"
            Sign-NAVContainerApp -containerName $containername -appFile $app.FullName -pfxFile $certfile
        }
    }

} finally {
    Trace-VstsLeavingInvocation $MyInvocation
}