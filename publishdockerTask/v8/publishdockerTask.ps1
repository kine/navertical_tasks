[CmdletBinding()]
param()

Trace-VstsEnteringInvocation $MyInvocation

try {
    # Get inputs.
    $ContainerName = Get-VstsInput -Name 'ContainerName' -Require
    $HostName = Get-VstsInput -Name 'HostName' -Default ''
    #$Contents = Get-VstsInput -Name 'Contents' -Default '*.app'
    $SourceFolder = Get-VstsInput -Name 'SourceFolder' -Default $env:SYSTEM_DEFAULTWORKINGDIRECTORY
    #$AppFileExclude = Get-VstsInput -Name 'AppFileExclude' -Default ''
    $Tenant = Get-VstsInput -Name 'Tenant' -Default 'default'
    $SyncMode = Get-VstsInput -Name 'SyncMode' -Default 'Add'
    $Scope = Get-VstsInput -Name 'Scope' -Default 'Tenant'
    $SkipVerify = Get-VstsInput -Name 'SkipVerify' -AsBool -Default $false
    $Recurse = Get-VstsInput -Name 'Recurse' -AsBool -Default $false
    $UseDevEndpoint = Get-VstsInput -Name 'UseDevEndpoint' -AsBool -Default $false
    $AppDownloadScript = Get-VstsInput -Name 'AppDownloadScript' -Default ''
    $IncludeAppFiles = Get-VstsInput -Name 'IncludeAppFiles' -AsBool -Default $false

    Write-Host "Importing module NVRAppDevOps"
    Import-Module NVRAppDevOps -DisableNameChecking

    if (-not $HostName) {
        $HostName = '.'
    }

    $pssession = New-PSSession -ComputerName $HostName
    # Create fast container to be able to get the al app order
    $PWord = ConvertTo-SecureString -String 'Pass@word1' -AsPlainText -Force
    $User = $env:USERNAME
    $cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User,$PWord
    try {

        if (($HostName -eq '.') -and (Get-NavContainerPath -containerName $ContainerName -path $SourceFolder)) {
            $ArtifactUrl = Get-BCContainerArtifactUrl $ContainerName
        } else {
            $Code = {
                param(
                    $ContainerName
                )
                
                Get-BCContainerArtifactUrl $ContainerName
            }
            Write-Host "Getting artifactUrl from $ContainerName on host $HostName"
            $ArtifactUrl = Invoke-Command -Session $pssession -ScriptBlock $Code -ArgumentList $ContainerName
            if (-not $ArtifactUrl) {
                Write-Host "Container isn't using artifacts (old container?). Defaulting to latest stable version of OnPrem w1"
                $ArtifactUrl = Get-BCArtifactUrl -type OnPrem -country w1 -select Latest
            }
            Write-Host "Artifact URL used: $ArtifactUrl"
        }
        Write-Host "Getting app dependencies and order"
        Write-Host "Get-ALAppOrder -ArtifactUrl $ArtifactUrl -Path $SourceFolder -Recurse:$Recurse"
        $AppOrder = Get-ALAppOrder -ArtifactUrl $ArtifactUrl -Path $SourceFolder -Recurse:$Recurse

        Write-Host "Checking availability of dependencies ($($AppOrder.Count))..."
        foreach ($App in ($AppOrder |where-object {$_.publisher -ne 'Microsoft'})) {
            if ($App.AppPath -like '*.app') {
                $AppFile = $App.AppPath
            }
            else {
                $AppFile = (Get-ChildItem -Path $SourceFolder -Filter "$($App.publisher)_$($App.name)_*.app" | Select-Object -First 1).FullName
            }
            $Code={
                param(
                    $ContainerName,
                    $Tenant,
                    $App
                )
                Get-BcContainerAppInfo -containerName $ContainerName -tenantSpecificProperties -sort None -Tenant $Tenant | where-object { $_.Name -eq $App.name }
            }
            $dockerapp = Invoke-Command -Session $pssession -ScriptBlock $Code -ArgumentList $ContainerName,$Tenant,$App  | Sort-Object -Property Version | Select-Object -Last 1
            if ((-not $AppFile) -and (-not $dockerapp)) {
                Write-Host "App $($App.name) from $($App.publisher) not found."
                if ($AppDownloadScript) {
                    Write-Host "Trying to download..."
                    Download-ALApp -name $App.name -publisher $App.publisher -version $App.version -targetPath $SourceFolder -AppDownloadScript $AppDownloadScript
                    $AppFile = (Get-ChildItem -Path $SourceFolder -Filter "$($App.publisher)_$($App.name)_*.app" | Select-Object -First 1).FullName
                    $App.AppPath = $AppFile               
                }
            } else {
                if (-not $dockerapp) {
                    Write-Host "$($App.name) found as file $($App.AppPath)"
                } else {
                    Write-Host "$($App.name) $($dockerapp.version) found already installed"
                    if ([version]$dockerapp.version -lt [version]$App.version) {
                        Write-Host "Version $($App.version) required, trying to download..."
                        Download-ALApp -name $App.name -publisher $App.publisher -version $App.version -targetPath $SourceFolder -AppDownloadScript $AppDownloadScript
                        $AppFile = (Get-ChildItem -Path $SourceFolder -Filter "$($App.publisher)_$($App.name)_*.app" | Select-Object -First 1).FullName
                        $App.AppPath = $AppFile               
                    }
                }
    
            }
        }
    
        Write-Host "Getting dependencies after download"
        $AppOrder = Get-ALAppOrder -ArtifactUrl $ArtifactUrl -Path $SourceFolder -Recurse:$Recurse -IncludeAppFiles $IncludeAppFiles
        Write-Verbose "Detected dependencies:"
        foreach ($App in $AppOrder) {
            Write-Verbose "$($App.name) $($App.AppPath)"
        }
        Write-Host "Publishing and Installing the apps..."
        foreach ($App in ($AppOrder |where-object {$_.publisher -ne 'Microsoft'})) {
            Write-Host "--- $($App.name)"
            if ($App.AppPath -like '*.app') {
                $AppFile = $App.AppPath
            }
            else {
                $AppFile = (Get-ChildItem -Path $SourceFolder -Filter "$($App.publisher)_$($App.name)_*.app" | Select-Object -First 1).FullName
            }

            $Code={
                param(
                    $ContainerName,
                    $Tenant,
                    $App
                )
                Get-BcContainerAppInfo -containerName $ContainerName -tenantSpecificProperties -sort None -Tenant $Tenant | where-object { $_.Name -eq $App.name }
            }
            $dockerapp = Invoke-Command -Session $pssession -ScriptBlock $Code -ArgumentList $ContainerName,$Tenant,$App
    
            if ($AppFile) {
                if ($HostName -eq '.') {
                    $Script = {
                        param($AppFile)
                        Write-Host "Getting info about $AppFile"
                        Get-NAVAppInfo -Path $AppFile
                    }
                    $AppFileInfo = Invoke-ScriptInBcContainer -containerName $ContainerName -scriptblock $Script -argumentList (Get-BcContainerPath -containerName $ContainerName -path $AppFile)

                    Publish-BcContainerApp -containerName $ContainerName `
                                            -appFile $AppFile `
                                            -skipVerification:$SkipVerify `
                                            -sync `
                                            -syncMode $SyncMode `
                                            -tenant $Tenant `
                                            -scope $Scope `
                                            -useDevEndpoint:$UseDevEndpoint
                    $AppInfo = Get-BcContainerAppInfo `
                                            -containerName $ContainerName `
                                            -tenant $Tenant `
                                            -tenantSpecificProperties | where-object {($_.Name -eq $AppFileInfo.Name) -and ($_.Version -eq $AppFileInfo.Version)}
                    if ($AppInfo.NeedsUpgrade) {
                        Write-Host "Upgrading app data"
                        Start-BcContainerAppDataUpgrade -containerName $ContainerName `
                                                        -tenant $Tenant `
                                                        -appName $AppInfo.Name `
                                                        -appVersion $AppInfo.Version
                    }                                            
                    $AppInfo = Get-BcContainerAppInfo `
                                            -containerName $ContainerName `
                                            -tenant $Tenant `
                                            -tenantSpecificProperties | where-object {($_.Name -eq $AppFileInfo.Name) -and ($_.Version -eq $AppFileInfo.Version)}
                    if (-not $AppInfo.IsInstalled) {
                        Write-Host "Installing app"
                        Install-BcContainerApp  -containerName $ContainerName `
                                                -tenant $Tenant `
                                                -appName $AppInfo.Name `
                                                -appVersion $AppInfo.Version `
                                                -Force
                    }
                        
                } else {
                    $FileName = Split-Path $AppFile -Leaf
                    $Code = {
                        param(
                            $FileName
                        )
                        $Result = Join-Path ($env:TEMP) $FileName
                        $Result
                    }
                    $TargetFileName = Invoke-Command -Session $pssession -ScriptBlock $Code -ArgumentList $FileName
                    Write-Host "Transfering to remote from $AppFile to $TargetFileName"
                    Copy-Item -ToSession $pssession -Path $AppFile -Destination $TargetFileName -Force
                    $Code = {
                        param(
                            $ContainerName,
                            $AppFile
                        )
                        $Script = {
                            param($AppFile)
                            Write-Host "Getting info about $AppFile"
                            Get-NAVAppInfo -Path $AppFile
                        }
                        $ContainerFileName = Get-BcContainerPath -containerName $ContainerName -path $AppFile
                        If (-not $ContainerFileName) {
                            $FileName = Split-Path $AppFile -Leaf
                            $ContainerFileName = Join-Path 'c:\run\my' $FileName
                            Copy-FileToBcContainer -containerName $ContainerName -localPath $AppFile -containerPath $ContainerFileName | Out-Null
                        }
                        $AppInfo = Invoke-ScriptInBcContainer -containerName $ContainerName -scriptblock $Script -argumentList $ContainerFileName
                        if (-not (Get-BcContainerPath -containerName $ContainerName -path $AppFile)) {
                            $Script = {
                                param($AppFile)
                                Write-Host "Removing $AppFile"
                                remove-item -Path $AppFile -Force
                            }
                            Invoke-ScriptInBcContainer -containerName $ContainerName -scriptblock $Script -argumentList $ContainerFileName | Out-Null
                        }
                        return $AppInfo

                    }
                    $AppFileInfo = Invoke-Command -Session $pssession -ScriptBlock $Code -ArgumentList $ContainerName,$TargetFileName | sort-object -Property Version |Select-Object -Last 1
                    $dockerappInfo = $dockerapp | Where-Object {($_.Name -eq $AppFileInfo.Name) -and `
                                                                ($_.Publisher -eq $AppFileInfo.Publisher) -and `
                                                                ([Version]$_.Version -ge [version]$AppFileInfo.Version)}
                    $Code = {
                        param(
                            $ContainerName,
                            $AppFile,
                            $SkipVerify,
                            $SyncMode,
                            $Tenant,
                            $Scope,
                            $UseDevEndpoint,
                            $AppFileInfo
                        )
                        Publish-BcContainerApp -containerName $ContainerName `
                                                -appFile $AppFile `
                                                -skipVerification:$SkipVerify `
                                                -sync `
                                                -syncMode $SyncMode `
                                                -tenant $Tenant `
                                                -scope $Scope `
                                                -useDevEndpoint:$UseDevEndpoint
                        Remove-Item -Path $AppFile -Force

                        $AppInfo = Get-BcContainerAppInfo `
                                            -containerName $ContainerName `
                                            -tenant $Tenant `
                                            -tenantSpecificProperties | where-object {($_.Name -eq $AppFileInfo.Name) -and ($_.Version -eq $AppFileInfo.Version)}
                        if (($AppInfo.NeedsUpgrade) -or ((-not [String]::IsNullOrEmpty($AppInfo.ExtensionDataVersion)) -and ($AppInfo.ExtensionDataVersion -ne $AppFileInfo.Version))) {
                            Write-Host "Upgrading app data"
                            Start-BcContainerAppDataUpgrade -containerName $ContainerName `
                                                            -tenant $Tenant `
                                                            -appName $AppInfo.Name `
                                                            -appVersion $AppInfo.Version
                        }                                            
                        $AppInfo = Get-BcContainerAppInfo `
                                                -containerName $ContainerName `
                                                -tenant $Tenant `
                                                -tenantSpecificProperties | where-object {($_.Name -eq $AppFileInfo.Name) -and ($_.Version -eq $AppFileInfo.Version)}
                        if (-not $AppInfo.IsInstalled) {
                            Write-Host "Installing app"
                            Install-BcContainerApp  -containerName $ContainerName `
                                                    -tenant $Tenant `
                                                    -appName $AppInfo.Name `
                                                    -appVersion $AppInfo.Version `
                                                    -Force
                        }
                    }
                    if (-not $dockerappInfo) {
                        Invoke-Command -Session $pssession -ScriptBlock $Code -ArgumentList $ContainerName,$TargetFileName,$SkipVerify,$SyncMode,$Tenant,$Scope,$UseDevEndpoint,$AppFileInfo
                    } else {
                        Write-Host "App $($AppFileInfo.Name) version $($dockerappInfo.Version) already detected, skipping"
                    }
                }
            
                if ($dockerapp) {
                    $Code={
                        param(
                            $ContainerName,
                            $App
                        )
                        Get-BcContainerAppInfo -containerName $ContainerName -tenantSpecificProperties -sort None | where-object { $_.Name -eq $App.name } | Sort-Object -Property "Version" | Select-Object -Unique -Property *
                    }
                    $dockerapp = Invoke-Command -Session $pssession -ScriptBlock $Code -ArgumentList $ContainerName,$App

                    foreach ($uapp in $dockerapp) {
                        if ((-not $uapp.IsInstalled) -and ($uapp.Version -ne $AppFileInfo.Version)) {
                            Write-Host "Unpublishing version $($uapp.Version) if possible"
                            $Code = {
                                param(
                                    $ContainerName,
                                    $App,
                                    $uapp
                                )
                                Unpublish-BcContainerApp -containerName $ContainerName -appName $App.name -version $uapp.Version -ErrorAction SilentlyContinue
                            }
                            Invoke-Command -Session $pssession -ScriptBlock $Code -ArgumentList $ContainerName,$App,$uapp
                        }
                    }
                }
            } else {
                if ($dockerapp) {
                    Write-Host "Using installed version of $($App.name) from $($App.publisher)"
                } else {
                    Write-Error "App $($App.name) from $($App.publisher) is missing!"
                }
            }
        }
    } finally  {
    }
         

}
finally {
    Trace-VstsLeavingInvocation $MyInvocation
}
