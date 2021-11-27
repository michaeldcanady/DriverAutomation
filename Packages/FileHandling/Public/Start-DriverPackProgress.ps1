function Start-DriverPackProgress {
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
        Start-DriverPackProgress -Source "C:\Path\To\Cab\File.Cab" -Destination "C:\Path\To\Cab\Folder"
    #>
    
    #-----------------------------------------------------------[Parameters]-----------------------------------------------------------

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Source,
        [Parameter(Mandatory)]
        [string]$Destination,
        [switch]$Asynchronous
    )

    #---------------------------------------------------------[Initialisations]--------------------------------------------------------



    #----------------------------------------------------------[Declarations]----------------------------------------------------------



    #-----------------------------------------------------------[Execution]------------------------------------------------------------

    #Gets Count of files in compressed Archive
    $shell = new-object -com shell.application
    $zip = $shell.namespace("$Source")
    $CabFiles = $zip.items() | 
    Select-Object @{n = 'Name'; e = { Split-Path -Path $_.path -Leaf } }, 
    @{n = 'BaseName'; e = { $_.name } }, 
    @{n = 'FullName'; e = { $_.path } }

    Write-Verbose "Checking if $Destination Exists"
    if (-not (Test-Path $Destination)) {
        Write-Verbose "Creating $Destination"
        New-Item -ItemType Directory -Path $Destination | Out-Null
    }

    $Start_Time = Get-Date

    Write-Progress -Activity "Expanding CAB File:" -CurrentOperation "Expanding" -Id 1 -Status "0% Complete" -PercentComplete 0

    $files = Get-ChildItem $Destination -File -Recurse

    $job = Start-Job -ScriptBlock { param($p1, $p2) Expand "$p1" -F:* "$p2" -R } -ArgumentList "$Source", "$Destination"

    if (-not $Asynchronous) {
        try {
            Do {
                $Current_Time = Get-Date
    
                $files = Get-ChildItem $Destination -File -Recurse
    
                [int]$Percent = ($($files.count) / $($CabFiles.Count)) * 100
    
                $Seconds = if ($(($Current_Time - $Start_Time).seconds) -gt 0) { ($Current_Time - $Start_Time).seconds }else { 1 }
    
                $FilesExpanded = if ($files.count -gt 0) { $files.count }else { 1 }
    
                Write-Progress -Activity "Expanding CAB File:" -CurrentOperation "Expanding" -Id 1 -Status "$Percent% Complete" -PercentComplete $Percent -SecondsRemaining $($($CabFiles.Count) / ($FilesExpanded / $Seconds))
            } while (($($files.count) -ne $($CabFiles.Count)) -and ($job.State -eq "Running"))
        }
        catch {
            throw $_.Exception.Message       
        }
        finally {
            Write-Progress -Activity "Expanding CAB File:" -Status "Expansion Complete" -Completed
        }
    }
}