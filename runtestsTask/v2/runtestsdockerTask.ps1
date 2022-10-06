[CmdletBinding()]
param()

Trace-VstsEnteringInvocation $MyInvocation

try{
    # Get inputs.
    $containername = Get-VstsInput -Name 'containername' -Require
    $testfile = Get-VstsInput -Name 'testfile' -Require
    $testsuite = Get-VstsInput -Name 'testsuite' -Default "DEFAULT"
    $tenant  = Get-VstsInput -Name 'tenant' -Default "default"
    $resultonerror  = Get-VstsInput -Name 'resultonerror' -Default "error"
    $auth  = Get-VstsInput -Name 'auth' -Default "Windows"
    $username  = Get-VstsInput -Name 'username' -Default $env:USERNAME
    $password  = Get-VstsInput -Name 'password' -Default ""
    $extensionid  = Get-VstsInput -Name 'extensionid' -Default ""
    $restartContainerAndRetry = Get-VstsInput -Name 'restartandretry' -AsBool
    $createnewcompany = Get-VstsInput -Name 'createnewcompany' -AsBool

    Write-Host "Importing module NVRAppDevOps"
    Import-Module NVRAppDevOps -DisableNameChecking

    $FullPath = [System.IO.Path]::GetFullPath($testfile)

    if ($createnewcompany) {
        $TestCompanyName = 'NVRTask_Tests'
        New-CompanyInBCContainer -containerName $containername -tenant $tenant -companyName $TestCompanyName
        Write-Host "Running Codeunit in $TestCompanyName"
        Invoke-NavContainerCodeunit -containerName $containername -codeunitId 45 -methodName "ReadRounding" -CompanyName $TestCompanyName
    }
    $result=Run-ALTestInContainer -ContainerName $containername -detailed -AzureDevOps $resultonerror -XUnitResultFileName "$FullPath" -testSuite $testsuite -Auth $auth -Username $username -Password $password -tenant $tenant -extensionId $extensionid -restartContainerAndRetry:$restartContainerAndRetry -companyName $TestCompanyName -returnTrueIfAllPassed
    if (($resultonerror -eq 'error') -and ($result -eq $false)) {
        # Fail if any errors.
        Write-VstsSetResult -Result 'Failed' -Message "Error detected" -DoNotThrow
    }
} finally {
    Trace-VstsLeavingInvocation $MyInvocation
}