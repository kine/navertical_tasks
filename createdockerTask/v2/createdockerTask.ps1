[CmdletBinding()]
param()

Trace-VstsEnteringInvocation $MyInvocation

try{
    # Get inputs.
    $containername = Get-VstsInput -Name 'containername' -Require
    $imagename = Get-VstsInput -Name 'imagename' -Require
    $licensefile = Get-VstsInput -Name 'licensefile' -Default ''
    $password = Get-VstsInput -Name 'password' -Default ''
    $username = Get-VstsInput -Name 'username' -Default ''
    $auth = Get-VstsInput -Name 'auth' -Require
    $ram = Get-VstsInput -Name 'ram' -Default '4GB'
    $importtestsuite = Get-VstsInput -Name 'importtestsuite' -AsBool
    $testlibraryonly = Get-VstsInput -Name 'testlibraryonly' -AsBool
    $fastcontainer = Get-VstsInput -Name 'fastcontainer' -AsBool
    $enablesymbolloading = Get-VstsInput -Name 'enablesymbolloading' -AsBool
    $includeCSide = Get-VstsInput -Name 'includeCSide' -AsBool
    $optionalparams = Get-VstsInput -Name 'optionalparams' -Default ''
    $isolation = Get-VstsInput -Name 'isolation' -Default ''
    $UseBestOS = Get-VstsInput -Name 'useBestContainerOS' -AsBool

    if ($isolation -eq 'default') {
        $isolation = ''
    }
    Write-Host "Importing module NVRAppDevOps"
    Import-Module NVRAppDevOps -DisableNameChecking
    $skipimporttestsuite = (-not $importtestsuite)
    $RepoPath = $env:AGENT_RELEASEDIRECTORY
    if (-not $RepoPath) {
        $RepoPath = $env:AGENT_BUILDDIRECTORY
    }
    
    if ($fastcontainer) {
        $PWord = ConvertTo-SecureString -String 'Pass@word1' -AsPlainText -Force
        $User = $env:USERNAME
        $cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User,$PWord
        New-NavContainer -accept_eula `
            -accept_outdated `
            -containerName $containername `
            -imageName $imagename `
            -doNotExportObjectsToText `
            -alwaysPull `
            -shortcuts "None" `
            -auth 'Windows' `
            -Credential $cred `
            -memoryLimit '4GB' `
            -updateHosts `
            -useBestContainerOS:$UseBestOS `
            -additionalParameters @("--volume ""$($RepoPath):c:\app""") `
            -isolation $isolation `
            -myScripts  @(@{"navstart.ps1" = "Write-Host 'Ready for connections!'";"checkhealth.ps1" = "exit 0"})

    } else {

        Init-ALEnvironment `
            -ContainerName $containername `
            -ImageName $imagename `
            -LicenseFile $licensefile `
            -Build 'true' `
            -Username $username `
            -Password $password `
            -RepoPath $RepoPath `
            -Auth $auth `
            -RAM $ram `
            -useBestContainerOS:$UseBestOS `
            -SkipImportTestSuite:$skipimporttestsuite `
            -TestLibraryOnly:$testlibraryonly `
            -EnableSymbolLoading $enablesymbolloading `
            -CreateTestWebServices $false `
            -Isolation $isolation `
            -IncludeCSide $includeCSide `
            -optionalParameters $optionalparams
    }
        
} finally {
    Trace-VstsLeavingInvocation $MyInvocation
}