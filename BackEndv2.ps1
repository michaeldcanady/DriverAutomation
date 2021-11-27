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



#---------------------------------------------------------[Initialisations]--------------------------------------------------------

Import-Module .\Packages\FileHandling\FileHandling.psm1 -Force
Import-Module .\Packages\SccmPackage\SccmPackage.psm1 -Force

#----------------------------------------------------------[Declarations]----------------------------------------------------------

$ListOfManufacturers = @()

$DeploymentPlatforms = @("ConfigMgr - Standard Pkg", "ConfigMgr - Driver Pkg", "ConfigMgr - Standard Pkg(Pilot)", "MDT", "Both - ConfigMgr Driver Pkg & MDT",
    "Both - CStandard Pkg & MDT", "Download Only", "Download & XML Generation")

$Architectures = @("x64", "x86")

$OperationSystemBuilds = @(
    @{
        Version = "Windows 11 21H2"
        Build = "10.0.22000"
    }
    @{
        Version = "Window 10 21H2"
        Build = "10.0.19044"
    }
    @{
        Version = "Window 10 21H1"
        Build = "10.0.19043"
    }
    @{
        Version = "Window 10 20H2"
        Build = "10.0.19042"
    }
    @{
        Version = "Window 10 20H1"
        Build = "10.0.19041"
    }
    @{
        Version = "Window 10 1909"
        Build = "10.0.18363"
    }
    @{
        Version = "Window 10 1903"
        Build = "10.0.18362"
    }
    @{
        Version = "Window 10 1809"
        Build = "10.0.17763"
    }
    @{
        Version = "Window 10 1803"
        Build = "10.0.17134"
    }
    @{
        Version = "Window 10 1709"
        Build = "10.0.16299"
    }
    @{
        Version = "Window 10 1703"
        Build = "10.0.15063"
    }
    @{
        Version = "Window 10 1607"
        Build = "10.0.14393"
    }
    @{
        Version = "Window 10 1511"
        Build = "10.0.10586"
    }
    @{
        Version = "Window 10"
        Build = "10.0.10240"
    }
)

$OperationSystems = @(
    [PSCustomObject]@{
        Version = "Windows 10"
        Builds  = @("1803", "1809", "1909", "20H1", "20H2", "21H1", "21H2")
    }
    [PSCustomObject]@{
        Version = "Windows 11"
        Builds  = @("21H2")
    }
)

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

#-----------------------------------------------------------[Execution]------------------------------------------------------------

#$ListOfManufacturers = Get-ManufacturersInformation

#$(Get-ManufacturersInformation | select -ExpandProperty Drivers)

$Models = $ListOfManufacturers | Select-Object Manufacturer, @{N = "Models"; E = { $_.Drivers.SystemName } }

$DriverPack = Find-DriverPack -DriverPacks $(Get-ManufacturersInformation)  -Manufacturer "Dell" -Model "Optiplex 5070" -Architecture "x64"

$DriverPack

#$CompressedFile = Start-DriverPackDownload -Driver $DriverPack

#Expand-DriverPack -CompressedFile $CompressedFile

#$ServerLocation = Move-DriverPack -Source "C:\temp\5070-win10-A08-J36D1" -Destination "\\mecmprod01\e$\Test"

$OS = if([string]::IsNullOrEmpty($DriverPack.OsBuilds)){$DriverPack.OSVersion}else{"$($DriverPack.OSVersion) $($DriverPack.OsBuilds)"}

#$DriverPackageParams = @{
#    SiteCode = $SiteCode;
#    Name = "Drivers - $($DriverPack.Manufacturer) $($DriverPack.SystemName) - $OS $($DriverPack.OSArchitecture)";
#    Version = $($DriverPack.Version);
#    Source = $ServerLocation;
#    Manufacturer = $($DriverPack.Manufacturer);
#}

#if($DistributePackage){
#    $DriverPackageParams["Distribute"] = $true
#    $DriverPackageParams["DistributionPoint"] = $DistributionPoints
#}

#New-DriverPackage @DriverPackageParams