<#PSScriptInfo

.VERSION 1.1.0.0

.GUID 645bfabe-c85f-4fe4-8558-06934cfff302

.AUTHOR Michael Canady

.COMPANYNAME

.COPYRIGHT 2021 Michael Canady. All rights reserved

.TAGS

.LICENSEURI https://github.com/michaeldcanady/DriverAutomation/blob/master/LICENSE

.PROJECTURI https://github.com/michaeldcanady/DriverAutomation

.ICONURI

.EXTERNALMODULEDEPENDENCIES 

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES Adding Parameters (All), Structing Process Block

.PRIVATEDATA

#> 

#>


<#
.SYNOPSIS

.DESCRIPTION
A Tool to Generate Driver Packages to be Used in Configuration Manager Task Sequences.<Overview of script><Overview of script><Overview of script>

.PARAMETER Path
None
    
.INPUTS
<Inputs if any, otherwise state None>

.OUTPUTS
None

.NOTES
Version:        1.0
Author:         Michael Canady
Creation Date:  11/24/2021
Purpose/Change: Initial Script Development

Version:        1.1.0.0
Author:         Michael Canady
Creation Date:  11/30/2021
Purpose/Change: Adding Parameters (All), Structing Process Block
  
.EXAMPLE
BackEndv2
#>

#-----------------------------------------------------------[Parameters]-----------------------------------------------------------

[CmdletBinding()]
param(
    [Parameter(ParameterSetName = "Download")]
    [Parameter(ParameterSetName = "ConfigFile")]
    [Parameter(ParameterSetName = "ConfigMgr")]
    [switch]$NoGui,
    [Parameter(Mandatory, ParameterSetName = "Download")]
    [Parameter(Mandatory, ParameterSetName = "ConfigFile")]
    [Parameter(Mandatory, ParameterSetName = "ConfigMgr")]
    [ValidateSet("Dell", "Hp", "Lenovo")]
    [string]
    $Manufacturer,
    [Parameter(Mandatory, ParameterSetName = "Download")]
    [Parameter(Mandatory, ParameterSetName = "ConfigFile")]
    [Parameter(Mandatory, ParameterSetName = "ConfigMgr")]
    [string]
    $Model,
    [Parameter(Mandatory, ParameterSetName = "Download")]
    [Parameter(Mandatory, ParameterSetName = "ConfigFile")]
    [Parameter(Mandatory, ParameterSetName = "ConfigMgr")]
    [ValidateSet("Windows 10", "Windows 11")]
    [string]
    $OsVersion,
    [Parameter(Mandatory, ParameterSetName = "Download")]
    [Parameter(Mandatory, ParameterSetName = "ConfigFile")]
    [Parameter(Mandatory, ParameterSetName = "ConfigMgr")]
    [AllowEmptyString()]
    [string]
    $Build,
    [Parameter(Mandatory, ParameterSetName = "Download")]
    [Parameter(Mandatory, ParameterSetName = "ConfigFile")]
    [Parameter(Mandatory, ParameterSetName = "ConfigMgr")]
    [string]
    $Architecture,
    [Parameter(Mandatory,
        ParameterSetName = "Download")]
    [switch]
    $DownloadOnly,
    [Parameter(Mandatory,
        ParameterSetName = "ConfigFile")]
    [switch]
    $FromConfig,
    [Parameter(Mandatory,
        ParameterSetName = "ConfigMgr")]
    [switch]
    $ConfigMgr,
    [Parameter(Mandatory,
        ParameterSetName = "ConfigMgr")]
    [ValidatePattern('(?=^.{1,254}$)(^(?:(?!\d+\.)[a-zA-Z0-9_\-]{1,63}\.?)+(?:[a-zA-Z]{2,})$)')]
    [string]
    $SiteServer,
    [Parameter(Mandatory,
        ParameterSetName = "ConfigMgr")]
    [ValidateLength(1, 3)]
    [string]
    $SiteCode,
    [Parameter(Mandatory,
        ParameterSetName = "ConfigMgr")]
    [string]
    $ServerStorage,
    [Parameter(Mandatory,
        ParameterSetName = "ConfigMgr")]
    [ValidateSet("Driver", "Standard")]
    [string]
    $PkgType,
    [Parameter(ParameterSetName = "ConfigMgr")]
    [switch]
    $DistributePackage
)

