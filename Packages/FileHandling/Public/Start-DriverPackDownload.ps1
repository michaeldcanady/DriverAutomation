function Start-DriverPackDownload {
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
        Start-DriverPackDownload -Driver @{}
        Start-DriverPackDownload -Driver @{} -Temp "C:\Temp"
    #>
    
    #-----------------------------------------------------------[Parameters]-----------------------------------------------------------

    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [PSCustomObject]$Driver,

        [Parameter(Mandatory=$false)]
        [string]$Temp = "C:\Temp",
        [Parameter(Mandatory=$false)]
        [switch]$DisableHashing,

        [Parameter(Mandatory=$false)]
        [ValidateRange(1,10)]
        [int]$AttemptLimit = 3
    )

    #---------------------------------------------------------[Initialisations]--------------------------------------------------------



    #----------------------------------------------------------[Declarations]----------------------------------------------------------

    $FileName = Split-Path -Leaf -Path $Driver.Path

    

    $CompressedFilePath = "$Temp\$FileName"

    #-----------------------------------------------------------[Execution]------------------------------------------------------------

    do{
        Write-Verbose "($Attempts/$AttemptLimit) Attempting to install driver pack for []..."
        Start-BitsTransfer -Source $($Driver.Path) -Destination $Temp
        $Attempts++
    } while(-not (Test-Path -Path $CompressedFilePath) -and ($Attempts -lt $AttemptLimit))

    if(-not (Test-Path -Path $CompressedFilePath)){
        throw "Unable to download Driver Pack"
    }

    if (-not $DisableHashing) {
        Write-Verbose "Hashing Installed Driver Pack using $($Driver.Algorithm) Algorithm"
        $InstalledFileHash = Get-FileHash -Path $CompressedFilePath -Algorithm $($Driver.Algorithm)

        Write-Verbose "Comparing Generated hash to manufacturer hash."
        if (($InstalledFileHash.Hash -ne $Driver.Hash) -and ($Driver.Hash -ne "N/A")) {
            throw "Unable to install driver package as the downloaded file does not match the provided hash"
        }
    } else {
        Write-Warning -Message "File Hashing has been disabled"
    }

    return "$temp\$FileName"
}