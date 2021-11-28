<#
.SYNOPSIS
    <Overview of script>

.DESCRIPTION
    <Brief description of script>

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
  
.EXAMPLE
    BackEndv2
#>

#-----------------------------------------------------------[Parameters]-----------------------------------------------------------
[CmdletBinding()]
param(
    [string]$Manufacturer,
    [string]$Model,
    [ValidateSet("x86", "x64")]
    [string]$Architecture,
    [string]$OS,

    [Parameter(Mandatory, ParameterSetName = "ConfigMgrDistribute")]
    [Parameter(Mandatory, ParameterSetName = "MDT&ConfigMgrDistribute")]
    [Parameter(Mandatory, ParameterSetName = "ConfigMgr")]
    [Parameter(Mandatory, ParameterSetName = "MDT&ConfigMgr")]
    [ValidateSet("Standard Pkg", "Driver Pkg")]
    [string]$ConfigMgr,

    [Parameter(Mandatory, ParameterSetName = "MDT&ConfigMgrDistribute")]
    [Parameter(Mandatory, ParameterSetName = "MDT&ConfigMgr")]
    [Parameter(Mandatory, ParameterSetName = "MDT")]
    [switch]$MDT,

    [Parameter(Mandatory, ParameterSetName = "DownloadOnly")]
    [Parameter(Mandatory, ParameterSetName = "Generate&Download")]
    [switch]$Download,

    [Parameter(Mandatory, ParameterSetName = "GenerateXml")]
    [Parameter(Mandatory, ParameterSetName = "Generate&Download")]
    [switch]$GenerateXml,

    [Parameter(Mandatory, ParameterSetName = "MDT&ConfigMgrDistribute")]
    [Parameter(Mandatory, ParameterSetName = "ConfigMgrDistribute")]
    [Parameter(Mandatory, ParameterSetName = "ConfigMgr")]
    [Parameter(Mandatory, ParameterSetName = "MDT&ConfigMgr")]
    [string]$SiteCode,

    [Parameter(Mandatory, ParameterSetName = "MDT&ConfigMgrDistribute")]
    [Parameter(Mandatory, ParameterSetName = "ConfigMgrDistribute")]
    [Parameter(Mandatory, ParameterSetName = "ConfigMgr")]
    [Parameter(Mandatory, ParameterSetName = "MDT&ConfigMgr")]
    [string]$SiteServer,

    [Parameter(Mandatory, ParameterSetName = "MDT&ConfigMgrDistribute")]
    [Parameter(Mandatory, ParameterSetName = "ConfigMgrDistribute")]
    [switch]$DistributePackage,

    [Parameter(Mandatory, ParameterSetName = "MDT&ConfigMgrDistribute")]
    [Parameter(Mandatory, ParameterSetName = "ConfigMgrDistribute")]
    [string[]]$DistributionPoint
)

BEGIN {
    #---------------------------------------------------------[Initialisations]--------------------------------------------------------

    Import-Module .\Packages\FileHandling\FileHandling.psm1 -Force
    Import-Module .\Packages\SccmPackage\SccmPackage.psm1 -Force
    Import-Module .\Packages\WindowsVersions\WindowsVersions.psm1 -Force

    #----------------------------------------------------------[Declarations]----------------------------------------------------------
    $ListOfManufacturers = @()

    $DeploymentPlatforms = @("ConfigMgr - Standard Pkg", "ConfigMgr - Driver Pkg", "ConfigMgr - Standard Pkg(Pilot)", "MDT", "Both - ConfigMgr Driver Pkg & MDT",
        "Both - CStandard Pkg & MDT", "Download Only", "Download & XML Generation")

    $Architectures = @("x64", "x86")

    $Models = @()

    #-----------------------------------------------------------[Functions]------------------------------------------------------------

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
}

PROCESS {
    #-----------------------------------------------------------[Execution]------------------------------------------------------------

    #$ListOfManufacturers = Get-ManufacturersInformation

    #$(Get-ManufacturersInformation | select -ExpandProperty Drivers)

    $Models = $ListOfManufacturers | Select-Object Manufacturer, @{N = "Models"; E = { $_.Drivers.SystemName } }

    $DriverPack = Find-DriverPack -DriverPacks $(Get-ManufacturersInformation)  -Manufacturer "Dell" -Model "Optiplex 5070" -Architecture "x64"

    #$CompressedFile = Start-DriverPackDownload -Driver $DriverPack

    #Expand-DriverPack -CompressedFile $CompressedFile

    #$ServerLocation = Move-DriverPack -Source "C:\temp\5070-win10-A08-J36D1" -Destination "\\mecmprod01\e$\Test"


    $DriverPackageParams = @{
        SiteCode     = $SiteCode;
        Name         = "Drivers - $($DriverPack.Manufacturer) $($DriverPack.SystemName) $(ConvertFrom-BuildNumber -BuildNumber $($DriverPack.OsBuild)) - $OS $($DriverPack.OSArchitecture)";
        Version      = $($DriverPack.Version);
        Source       = $ServerLocation;
        Manufacturer = $($DriverPack.Manufacturer);
    }

    $DriverPackageParams

    #if($DistributePackage){
    #    $DriverPackageParams["Distribute"] = $true
    #    $DriverPackageParams["DistributionPoint"] = $DistributionPoints
    #}

    #New-DriverPackage @DriverPackageParams    
}