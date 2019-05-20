[CmdletBinding()]
param()

Trace-VstsEnteringInvocation $MyInvocation

try{
    # Get inputs.
    $tenant = Get-VstsInput -Name 'tenant' -Require
    $environment = Get-VstsInput -Name 'environment' -Default ''
    $apiversion = Get-VstsInput -Name 'apiversion' -Default 'v2.0'
    $automationapiversion = Get-VstsInput -Name 'automationapiversion' -Default 'beta'
    $appfile = Get-VstsInput -Name 'appfile' -Default '*.app'
    $appid = Get-VstsInput -Name 'appid' -Require
    $appsecret = Get-VstsInput -Name 'appsecret' -Require
    $username = Get-VstsInput -Name 'username' -Require
    $userpwd = Get-VstsInput -Name 'userpwd' -Require
    $appfileexclude = Get-VstsInput -Name 'appfileexclude' -Default ''
    
    Write-Host "Importing module NVRAppDevOps"
    Import-Module NVRAppDevOps -DisableNameChecking

    $files = Get-ChildItem -Path $appfile -Recurse -Exclude $appfileexclude
    $cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $username,(ConvertTo-SecureString -String $userpwd -AsPlainText -Force)
    $apiuri = "api/microsoft/automation/$automationapiversion"
    foreach($file in $files) {
        Write-Host "Publishing file $($file.FullName)"
        Upload-PerTenantApp -AppId $appid `
                            -AppSecret $appsecret `
                            -Credentials $cred `
                            -Tenant $tenant `
                            -APIUri $apiuri `
                            -AppPath $file.FullName `
                            -Environment $environment `
                            -APIVersion $apiversion
    }

} finally {
    Trace-VstsLeavingInvocation $MyInvocation
}