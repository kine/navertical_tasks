[CmdletBinding()]
param()

Trace-VstsEnteringInvocation $MyInvocation

try{

    function UpdateOrInstallModule
    {

        param(
            $modulename,
            $requiredversion
        )
        $ExistingModule = Get-Module $modulename -ListAvailable
        if (-not ($ExistingModule)) {
            Write-Host "Installing module $modulename $requiredversion"
            if ($requiredversion) {
                install-module -Name $modulename -Scope CurrentUser -Force -RequiredVersion $requiredversion
            } else {
                install-module -Name $modulename -Scope CurrentUser -Force
            }
        } else {
            if ($requiredversion) {
                $OnlineModule = Find-Module $modulename -RequiredVersion $requiredversion
            } else {
                $OnlineModule = Find-Module $modulename
            }
            if ($OnlineModule.Version -ne $ExistingModule[0].Version) {
                Write-Host "Newer version online exists - updating module $modulename"
                if ($requiredversion) {
                    update-module -Name $modulename -Force -RequiredVersion $requiredversion
                } else {
                    update-module -Name $modulename -Force
                }
            } else {
                Write-Host "Required version of $modulename already installed"
            }
        }
    }

    # Get inputs.
    $UninstallOldVersions = Get-VstsInput -Name 'UninstallOldVersions' -AsBool
    $NVRAppDevOpsVersion = Get-VstsInput -Name 'NVRAppDevOpsVersion' -Default ''
    $navcontainerhelperVersion = Get-VstsInput -Name 'navcontainerhelperVersion' -Default ''
    
    Write-Host "Checking and Installing needed modules"
    Install-PackageProvider nuget -force | Out-Null
    UpdateOrInstallModule -modulename 'NVRAppDevOps' -requiredversion $NVRAppDevOpsVersion
    UpdateOrInstallModule -modulename 'navcontainerhelper' -requiredversion $navcontainerhelperVersion
    
    if ($UninstallOldVersions) {
        Write-Host "Uninstalling previous versions of NVRAppDevOps"
        if ($NVRAppDevOpsVersion) {
            $Latest = Get-InstalledModule NVRAppDevOps -RequiredVersion $NVRAppDevOpsVersion
        } else {
            $Latest = Get-InstalledModule NVRAppDevOps
        }
        Get-InstalledModule NVRAppDevOps -AllVersions | Where-Object {$_.Version -ne $Latest.Version} | Uninstall-Module -Force

        Write-Host "Uninstalling previous versions of navcontainerhelper"
        if ($navcontainerhelperVersion) {
            $Latest = Get-InstalledModule navcontainerhelper -RequiredVersion $navcontainerhelperVersion
        } else {
            $Latest = Get-InstalledModule navcontainerhelper
        }
        Get-InstalledModule navcontainerhelper -AllVersions | Where-Object {$_.Version -ne $Latest.Version} | Uninstall-Module -Force
    }

} finally {
    Trace-VstsLeavingInvocation $MyInvocation
}