BEGIN {
    #---------------------------------------------------------[Initialisations]--------------------------------------------------------

    Import-Module .\Packages\FileHandling\FileHandling.psm1 -Force
    Import-Module .\Packages\SccmPackage\SccmPackage.psm1 -Force
    Import-Module .\Packages\WindowsVersions\WindowsVersions.psm1 -Force

    #----------------------------------------------------------[Functions]-------------------------------------------------------------

    function Get-ManufacturersInformation {
        <#
    .SYNOPSIS
        <Overview of script>

    .DESCRIPTION
        <Brief description of script>

    .PARAMETER Path
        Path to a directory containing Manufacture Xml files generated with or in the format of Get-ManufacturerXml.ps1
    
    .INPUTS
        <Inputs if any, otherwise state None>

    .OUTPUTS
        PSObject with the properties, Manufacturer which contained within the xml path name;
        and drivers which is an array of all drivers found within that specific xml

    .NOTES
        Version:        1.0
        Author:         Michael Canady
        Creation Date:  11/24/2021
        Purpose/Change: Initial Function Development
  
    .EXAMPLE
        Get-ManufacturersInformation -Path "C:\Path\to\xml\folder"
    #>

        #-----------------------------------------------------------[Parameters]-----------------------------------------------------------

        param(
            [string]$Path = ".\xml"
        )

        BEGIN {
            #---------------------------------------------------------[Initialisations]--------------------------------------------------------


        
            #----------------------------------------------------------[Declarations]----------------------------------------------------------
    
            $Manufacturers = @()
        }

        PROCESS {

            #-----------------------------------------------------------[Execution]------------------------------------------------------------
            foreach ($File in $(Get-ChildItem -Path $Path -Filter "*.xml" | Select-Object FullName, Name)) {
               
                [xml]$data = Get-Content $($File.FullName) -raw

                $CurrentManufacturer = [PSCustomObject]@{
                    "Manufacturer" = $($File.Name).split("_")[0];
                    "Drivers"      = @()
                }

                foreach ($driver in $($data.ManifestDrivers.drivers.Driver)) {
                    $CurrentManufacturer.Drivers += $driver
                }

                $Manufacturers += $CurrentManufacturer

            }
        }

        END {
            return $Manufacturers
        }
    }

    function Update-DriverAutomation {
        param(
            $NormalizedScriptVersion,
            $Temp = "C:\Temp"
        )
    
        $Params = @{
            Method = "Get"
            Uri    = "https://api.github.com/repos/michaeldcanady/DriverAutomation/releases/latest"
        }
        
        #Need name, published_at, prerelease, tag_name, zipball_url, draft, body, url
        $LatestVersion = Invoke-RestMethod @Params | Select-Object name, published_at, prerelease, tag_name, assets, draft, body, @{N = "url"; E = { $_.assets.browser_download_url } }, @{N = "Author"; E = { $_.author.login } }
        
        $NormalizedLatestVersion = New-Object System.Version($LatestVersion.tag_name)
        
        if ($NormalizedScriptVersion -ge $NormalizedLatestVersion) {
            return $false
        }
    
        Write-Host "New version: [$NormalizedLatestVersion] found. Current: [$NormalizedScriptVersion]"
    
        $title = 'Update Confirmation'
        $question = 'Would you like to install it?'
        $choices = '&Yes', '&No'
    
        $decision = $Host.UI.PromptForChoice($title, $question, $choices, 1)
    
        if ($decision -ne 0) {
            return $false
        }
    
        try {
            Write-Verbose "Downloading Version [$NormalizedLatestVersion]..."
    
            $DestFile = ($LatestVersion.zipball_url).split("/")[-1]
            $DestPath = "$Temp\$DestFile"
    
            Start-BitsTransfer -Source $LatestVersion.url
    
            $DriverAutomation = "$psscriptroot\DriverAutomationTool.exe"
            $DriverAutomationOld = "$psscriptroot\DriverAutomationTool.exe.old"
    
            Write-Verbose "Renaming $DriverAutomation to $DriverAutomationOld"
    
            Rename-Item -LiteralPath "$DriverAutomation" -NewName "$DriverAutomationOld"
    
            Write-Verbose "Copying $DestPath to $psscriptroot"
    
            Copy-Item -Path $DestPath -Destination $psscriptroot
    
            Write-Verbose "Removing $DriverAutomationOld"
    
            Remove-Item -Path $DriverAutomationOld
    
            Write-Verbose "Successfully updated Driver Automation"
        }
        catch {
            $UpdateError = $_.Exception.Message
            Write-Error $UpdateError
    
            if (Test-Path $DestPath) {
                Write-Verbose "Removing $DestPath"
                Remove-Item $DestPath
            }
    
            if (!(Test-Path $DriverAutomation) -and (Test-Path $DriverAutomationOld)) {
                Write-Verbose "Renaming $DriverAutomationOld to $DriverAutomation"
                Rename-Item -Path $DriverAutomationOld -NewName $DriverAutomation
            }
    
            return $false
        }
        
        return $true
    }

    #----------------------------------------------------------[Declarations]----------------------------------------------------------
    $ListOfManufacturers = Get-ManufacturersInformation
    $ListOfManufacturers = @()

    $DeploymentPlatforms = @("ConfigMgr - Standard Pkg", "ConfigMgr - Driver Pkg", "ConfigMgr - Standard Pkg(Pilot)", "MDT", "Both - ConfigMgr Driver Pkg & MDT",
        "Both - CStandard Pkg & MDT", "Download Only", "Download & XML Generation")

    $Architectures = @("x64", "x86")

    $NormalizedScriptVersion = New-Object System.Version((Test-ScriptFileInfo -Path $PSCommandPath).version)

    #-----------------------------------------------------------[Execution]------------------------------------------------------------

    if (Update-DriverAutomation -NormalizedScriptVersion $NormalizedScriptVersion) {
        #Restart script with same params
    }
    else {
        Write-Host "No updates found."
    }

    $Models = $ListOfManufacturers | Select-Object Manufacturer, @{N = "Models"; E = { $_.Drivers.SystemName } }

    $SelectedBuild = ConvertTo-BuildNumber -OperatingSystem $OsVersion -Version $Build
}

