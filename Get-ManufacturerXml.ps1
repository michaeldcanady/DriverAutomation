#requires -version 2
<#
.SYNOPSIS
  <Overview of script>

.DESCRIPTION
  <Brief description of script>

.PARAMETER Manufacturers
    <Brief description of parameter input required. Repeat this attribute if required>

.PARAMETER All
    None

.PARAMETER XmlTempFolder
    <Brief description of parameter input required. Repeat this attribute if required>
    
.INPUTS
  <Inputs if any, otherwise state None>

.OUTPUTS
  <Outputs if any, otherwise state None - example: Log file stored in C:\Windows\Temp\<name>.log>

.NOTES
  Version:        1.0
  Author:         Michael Canady
  Creation Date:  11/24/2021
  Purpose/Change: Initial script development

  Version:        1.1
  Author:         Michael Canady
  Creation Date:  11/24/2021
  Purpose/Change: Adding Header Information
  
.EXAMPLE
  .\Get-ManufacturerXml.ps1 -Manufacturers "Dell","Hp"
  .\Get-ManufacturerXml.ps1 -Manufacturers "Dell","Hp" -LogPath "C:\Path\To\Folder\Log.log"
  .\Get-ManufacturerXml.ps1 -Manufacturers "Dell","Hp" -XmlTempFolder "C:\Path\To\Folder\Temp" -LogPath "C:\Path\To\Folder\Log.log"
  .\Get-ManufacturerXml.ps1 -All
  .\Get-ManufacturerXml.ps1 -All -LogPath "C:\Path\To\Folder\Log.log"
  .\Get-ManufacturerXml.ps1 -All -XmlTempFolder "C:\Path\To\Folder\Temp" -LogPath "C:\Path\To\Folder\Log.log"
#>

#-----------------------------------------------------------[Parameters]-----------------------------------------------------------

[CmdletBinding(DefaultParameterSetName = "Specific")]
param(
    [Parameter(Mandatory, ParameterSetName = "Specific", HelpMessage = "A Comma Seperated List, of Readied Manufacturer's, to Generate the Xml.", Position = 0, ValueFromPipeline)]
    [Alias("Vendors")]
    [string[]]$Manufacturers,
    [Parameter(Mandatory,
        ParameterSetName = "All",
        HelpMessage = "Generates Xml for All Avaliable Manufacturers.",
        Position = 0)]
    [switch]$All,
    [string]$Destination = "$PSScriptRoot\xml",
    [Parameter(Mandatory = $false, HelpMessage = "Location to Store OEM Driver Package Xml until No Longer Needed.", Position = 1)]
    [Alias("TempFolder")]
    [ValidateUserDrive()]
    [string]$XmlTempFolder = "C:\Github\DriverAutomation\xml\Temp",
    [Parameter(Mandatory = $false, HelpMessage = "Location to Store Log File.", Position = 1)]
    [string]$LogPath = "C:\Windows\Temp"
)

