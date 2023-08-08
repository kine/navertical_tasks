[CmdletBinding()]
param()

function Get-NavSipFromArtifacts
(
    [string] $TargetPath
) {
    $artifactTempFolder = Join-Path $([System.IO.Path]::GetTempPath()) ([System.IO.Path]::GetRandomFileName())

    try {
        Write-Host "Downloading core atifact for getting navsip.dll"
        Download-Artifacts -artifactUrl (Get-BCArtifactUrl -type Sandbox -country core) -basePath $artifactTempFolder | Out-Null
        Write-Host "Downloaded artifacts to $artifactTempFolder"
        $navsip = Get-ChildItem -Path $artifactTempFolder -Filter "navsip.dll" -Recurse
        Write-Host "Found navsip at $($navsip.FullName)"
        Copy-Item -Path $navsip.FullName -Destination $TargetPath -Force | Out-Null
        Write-Host "Copied navsip to $TargetPath"
    }
    finally {
        Remove-Item -Path $artifactTempFolder -Recurse -Force
    }
}

function Register-NavSip() {
    $msvcr120Path = "C:\Windows\System32\msvcr120.dll"
    if (!(Test-Path $msvcr120Path)) {
        Write-Host 'vcredist_x64.exe (Visual C++ Redistributable Packages for Visual Studio 2013) not installed (needed for navsip.dll)! Downloading and installing from https://www.microsoft.com/en-us/download/details.aspx?id=40784'
        $VCRedistFile = Join-Path $env:TEMP "vcredist_x64.exe"
        Write-Host "Downloading vcredist_x64.exe"
        Invoke-WebRequest 'https://download.microsoft.com/download/0/5/6/056DCDA9-D667-4E27-8001-8A0C6971D6B1/vcredist_x64.exe' -OutFile $VCRedistFile
        Start-Process -FilePath $VCRedistFile -ArgumentList '/install', '/passive', '/norestart', '/quiet' -Wait
        Write-Host "Installation of vcredist_x64.exe complete"
    }
    $TargetPath = "C:\Windows\System32"
    $navSipDllPath = Join-Path $TargetPath "navsip.dll"
    try {
        if (-not (Test-Path $navSipDllPath)) {
            Get-NavSipFromArtifacts -TargetPath $navSipDllPath
        }

        Write-Host "Unregistering dll $navSipDllPath"
        RegSvr32 /u /s $navSipDllPath
        Start-sleep -s 1
        Write-Host "Registering dll $navSipDllPath"
        RegSvr32 /s $navSipDllPath
    }
    catch {
        Write-Host "Failed to copy navsip to $TargetPath"
    }

}

Trace-VstsEnteringInvocation $MyInvocation

try {
    # Get inputs.
    $containername = Get-VstsInput -Name 'containername' -Default ''
    $appfile = Get-VstsInput -Name 'appfile' -Default '*.app'
    $appfileexclude = Get-VstsInput -Name 'appfileexclude' -Default ''
    $pfxpassword = Get-VstsInput -Name 'pfxpassword' -Default ''
    $certfile = Get-VstsInput -Name 'certfile' -Default ''
    $useazurekeyvault = Get-VstsInput -Name 'useazurekeyvault' -AsBool
    $skiptoolinstall = Get-VstsInput -Name 'skiptoolinstall' -AsBool
    $keyvaultname = Get-VstsInput -Name 'keyvaultname' -Default ''
    $keyvaultcertificatename = Get-VstsInput -Name 'keyvaultcertificatename' -Default ''
    $clientid = Get-VstsInput -Name 'clientid' -Default ''
    $clientsecret = Get-VstsInput -Name 'clientsecret' -Default ''
    $tenantid = Get-VstsInput -Name 'tenantid' -Default ''
    $filedigest = Get-VstsInput -Name 'filedigest' -Default "sha256"
    $timestampservice = Get-VstsInput -Name 'timestampservice' -Default "http://timestamp.digicert.com"
    $timestampdigest = Get-VstsInput -Name 'timestampdigest' -Default "sha256"
    $accesstoken = Get-VstsInput -Name 'accesstoken' -Default ''

    $apps = Get-ChildItem $appfile -Recurse -Filter *.app -Exclude $appfileexclude 

    if ($useazurekeyvault) {
        Write-Host "Using KeyVault $($keyvaultname) for signing the files"
        if (-not $skiptoolinstall) {
            Write-Host "Installing dotnet tool"
            $ScriptPath = Join-Path $env:TEMP "install-dotnet.ps1"
            Invoke-WebRequest 'https://dot.net/v1/dotnet-install.ps1' -OutFile $ScriptPath
            .$ScriptPath
            Write-Host "Installation of dotnet tool complete"
        }
        if (-not (dotnet tool list --global | Where-Object { $_ -like '*azuresigntool*' })) {
            Write-Host "Installing AzureSignTool"
            dotnet tool install --global AzureSignTool --version 4.0.1
            Write-Host "Installation complete"
        }
        if ($env:Path -notlike "*.dotnet\tools*") {
            $env:Path += ";%USERPROFILE%\.dotnet\tools"
            Write-Host "Adding %USERPROFILE%\.dotnet\tools to Path environment variable"
        }
        else {
            Write-Host ".dotnet\tools already in Path environment variable"
        }
        

        Write-Host "Signing these files:"
        $apps | ForEach-Object { Write-Host $_.FullName }

        Write-Host "Register NavSip from artifact"
        Register-NavSip

        if ($accesstoken) {
            Write-Host "Using access token"
            AzureSignTool sign --file-digest $FileDigest `
                --azure-key-vault-url "https://$keyvaultname.vault.azure.net/" `
                --azure-key-vault-accesstoken $accesstoken `
                --azure-key-vault-certificate $keyvaultcertificatename `
                --timestamp-rfc3161 "$timestampservice" `
                --timestamp-digest $timestampdigest `
                $apps

        }
        else {
            Write-Host "Using AAD app to authenticate"
            AzureSignTool sign --file-digest $FileDigest `
                --azure-key-vault-url "https://$keyvaultname.vault.azure.net/" `
                --azure-key-vault-client-id $clientid `
                --azure-key-vault-tenant-id $tenantid `
                --azure-key-vault-client-secret $clientsecret `
                --azure-key-vault-certificate $keyvaultcertificatename `
                --timestamp-rfc3161 "$timestampservice" `
                --timestamp-digest $timestampdigest `
                $apps
        }

    }
    else {
        Write-Host "Importing module NVRAppDevOps"
        Import-Module NVRAppDevOps -DisableNameChecking
        
        if (-not $pfxpassword) {
            Write-Host "Getting pfxpassword from environment $($env:SECRET_CERTPASSWORD)"
            $pfxpassword = $env:SECRET_CERTPASSWORD
        }
        foreach ($app in $apps) {
            Write-Host "Signing $($app.FullName)"
            if ($pfxpassword -ne '') {
                Write-Host "Password entered, using it"
                $pfxpwd = (ConvertTo-SecureString -String $pfxpassword -AsPlainText -Force)            
                Sign-NAVContainerApp -containerName $containername -appFile $app.FullName -pfxFile $certfile -pfxPassword $pfxpwd
            }
            else {
                Write-Host "No password entered"
                Sign-NAVContainerApp -containerName $containername -appFile $app.FullName -pfxFile $certfile
            }
        }
    }
   
}
finally {
    Trace-VstsLeavingInvocation $MyInvocation
}