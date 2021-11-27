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
    [ValidateScript({
            foreach ($Man in $_) {
                if ($Man -in $($ManufacturerObjects.Name)) {
                    return $true
                }
            }
            throw "$_ is not valid, please use: $($ManufacturerObjects.Name)"
        })]
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
    [string]$XmlTempFolder = "C:\Git\DriverAutomation\xml\Temp",
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
            [string]$FilePath
        )

        [xml]$DellDrivers = Get-Content -Path $FilePath -Raw

        $DriverPacks = $DellDrivers.driverpackmanifest.driverpackage

        $BasePath = "https://" + $($DellDrivers.DriverPackManifest.baseLocation)

        $Drivers = @()

        foreach ($DriverPack in $DriverPacks) {

            $SystemName = $($DriverPack.SupportedSystems.Brand.Model.name)
            $OsArch = $($DriverPack.SupportedOperatingSystems.OperatingSystem.osArch)
            $SystemID = $DriverPack.SupportedSystems.Brand.Model.SystemID

            $Hash = $DriverPack.Cryptography.Hash | ? { $_.algorithm -eq "MD5" }

            $drive = [hashtable]@{
                SystemName = $(if ((-not [string]::IsNullOrEmpty($SystemName)) -and ($SystemName.GetType() -eq [object[]]) -and ($OsArch.GetType() -ne [object[]])) { $SystemName[0] }else { $SystemName })
                SystemID   = if ((-not [string]::IsNullOrEmpty($SystemName)) -and ($SystemID.GetType() -eq [object[]])) { $SystemID[1] }else { $SystemID }
                Version    = $DriverPack.dellVersion
                Path       = $("$BasePath/$($DriverPack.Path)")
                OsBuilds   = ""
                Algorithm  = $Hash.algorithm
                Hash       = $Hash.$("#text")
            }

            if ($OsArch.GetType() -eq [object[]]) {
                for ($i = 0; $i -lt $OsArch.count; $i++) {
                    $drive1 = $drive.PsObject.Copy()
                    $drive1["OSArchitecture"] = $OsArch[$i]
                    $drive1["OSVersion"] = $($DriverPack.SupportedOperatingSystems.OperatingSystem.Display.$("#cdata-section")[$i] -replace $($drive1.OSArchitecture), "").Trim()
                    $Drivers += $drive1
                }
            }
            else {
                $drive["OSArchitecture"] = $OsArch
                $drive["OSVersion"] = $($DriverPack.SupportedOperatingSystems.OperatingSystem.Display.$("#cdata-section") -replace $($drive.OSArchitecture), "").Trim()
                $Drivers += $drive
            }
        }

        return @{
            baseLocation = $BasePath
            version      = $DellDrivers.DriverPackManifest.version
            drivers      = $Drivers
        }

    }

    function New-HpXml {
        param(
            [string]$FilePath,
            [string]$Algorithm = "MD5"
        )
    
        [xml]$HpDrivers = Get-Content -Path $FilePath
    
        $DriverPacks = $HpDrivers.NewDataSet.HPClientDriverPackCatalog.ProductOSDriverPackList.ProductOSDriverPack
    
        $Drivers = @()
    
        for ($i = 0; $i -lt $DriverPacks.count; $i++) {
    
            $Os, $Build = $($DriverPacks[$i].OSName).split(",")

            $h = $HpDrivers.newdataset.hpclientdriverpackcatalog.softpaqlist.softpaq | ? { $_.Id -eq $DriverPacks[$i].SoftPaqId } | select Version, Url, $($Algorithm)
    
            $Drivers += [hashtable]@{
                SystemName     = $DriverPacks[$i].SystemName
                SystemID       = $DriverPacks[$i].SystemId
                Algorithm      = $Algorithm
                Version        = $h.Version
                Url            = $h.Url
                Hash           = $h.$($Algorithm)
                OSVersion      = $($Os -replace $($DriverPacks[$i].Architecture), "").Trim()
                OsBuilds       = if ([string]::IsNullOrEmpty($Build)) { "" }else { $($Build).Trim() }
                OSArchitecture = "x" + $($DriverPacks[$i].Architecture -replace "-Bit", "")
            }
    
            $Percent = [int]$(($i / $($DriverPacks.count)) * 100)
    
            Write-Progress -Activity "Converting Hp Xml to Object" -Status "$Percent% Complete:" -PercentComplete $Percent
        }
    
        Write-Progress -Activity "Converting Hp Xml to Object" -Status "100% Complete:" -PercentComplete 100 -Completed
    
        return @{
            baseLocation = "https://ftp.hp.com/pub/softpaq/"
            version      = $HpDrivers.NewDataSet.HPClientDriverPackCatalog.ToolVersion
            drivers      = $Drivers
        }
    
    }

    function New-LenovoXml {
        param(
            [string]$FilePath
        )

        [xml]$LenovoDrivers = Get-Content -Path $FilePath -Raw

        $DriverPacks = $LenovoDrivers.ModelList.Model

        $Drivers = @()

        $BasePath = "https://download.lenovo.com/"

        foreach ($DriverPack in $DriverPacks) {

            foreach ($Version in $($DriverPack.SCCM.Version)) {
            
                foreach ($DowloadLink in $DriverPack.SCCM.$("#text")) {
                    $Info = $($DowloadLink.split("_"))
                    if ($Version -in $Info) {
                        if (("win1064" -in $Info) -or "w1064" -in $Info) {
                            $OsVersion = "Windows 10"
                            $OsArchitecture = "64"
                        }
                        $Drivers += [hashtable]@{
                            SystemName     = $DriverPack.name
                            SystemID       = "N/A"
                            Version        = $($Info[-1]).Trim(".exe")
                            Path           = $DowloadLink
                            OSBuild        = $(ConvertTo-BuildNumber -OperatingSystem "$OsVersion" -Version "$Version")
                            OSArchitecture = "x" + $OsArchitecture
                            Algorithm      = "N/A"
                            Hash           = "N/A"
                        }
                    }
                }
            }
        }
        return @{
            baseLocation = $BasePath
            version      = "N/A"
            drivers      = $Drivers
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

    # Iterate through all the provided manufactures to generate the xml
    foreach ($Manufacturer in $Manufacturers) {
        
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
                $Xml = New-DellXml -FilePath $CurrentDir
            }
            "HP" {
                Write-Debug "Running New-HpXml with the filepath param of $CurrentDir"
                $Xml = New-HpXml -FilePath $CurrentDir
            }
            "Lenovo" {
                Write-Debug "Running New-LenovoXml with the filepath param of $CurrentDir"
                $Xml = New-LenovoXml -FilePath $CurrentDir
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
}

END {

}