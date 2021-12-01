function New-StandardPackage {
    <#
    .SYNOPSIS
        <Overview of script>

    .DESCRIPTION
        <Brief description of script>

    .PARAMETER Source
        Path to the CAB file to extract

        Types: String
        Position: Named
        Default Value: None
        Accepts pipeline input: False
        Accepts wildcard characters: False
    
    .PARAMETER Destination
        Path to the folder in which to extract the Source

        Types: String
        Position: Named
        Default Value: None
        Accepts pipeline input: False
        Accepts wildcard characters: False
    
    .INPUTS
        None
        You cannot pipe input to this cmdlet.

    .OUTPUTS
        None
        Start-DriverPackProgress does not generate any output.

    .NOTES
        Version:        1.0
        Author:         Michael Canady
        Creation Date:  11/26/2021
        Purpose/Change: Initial Script Development
  
    .EXAMPLE
        New-StandardPackage -SiteCode ABC -Name PackageName -Version 1.0 -Source "\\Path\to\source\drive"
        New-StandardPackage -SiteCode ABC -Name PackageName -Description "Wonderful Package" -Manufacturer "Me" -Version 1.0 -Source "\\Path\to\source\drive"
        New-StandardPackage -SiteCode ABC -Name PackageName -Version 1.0 -Source "\\Path\to\source\drive"
        New-StandardPackage -SiteCode ABC -Name PackageName -Description "Wonderful Package" -Manufacturer "Me" -Version 1.0 -Source "\\Path\to\source\drive"
    #>
    
    #-----------------------------------------------------------[Parameters]-----------------------------------------------------------
    [cmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateLength(1, 3)]
        [string]$SiteCode,
        [Parameter(Mandatory)]
        [string]$Name,
        [string]$Description,
        [string]$Manufacturer,
        [Parameter(Mandatory)]
        [string]$Version,
        [Parameter(Mandatory)]
        [string]$Source
    )

    BEGIN {
        Push-Location

        Set-Location "$SiteCode`:"
    }

    PROCESS {
        $PackageParams = @{
            Name    = $Name;
            Version = $Version;
            Path    = $Source;
        }
    
        foreach ($Option in @{"Description" = $Description; "Manufacturer" = $Manufacturer; }.GetEnumerator()) {
            if (-not [string]::IsNullOrEmpty($Option.Value)) {
                $PackageParams[$Option.Name] = $Option.Value
            }
        }
    
        ## Create the Package ##
        Write-Verbose "Creating $Name Package"
        $Package = New-CMPackage @PackageParams
    }

    END {
        Write-Verbose "Returning back to previous location"
        Pop-Location
        return $Package.Name
    }
}