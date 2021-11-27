function Move-DriverPack {
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
        Move-DriverPack -Source "C:\Path\To\Extracted\Folder" -Destination "\\Path\To\Cab\Folder"
    #>
    
    #-----------------------------------------------------------[Parameters]-----------------------------------------------------------

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({
                if ((Get-Item $_) -is [System.IO.DirectoryInfo]) {
                    if ($_.StartsWith("\\")) {
                        return $(Test-Path "filesystem::$_")
                    }
                    return $(Test-Path "$_")
                }
                else {
                    throw "Source must be a directory"
                }
            })]
        [string]$Source,
        [Parameter(Mandatory)]
        [ValidateScript({
                if ($_.StartsWith("\\")) {
                    return $(Test-Path "filesystem::$_")
                }
                return $(Test-Path "$_")
            })]
        [string]$Destination
    )

    #---------------------------------------------------------[Initialisations]--------------------------------------------------------



    #----------------------------------------------------------[Declarations]----------------------------------------------------------
    
    $Folder = Split-Path -Path $Source -Leaf
    $Dest = "$Destination\$Folder"

    #-----------------------------------------------------------[Execution]------------------------------------------------------------

    $SourceSize = Measure-FolderSize -Source $Source

    $Start_Time = Get-Date

    $Job = Start-Job -ScriptBlock { param($p1, $p2) Copy-Item -Path $p1 -Destination $p2 -Recurse } -ArgumentList $Source, $Destination

    Write-Progress -Activity "Copying Driver Files:" -CurrentOperation "Copying" -Id 1 -Status "0% Complete" -PercentComplete 0

    start-sleep 1

    try {
        Do {
            $Current_Time = Get-Date

            $DestinationSize = Measure-FolderSize -Source $Dest

            [int]$Percent = ($DestinationSize / $SourceSize) * 100

            $Seconds = if ($(($Current_Time - $Start_Time).seconds) -gt 0) { ($Current_Time - $Start_Time).seconds }else { 1 }

            [int]$SecondsRemaining = $SourceSize / ($DestinationSize/$Seconds)

            Write-Progress -Activity "Copying Driver Files:" -CurrentOperation "Copying" -Id 1 -Status "$Percent% Complete" -PercentComplete $Percent -SecondsRemaining $SecondsRemaining
        } while (($DestinationSize -lt $SourceSize) -and ($job.State -eq "Running"))
    }
    catch {
        write-host "Sec remaining: $secondsRemaining"
        Get-Job -Id $($Job.Id) | Stop-Job
        throw $_.Exception.Message     
    }
    finally {
        Write-Progress -Activity "Copying Driver Files:" -Status "Copying Complete" -Completed
    }
}