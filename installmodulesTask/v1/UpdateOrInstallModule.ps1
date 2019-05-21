Write-Host "Checking and Installing needed modules"
Install-PackageProvider nuget -force | Out-Null
$NVRAppDevOpsModules = Get-Module NVRAppDevOps -ListAvailable
if (-not ($NVRAppDevOpsModules)) {
    Write-Host "Installing module NVRAppDevOps"
    install-module -Name NVRAppDevOps -Scope CurrentUser -Force
} else {
    $OnlineModule = Find-Module NVRApPDevOps
    if ($OnlineModule.Version -ne $NVRAppDevOpsModules[0].Version) {
        Write-Host "Newer version online exists - updating module NVRAppDevOps"
        update-module -Name NVRAppDevOps -Force
    } else {
        Write-Host "Latest version of NVRAppDevOps already installed"
    }
}

$navcontainerhelpermodules = Get-Module navcontainerhelper -ListAvailable
if (-not $navcontainerhelpermodules) {
    Write-Host "Installing module navcontainerhelper"
    install-module -Name navcontainerhelper -Scope CurrentUser -Force
} else {
    $OnlineModule = Find-Module navcontainerhelper
    if ($OnlineModule.Version -ne $navcontainerhelpermodules[0].Version) {
        Write-Host "Newer version online exists - updating module navcontainerhelper"
        update-module -Name navcontainerhelper -Force
    } else {
        Write-Host "Latest version of navcontainerhelper already installed"
    }
}

