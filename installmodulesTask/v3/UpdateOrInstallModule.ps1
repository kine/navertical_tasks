[CmdletBinding()]
param()

Trace-VstsEnteringInvocation $MyInvocation

try{

    function UpdateOrInstallModule
    {

        param(
            $modulename,
            $requiredversion,
            $allowPreRelease
        )
        $ExistingModule = Get-Module $modulename -ListAvailable
        if (-not ($ExistingModule)) {
            Write-Host "Installing module $modulename $requiredversion"
            if ($requiredversion) {
                install-module -Name $modulename -Scope CurrentUser -Force -RequiredVersion $requiredversion -AllowPrerelease:$allowPreRelease
            } else {
                install-module -Name $modulename -Scope CurrentUser -Force -AllowPrerelease:$allowPreRelease
            }
        } else {
            if ($requiredversion) {
                $OnlineModule = Find-Module $modulename -RequiredVersion $requiredversion -AllowPrerelease:$allowPreRelease
            } else {
                $OnlineModule = Find-Module $modulename -AllowPrerelease:$allowPreRelease
            }
            if ($OnlineModule.Version -ne $ExistingModule[0].Version) {
                Write-Host "Newer version online exists - updating module $modulename"
                if ($requiredversion) {
                    update-module -Name $modulename -Force -RequiredVersion $requiredversion -AllowPrerelease:$allowPreRelease
                } else {
                    update-module -Name $modulename -Force -AllowPrerelease:$allowPreRelease
                }
            } else {
                Write-Host "Required version of $modulename already installed"
            }
        }
    }

    # Get inputs.
    $UninstallOldVersions = Get-VstsInput -Name 'UninstallOldVersions' -AsBool
    $AllowPreRelease = Get-VstsInput -Name 'allowPreRelease' -AsBool
    $NVRAppDevOpsVersion = Get-VstsInput -Name 'NVRAppDevOpsVersion' -Default ''
    $bccontainerhelperVersion = Get-VstsInput -Name 'bccontainerhelperVersion' -Default ''
    
    Write-Host "Checking and Installing needed modules"
    Install-PackageProvider nuget -force | Out-Null
    UpdateOrInstallModule -modulename 'NVRAppDevOps' -requiredversion $NVRAppDevOpsVersion -allowPreRelease $AllowPreRelease
    UpdateOrInstallModule -modulename 'bccontainerhelper' -requiredversion $bccontainerhelperVersion -allowPreRelease $AllowPreRelease
    
    if ($UninstallOldVersions) {
        Write-Host "Uninstalling previous versions of NVRAppDevOps"
        if ($NVRAppDevOpsVersion) {
            $Latest = Get-InstalledModule NVRAppDevOps -RequiredVersion $NVRAppDevOpsVersion
        } else {
            $Latest = Get-InstalledModule NVRAppDevOps
        }
        Get-InstalledModule NVRAppDevOps -AllVersions | Where-Object {$_.Version -ne $Latest.Version} | Uninstall-Module -Force

        Write-Host "Uninstalling previous versions of bccontainerhelper"
        if ($bccontainerhelperVersion) {
            $Latest = Get-InstalledModule bccontainerhelper -RequiredVersion $bccontainerhelperVersion
        } else {
            $Latest = Get-InstalledModule bccontainerhelper
        }
        Get-InstalledModule bccontainerhelper -AllVersions | Where-Object {$_.Version -ne $Latest.Version} | Uninstall-Module -Force
    }

} finally {
    Trace-VstsLeavingInvocation $MyInvocation
}