BEGIN {
    #---------------------------------------------------------[Initialisations]--------------------------------------------------------
    Import-Module .\Packages\WindowsVersions\WindowsVersions.psm1 -Force
    #Set Error Action to Silently Continue
    $ErrorActionPreference = "Continue"

    #----------------------------------------------------------[Declarations]----------------------------------------------------------

    #Script Version
    #$ScriptVersion = "1.0"

    #Log File Info
    #$LogPath = "C:\Windows\Temp"
    #$LogName = "<script_name>.log"
    #$LogFile = Join-Path -Path $LogPath -ChildPath $LogName

    #-----------------------------------------------------------[Functions]------------------------------------------------------------

    function ConvertTo-DaXml {
        [CmdletBinding()]
        param (
            #Object to Input
            [Parameter(ValueFromPipeline)]$InputObject,
            #Name of the root document node. Defaults to "Objects"
            $RootNodeName = "Objects"
        ) 

        begin {
            [xml]$doc = New-Object System.Xml.XmlDocument
            #Add XML Declaration
            $null = $doc.AppendChild($doc.CreateXmlDeclaration("1.0", "UTF-8", $null))
            #Add XML Root Node
            $root = $doc.AppendChild($doc.CreateElement($RootNodeName))
        }

        process {

            foreach ($Object in $InputObject.getenumerator()) {
                switch ($Object.value.GetType().name) {
                    Hashtable {
                        foreach ($Object in $Entry.getenumerator()) {
                            $propNode = $doc.CreateElement("Driver")
                            New-DaChildXml -Entry $($SubEntry.value) -Name $($SubEntry.Name) -doc $doc -parentNode $propNode
                            $null = $root.AppendChild($propNode)
                        }
                    }
                    string {
                        $propNode = $doc.CreateElement($Object.Name)
                        $propNode.InnerText = $($Object.Value)
                        $null = $root.AppendChild($propNode)
                    }
                    object[] {
                        $propNode1 = $doc.CreateElement($Object.Name)
                        foreach ($SubEntry in $Object.value) {
                            try {
                                New-DaChildXml -Entry $SubEntry -Name $Object.Name -doc $doc -parentNode $propNode1
                            }
                            catch {
                                $propNode1
                                $_.Exception.Message
                                $SubEntry
                                exit
                            }
                        }
                        $null = $root.AppendChild($propNode1)
                    }
                }
            }        
        }

        end {
            return $doc.outerxml
        }
    }
    function New-DaChildXml {
        param(
            $Entry,
            [xml]$doc,
            $Name,
            $parentNode
        )
        if ($null -ne $Entry) {
            switch ($Entry.GetType().name) {
                Hashtable {
                    $propNode = $doc.CreateElement("Driver")
                    foreach ($SubEntry in $Entry.getenumerator()) {
                        New-DaChildXml -Entry $($SubEntry.value) -Name $($SubEntry.Name) -doc $doc -parentNode $propNode
                    }
                    $null = $parentNode.AppendChild($propNode)
                }
                string {
                    $propNode = $doc.CreateElement($Name)
                    $propNode.InnerText = $($Entry)
                    $null = $parentNode.AppendChild($propNode)
                }
                object[] {
                    foreach ($SubEntry in $Entry) {
                        New-DaChildXml -Entry $SubEntry -Name $Name -doc $doc -parentNode $parentNode
                    }
                }
            }
        }
    }
    function Format-XML {
        param(
            [Parameter(ValueFromPipeline)]
            [xml]$xml,
            $indent = 2
        )
        $StringWriter = New-Object System.IO.StringWriter
        $XmlWriter = New-Object System.XMl.XmlTextWriter $StringWriter
        $xmlWriter.Formatting = "indented"
        $xmlWriter.Indentation = $Indent
        $xml.WriteContentTo($XmlWriter)
        $XmlWriter.Flush()
        $StringWriter.Flush()
        return $StringWriter.ToString()
    }

    function New-DellXml {
        param(
            [string]$FilePath,
            [ValidateSet("MD5")]
            [string]$Algorithm
        )

        [xml]$DellDrivers = Get-Content -Path $FilePath -Raw

        $DellDriversObject = @{
            BaseLocation = "https://$($DellDrivers.DriverPackManifest.baseLocation)"
            Version      = $DellDrivers.DriverPackManifest.version
        }

        $DriverPacks = $DellDrivers.driverpackmanifest.driverpackage

        $Drivers = @()
    
        foreach ($DriverPack in $DriverPacks) {

            $RawSystemName = @($DriverPack.SupportedSystems.Brand.Model.name)
            $RawOsArch = @($DriverPack.SupportedOperatingSystems.OperatingSystem.osArch)
            $RawSystemID = @($DriverPack.SupportedSystems.Brand.Model.SystemID)
            $Hash = $DriverPack.Cryptography.Hash | Where-Object { $_.algorithm -eq $Algorithm }
            $Version = $DriverPack.dellVersion
            $Path = $("$($DellDriversObject.baseLocation)/$($DriverPack.Path)")

            if ([string]::IsNullOrEmpty($RawSystemName)) { continue }

            for ($i = 0; $i -lt $RawSystemName.count; $i++) {
                $SystemName = $RawSystemName[$i]
                $SystemID = $RawSystemID[$i]

                for ($j = 0; $j -lt $RawOsArch.count; $j++) {
                    $RawOsVersion = @($DriverPack.SupportedOperatingSystems.OperatingSystem.osCode)[$j]
                    $OsVersion = $RawOsVersion.replace("Windows", "Windows ")
                    $OsVersion = $OsVersion.replace("Vista", "Windows Vista")
                    $OsVersion = $OsVersion.replace("XP", "Windows XP")
                    $OsArch = $RawOsArch[$j]
                    $Drivers += ConvertTo-CustomObject -SystemName $SystemName -SystemID $SystemID -Version $Version -Path $Path -OsVersion $OsVersion -OsBuild "" -OsArch $OsArch -Algorithm $($Hash.algorithm) -Hash $($Hash.$("#text"))
                }
            }  
        }
        $DellDriversObject["Drivers"] = $Drivers

        return $DellDriversObject
    }

    function New-HpXml {
        param(
            [string]$FilePath,
            [ValidateSet("MD5")]
            [string]$Algorithm
        )
    
        [xml]$HpDrivers = Get-Content -Path $FilePath
    
        $DriverPacks = $HpDrivers.NewDataSet.HPClientDriverPackCatalog.ProductOSDriverPackList.ProductOSDriverPack
    
        $Drivers = @()
    
        for ($i = 0; $i -lt $DriverPacks.count; $i++) {

            #Cleaning and formating the Architecture as x64 or x86
            $CleanedArch = $($($DriverPacks[$i].Architecture) -replace "-Bit", "")

            $OsArch = if (-not $CleanedArch.StartsWith("x")) {
                "x$CleanedArch"
            }
            else {
                $CleanedArch
            }
            
            # formating the Build/Os into two different variables and then cleaning it's formatting
            $Os, $Build = $($DriverPacks[$i].OSName).split(",")
            $Os = $($Os -replace $($DriverPacks[$i].Architecture), "").Trim()
            $Build = if ([string]::IsNullOrEmpty($Build)) { "" }else { $($Build).Trim() }
            $SystemName = $($($($($DriverPacks[$i].SystemName) -replace "HP", "") -replace "PC", "") -replace "&amp;", "/").Trim()

            $SystemId = $($DriverPacks[$i].SystemId)

            $h = $HpDrivers.newdataset.hpclientdriverpackcatalog.softpaqlist.softpaq | Where-Object { $_.Id -eq $DriverPacks[$i].SoftPaqId } | Select-Object Version, Url, $($Algorithm)

            $Drivers += ConvertTo-CustomObject -SystemName $SystemName -SystemID $SystemId -Version $($h.Version) -Path $($h.Url) -OsVersion $Os -OsBuild $Build -OsArch $OsArch -Algorithm $Algorithm -Hash $h.$($Algorithm)

            $Percent = [int]$(($i / $($DriverPacks.count)) * 100)
    
            #Write-Progress -Activity "Converting Hp Xml to Object" -Status "$Percent% Complete:" -PercentComplete $Percent
        }
    
        #Write-Progress -Activity "Converting Hp Xml to Object" -Status "100% Complete:" -PercentComplete 100 -Completed

        return @{
            baseLocation = "https://ftp.hp.com/pub/softpaq/"
            version      = $HpDrivers.NewDataSet.HPClientDriverPackCatalog.ToolVersion
            drivers      = $Drivers
        }
    
    }

    function New-LenovoXml {
        param(
            [string]$FilePath,
            [ValidateSet("MD5")]
            [string]$Algorithm,
            [string]$Temp = "C:\Temp"
        )

        [xml]$LenovoDrivers = Get-Content -Path $FilePath -Raw

        $DriverPacks = $LenovoDrivers.ModelList.Model

        $DellDriversObject = @{
            BaseLocation = "https://download.lenovo.com/"
            Version      = "N/A"
        }

        $Drivers = @()

        Write-Progress -Activity "Converting Lenovo Xml to Object" -Status "0% Complete:" -PercentComplete 0 -CurrentOperation "LenovoGenObject"

        $total = $DriverPacks.count

        $i = 1

        $Start_Time = Get-Date

        Start-Sleep 1

        foreach ($DriverPack in $DriverPacks) {
            foreach ($OsBuild in $($DriverPack.SCCM)) {
                $End_Time = Get-Date
                $PackagesPerSecond = $($total / ($i / ($End_Time - $Start_Time).seconds))
                [int]$percent = $i / $total
                
                $OsVersion = "Windows 10"
                $Build = if ($($OsBuild.version) -eq "*") { "" }else { $OsBuild.version }
                $DownloadLink = $($OsBuild.$("#text"))

                $Version = $($DownloadLink.split("_")[-1]).Trim(".exe")


                $Drivers += ConvertTo-CustomObject -SystemName $($DriverPack.name) -SystemID "N/A" -Version $Version -Path $DownloadLink -OsVersion $OsVersion -OsBuild $Build -OsArch $OsArch -Algorithm "N/A" -Hash "N/A" 
            }
            $i++
            Write-Progress -Activity "Converting Lenovo Xml to Object" -Status "$percent% Complete:" -PercentComplete $percent -CurrentOperation "LenovoGenObject" -SecondsRemaining $PackagesPerSecond
        }
        Write-Progress -Activity "Converting Lenovo Xml to Object" -Status "100% Complete:" -Completed -CurrentOperation "LenovoGenObject"
        $DellDriversObject["Drivers"] = $Drivers

        return $DellDriversObject
    }

    function Get-FileHash {
        param(
            [string]$FilePath,
            [string]$Temp = "C:\Temp"
        )


        Start-BitsTransfer -Source $FilePath -Destination $Temp

        $FileName = Split-Path -Path $FilePath -Leaf

        $TempPath = "$Temp\$FileName"

        $Hash = Get-FileHash -LiteralPath $TempPath -Algorithm $Algorithm

        Remove-Item -Path $TempPath

        return $Hash
    }

    function ConvertTo-CustomObject {
        param(
            [string]$SystemName,
            [string]$SystemID = "N/A",
            [string]$Version,
            [string]$Path,
            [string]$OsVersion,
            [string]$OsBuild,
            [string]$OsArch,
            [string]$Algorithm = "N/A",
            [string]$Hash = "N/A"
        )

        return [hashtable]@{
            SystemName     = $SystemName
            SystemID       = $SystemID
            Version        = $Version
            Path           = $Path
            OSBuild        = $(ConvertTo-BuildNumber -OperatingSystem "$OsVersion" -Version "$OsBuild")
            OSArchitecture = $OsArch
            Algorithm      = $Algorithm
            Hash           = $Hash
        }

    }

    function Get-DriverXml {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory)]
            [string]$Source,
            [Parameter(Mandatory)]
            [string]$Destination,
            [string]$Temp = "C:\Temp",
            [switch]$IsCab = $false
        )

        if (([IO.Path]::GetExtension($Source)) -eq ".cab") {
            $IsCab = $true
        }



        $Params = @{
            Source      = $Source
            Destination = if ($IsCab) { $Temp } else { $Destination }
        }

        Write-Verbose "Downloading $Source to $($Params.Destination)"

        $FileName = Split-Path -Leaf $Source

        Start-BitsTransfer @Params

        if ($IsCab) {
            Write-Verbose "Expanding $Temp\$FileName to $Destination"

            Expand "$Temp\$FileName" -F:* "$Destination" -R | Out-Null

            Write-Verbose "Removing $FileName from $Temp"

            Remove-Item "$Temp\$FileName"
        }

        return "$Destination\$($FileName -replace "cab","xml")"
    }
}