PROCESS {
    #region NO GUI
    if (-not $Gui) {
        $DriverPack = Find-DriverPack -DriverPacks $(Get-ManufacturersInformation)  -Manufacturer $Manufacturer -Model $Model -OsBuild $SelectedBuild -Architecture $Architecture

        $CompressedFile = Start-DriverPackDownload -Driver $DriverPack

        $UncompressedFile = Expand-DriverPack -CompressedFile $CompressedFile

        if ($ConfigMgr) {
            $ServerLocation = Move-DriverPack -Source $UncompressedFile -Destination $ServerStorage
        
            $DriverPackageParams = @{
                SiteCode     = $SiteCode;
                Name         = "Drivers - $($DriverPack.Manufacturer) $($DriverPack.SystemName) - $(ConvertFrom-BuildNumber -BuildNumber $($DriverPack.OsBuild)) $($DriverPack.OSArchitecture)";
                Version      = $($DriverPack.Version);
                Source       = $ServerLocation;
                Manufacturer = $($DriverPack.Manufacturer);
            }
    
            $DriverPackageParams
    
            $PackageName = switch ($PkgType) {
                "Driver" {
                    $DriverPackageParams["Model"] = $($DriverPack.SystemName)
                    New-DriverPackage @DriverPackageParams
                }
                "Standard" {
                    New-StandardPackage @DriverPackageParams
                }
            }
    
            if ($DistributePackage) {
                Write-Verbose "Distributing $Name to $($DistributionPoint -join ",")"
                Start-CMContentDistribution -PackageName $PackageName -DistributionPointName $DistributionPoints
            }
        }
        elseif ($DownloadOnly) {
            return $UncompressedFile
        }
    }
    #endregion
}

END {

}