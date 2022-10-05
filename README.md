# NaverticAl Tasks

This package includes tasks you can use in your Build/Release pipelines for Microsoft Dynamics 365 Business Central

## Existing tasks

- Install powershell modules
- Create Container
- Sign app through container
- Publish app to container
- Publish multiple apps to container (dependencies detection)
- Publish PerTenant app to online
- Run Tests in container
- Remove Container
- Compile App
- Set build no. in App.Json and of the build pipeline

## Planned tasks

- Create nuget package
- Get app from nuget

## How to use

On your Azure DevOps account go to the Marketplace, find the extension and install it.
After that, you can use the new tasks in your pipelines through visual designer or yaml, as you wish. Just define the parameters and run the pipeline.

## Example of Release Pipeline to create container, publish the app, test it...

- Install or update scripts
- Create container
- Publish Main App to container
- Publish Test App to container
- Run tests in container
- Publish test results
- Remove container

![image](images/testPipeline.png)

## Example of Release Pipeline to release the app into QA container...

- Install or update scripts
- Publish Main App to container

![image](images/publishPipeline.png)

## Example of Release Pipeline to release the app online...

- Install or update scripts
- Publish App to tenant

![image](images/publishOnlinePipeline.png)

## Example of Release Pipeline to sign the app...

- Install or update scripts
- Download secure file
- Create container
- Sign through container
- Delete file
- Publish signed app artifact

![image](images/signPipeline.png)

## Changelog

### 0.0.179

- Run Codeunit 2 when new company created during RuntestsTask (preventing side effects of some apps initing data on first connection)

### 0.0.168

- CreateBCAppNuspec v 3 added which uses artifact to get app info - no need to create container

### 0.0.162

- publishbcappdocker v8 added which uses artifact to get app info - no need to create container

### 0.0.159

- createdockerTask v5 added with imageName parameter to generate the image

### 0.0.133

- publishdockerTask v5 fixed no ArtifactUrl when container is old and not using artifacts (defaulting to latest stable OnPrem w1)

### 0.0.131

- installmodulesTask fixed to not remove wrong version

### 0.0.130

- publishdockerTask v5 added - using BcContainerHelper cmdlets

### 0.0.127

- add allowPrerelease switch into installbcmodules v3 to allow installation of prerelease versions of modules

### 0.0.126

- installbcmodules v3 - instal bccontainerhelper instead navcontainerhelper

### 0.0.121

- Fix "Error: No such container: powershell" in publishbcappdocker v3

### 0.0.120

- Bugfix UseBestContainerOS when creating docker container ignored this setting

### 0.0.113 - 0.0.119

- Bugfix for publicbcappdocker v3

### 0.0.112

- Add support for remote host in publishbcappdocker v3

### 0.0.111

- When error during unpublishing of previous version of app, it will be ignored. E.g. when app is used on another tenant

### 0.0.110

- CompileBCApps RulesetFile is now plain string instead filePath to be able to enter relative path from App root folder

### 0.0.109

- v2 CompileBCApps wiht RulesetFile and AsmProbingPaths parameters

### 0.0.108

- v2 installbcmodules with possibility to use specific version of modules (e.g. when some module version have bugs)

### 0.0.107

- add useBestContainerOS to CreateContainer task v3.0.0

### 0.0.100

- fix runbctestincontainer to fail task when some test fails

### 0.0.99

- fixes in publishdockerTask when dependency is downloaded (some dependencies could be missed)

### 0.0.98

- fixes in publishdockerTask when dependency is downloaded

### 0.0.97

- publishdockerTask fixing when downloaded dependency not installed

### 0.0.95

- v2 of runtestsTask to support new parameters of navcontainerhelper function (extensionID, restartandretry)
- v2 of createdockerTask to support new parameter TestLibraryOnly to speed up container creation 

### 0.0.94

- Fixed bug when trying to upgrade App from '' version (previous app published but never installed)

### 0.0.91

- Fixed bug with duplicities from get-navcontainerappinfo in PublishDocker task

### 0.0.88-0.0.90

- Fixed bug in publishbcappdocker because missing new parameter introduced in navcontainerhelper to sort result (failing on recursion)

### 0.0.87

- NuSpec description taken from App if not filled in as parameter

### 0.0.62 - 0.0.86

- Minor Changes and bugfixes

### 0.0.61

- Fixed CreateDockerTask when used in Build pipeline

### 0.0.59

- Add SetupBCBuildNo task

### 0.0.58

- CompileBCApp parameters casing fixed
- PublishDockerTask v2.x added - publishing multiple apps in correct order with new settings

### 0.0.57 - 6.6.2019

- Add task compilebcapp
