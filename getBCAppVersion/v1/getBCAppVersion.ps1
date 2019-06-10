[CmdletBinding()]
param()

Trace-VstsEnteringInvocation $MyInvocation

try{
    # Get inputs.
    $SourceFolder = Get-VstsInput -Name 'SourceFolder' -Require
    $ContainerName = Get-VstsInput -Name 'ContainerName' -Require

    Write-Host "Importing module NVRAppDevOps"
    Import-Module NVRAppDevOps -DisableNameChecking

    $FileName = Get-ChildItem -Path $SourceFolder | Select-Object -First 1
    if (Get-NavContainerPath -containerName $ContainerName -path $FileName) {
        Write-Host 'Getting app version'
        $AppInfo = Get-NavContainerAppInfoFile -ContainerName $ContainerName -AppPath $FileName
    } else {
        # Create fast container to be able to get the al app order
        $PWord = ConvertTo-SecureString -String 'Pass@word1' -AsPlainText -Force
        $User = $env:USERNAME
        $cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User,$PWord
        $InternalContainerName = 'BCPS'
        try {
            $RepoPath = $SourceFolder
            $RepoPath = Split-Path -Path $RepoPath -Resolve
            Write-Host "Creating internal container with $RepoPath shared"
            New-NavContainer -accept_eula `
                -accept_outdated `
                -containerName $InternalContainerName `
                -imageName (Get-NavContainerImageName -containerName $ContainerName) `
                -doNotExportObjectsToText `
                -alwaysPull `
                -shortcuts "None" `
                -auth 'Windows' `
                -Credential $cred `
                -memoryLimit '4GB' `
                -updateHosts `
                -useBestContainerOS `
                -additionalParameters @("--volume ""$($RepoPath):c:\app""") `
                -myScripts  @(@{"navstart.ps1" = "Write-Host 'Ready for connections!'";"checkhealth.ps1" = "exit 0"})
    
            Write-Host 'Getting app version'
            $AppInfo = Get-NavContainerAppInfoFile -ContainerName BCPS -AppPath $FileName
                    
        } finally  {
            Write-Host 'Remove internal container'
            Remove-NavContainer -containerName $InternalContainerName
        }
        #Write-Output "##vso[task.setvariable variable=Version;isSecret=false;isOutput=true;]$version"
    }

    Write-Host "Setting variable Version to value $($AppInfo.Version)"
    Set-VstsTaskVariable -Name Version -Value $($AppInfo.Version)
    $VersionShort = "$($AppInfo.Version.Major).$($AppInfo.Version.Minor).$($AppInfo.Version.Build)"
    Write-Host "Setting variable VersionShort to value $VersionShort"
    Set-VstsTaskVariable -Name VersionShort -Value $VersionShort

} finally {
    Trace-VstsLeavingInvocation $MyInvocation
}