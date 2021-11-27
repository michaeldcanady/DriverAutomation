#using namespace System.Management.Automation

#class ValidFilesGenerator : IValidateSetValuesGenerator {
#    [string[]] GetValidValues() {
#        $Values = (Get-ChildItem -File).Name
#        return $Values
#    }
#}
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



[cmdletBinding()]
param(
    [Parameter(ParameterSetName = "Get")]
    [Parameter(Mandatory,ParameterSetName = "View")]
    [switch]$NoGui,
    [Parameter(ParameterSetName = "View")]
    [switch]$listDrivers,
    [Parameter(ParameterSetName = "Get")]
    [string]$Model
)


#---------------------------------------------------------[Initialisations]--------------------------------------------------------

Import-Module .\BackEndv2.ps1 -Force

#----------------------------------------------------------[Declarations]----------------------------------------------------------

#-----------------------------------------------------------[Functions]------------------------------------------------------------

function Format-DriverListView {

    param(
        [string]$OrderBy
    )

    $Models = @()

    foreach ($object in $ListOfManufacturers) {
        $Manufacturer = $object.Manufacturer
        $ManufacturerDrivers = $($object | ? { $_.Manufacturer -eq $Manufacturer } | select -ExpandProperty Drivers)
        $ManufacturerDrivers = $ManufacturerDrivers | % { $_ | Add-Member -NotePropertyName "Manufacturer" -NotePropertyValue $Manufacturer -PassThru }

        $Models += $ManufacturerDrivers
    }

    $CleanedModels = $Models | select SystemName, Manufacturer, OSVersion, OsBuilds, OSArchitecture

    return $CleanedModels
}


#-----------------------------------------------------------[Execution]------------------------------------------------------------

if ($listDrivers) {
    $ListOfManufacturers = Get-ManufacturersInformation

    $Params = {
        OrderBy = $OrderBy
    }

    Format-DriverListView @Params
}