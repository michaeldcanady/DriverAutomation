function Find-DriverPack {
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
        Creation Date:  11/25/2021
        Purpose/Change: Initial Script Development
  
    .EXAMPLE
        Find-DriverPack -DriverPack @() -Manufacturer Dell -Model TestModel -Architecture x64
    #>
    
    #-----------------------------------------------------------[Parameters]-----------------------------------------------------------

    param(
        [Parameter(Mandatory)]
        [object[]]$DriverPacks,

        [Parameter(Mandatory)]
        [string]$Manufacturer,

        [Parameter(Mandatory)]
        [string]$Model,

        [Parameter(Mandatory)]
        [string]$OsBuild,

        [Parameter(Mandatory)]
        [ValidateSet("x86", "x64")]
        [string]$Architecture
    )

    #---------------------------------------------------------[Initialisations]--------------------------------------------------------



    #----------------------------------------------------------[Declarations]----------------------------------------------------------



    #-----------------------------------------------------------[Execution]------------------------------------------------------------

    $Man = $DriverPacks | ? { ($_.Manufacturer -eq $Manufacturer) } | select -ExpandProperty Drivers

    return $Man | ? { ($_.SystemName -eq $Model) -and ($_.OSArchitecture -eq $Architecture) -and ($_.OsBuild -eq $OsBuild) } | Add-Member -NotePropertyName "Manufacturer" -NotePropertyValue $Manufacturer -PassThru | Sort-Object -Unique
}