PROCESS {
    #-----------------------------------------------------------[Execution]------------------------------------------------------------
    $ManufacturerObjects = @(
        [PsCustomObject]@{
            Name   = "Dell";
            Source = "https://downloads.dell.com/catalog/DriverPackCatalog.cab";
        }
        [PsCustomObject]@{
            Name   = "Hp";
            Source = "https://ftp.hp.com/pub/caps-softpaq/cmit/HPClientDriverPackCatalog.cab";
        }
        [PsCustomObject]@{
            Name   = "Lenovo";
            Source = "https://download.lenovo.com/cdrt/td/catalogv2.xml";
        }
        #@{
        #Name = "Microsoft";
        #Source = "https://raw.githubusercontent.com/maurice-daly/DriverAutomationTool/master/Data/MSProducts.xml"
        #Cab    = $false;
        #}
    )

    #If All Parameter is Used, All Avaliable Manufacturers to $Manufacturers
    if ($All) { 
        foreach ($Man in $ManufacturerObjects.Name) {
            $Manufacturers += $Man
        }
    }

    Write-Verbose "Checking if Xml Temporary Folder Path ($XmlTempFolder) is Vaild."

    if (-not (Test-Path $XmlTempFolder)) {

        Write-Verbose "Creating Xml Temporary Folder Path ($XmlTempFolder)."

        New-Item $XmlTempFolder
    }

    $Total = $($Manufacturers.Count)
    $i = 0

    #Write-Progress -Activity "Generating Xmls for Manufacturers:" -Status "0% Complete" -PercentComplete 0 -CurrentOperation "Generating Xml" -Id 1

    # Iterate through all the provided manufactures to generate the xml
    foreach ($Manufacturer in $Manufacturers) {
        #Write-Progress -Activity "Generating Xmls for Manufacturers:" -Status "$($i/$Total)% Complete" -PercentComplete $($i / $Total) -CurrentOperation "Generating Xml" -Id 1
        
        $ManParams = @{
            Source      = $($ManufacturerObjects | Where-Object { $_.Name -eq $Manufacturer } | Select-Object -ExpandProperty Source);
            Destination = $XmlTempFolder;
        }

        Write-Verbose "Getting Xml for $Manufacturer"

        $CurrentDir = Get-DriverXml @ManParams

        if (-not (Test-Path $CurrentDir)) {
            throw "Failed to extract XML"
            exit
        }

        Write-Verbose "Creating Driver Automation Object for $Manufacturer"

        #Switchs to what Xml Object Creators is Needed Based off Manufacturer
        switch ($Manufacturer) {
            "Dell" {
                Write-Debug "Running New-DellXml with the filepath param of $CurrentDir"
                $Xml = New-DellXml -FilePath $CurrentDir -Algorithm MD5
            }
            "HP" {
                Write-Debug "Running New-HpXml with the filepath param of $CurrentDir"
                $Xml = New-HpXml -FilePath $CurrentDir -Algorithm MD5
            }
            "Lenovo" {
                Write-Debug "Running New-LenovoXml with the filepath param of $CurrentDir"
                $Xml = New-LenovoXml -FilePath $CurrentDir -Algorithm MD5
            }
            default {
                Throw "$_ is an unexpected manufacturer. Please append "
            }
        }

        Write-Verbose "Converting Driver Automation Object to Xml"

        $DaObject = ConvertTo-DaXml -InputObject $Xml  -RootNodeName "ManifestDrivers"

        Write-Verbose "Formatting Xml Object"

        $FormatedDaObject = Format-XML -Xml $DaObject

        Write-Verbose "Writing Xml Object Data to $(Join-Path -Path $Destination -ChildPath "$($Manufacturer)_Products.xml")"

        Out-File -InputObject $FormatedDaObject -FilePath $(Join-Path -Path $Destination -ChildPath "$($Manufacturer)_Products.xml")
    }

    #Write-Progress -Activity "Generating Xmls for Manufacturers:" -Status "100% Complete" -Completed -CurrentOperation "Generating Xml" -Id 1
}

END {

}