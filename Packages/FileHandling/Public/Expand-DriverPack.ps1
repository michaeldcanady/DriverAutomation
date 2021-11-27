function Expand-DriverPack {
    <#
    .SYNOPSIS
        <Overview of script>

    .DESCRIPTION
        <Brief description of script>

    .PARAMETER CompressedFile
        Specifies the path to an archive file. the value of CompressedFile is used exactly as it is typed. Wildcard characters are not supported.
        If the path includes escape characters, enclose each escape character in single quotation marks, to instruct PowerShell not to interpret any characters as escape sequences.
        Types: String
        Position: Named
        Default Value: None
        Accepts pipeline input: False
        Accepts wildcard characters: False
    
    .PARAMETER CleanFile
        Deletes the archive after it is successfully extracted
        Types: SwitchParameter
        Position: Named
        Default Value: None
        Accepts pipeline input: False
        Accepts wildcard characters: False
    
    .INPUTS
        None
        You cannot pipe input to this cmdlet.

    .OUTPUTS
        String
        The cmdlet outputs a file path to expanded archive

    .NOTES
        Version:        1.0
        Author:         Michael Canady
        Creation Date:  11/26/2021
        Purpose/Change: Initial Script Development
  
    .EXAMPLE
        Export-DriverPack -CompressedFile "C:\Path\to\compressed\file.cab"
    #>
    
    #-----------------------------------------------------------[Parameters]-----------------------------------------------------------

    param(
        [Parameter(Mandatory = $true)]
        [ValidateScript({ Test-Path $_ })]
        [string]$CompressedFile,
        [string]$Temp = "C:\Temp",
        [switch]$CleanFile
    )

    #---------------------------------------------------------[Initialisations]--------------------------------------------------------



    #----------------------------------------------------------[Declarations]----------------------------------------------------------

    $File = New-Object System.IO.FileInfo($CompressedFile)

    $FileType = $($File.Extension).replace(".", "")
    $UncompressedFilePath = "$Temp\$($File.BaseName)"

    #-----------------------------------------------------------[Execution]------------------------------------------------------------

    Write-Verbose "Checking if $UncompressedFilePath already exists"
    if (-not(Test-Path $UncompressedFilePath)) {
        Write-Verbose "Creating $UncompressedFilePath"
        New-Item -ItemType Directory $UncompressedFilePath | Out-Null
    }

    Write-Verbose "Expanding $CompressedFilePath into $UncompressedFilePath"

    switch ($FileType.ToUpper()) {
        "CAB" {
            Write-Host "CAB File"
            Start-DriverPackProgress -Source $CompressedFile -Destination $UncompressedFilePath
        }
        "ZIP" {
            Expand-Archive -LiteralPath $CompressedFilePath -DestinationPath $UncompressedFilePath
        }
    }


    if ($CleanFile) {
        Write-Verbose "Deleting $CompressedFilePath"
        Remove-Item $CompressedFilePath
    }

    return $UncompressedFilePath
}