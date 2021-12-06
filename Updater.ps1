
$NormalizedScriptVersion = New-Object System.Version((Test-ScriptFileInfo -Path $PSCommandPath).version)

function Update-DriverAutomation {
    param(
        $NormalizedScriptVersion,
        $Temp = "C:\Temp"
    )

    $Params = @{
        Method = "Get"
        Uri    = "https://api.github.com/repos/michaeldcanady/DriverAutomation/releases/latest"
    }
    
    #Need name, published_at, prerelease, tag_name, zipball_url, draft, body, url
    $LatestVersion = Invoke-RestMethod @Params | Select-Object name, published_at, prerelease, tag_name, assets, draft, body, @{N = "url"; E = { $_.assets.browser_download_url } }, @{N = "Author"; E = { $_.author.login } }
    
    $NormalizedLatestVersion = New-Object System.Version($LatestVersion.tag_name)
    
    if ($NormalizedScriptVersion -ge $NormalizedLatestVersion) {
        return $false
    }

    Write-Host "New version: [$NormalizedLatestVersion] found. Current: [$NormalizedScriptVersion]"

    $title = 'Update Confirmation'
    $question = 'Would you like to install it?'
    $choices = '&Yes', '&No'

    $decision = $Host.UI.PromptForChoice($title, $question, $choices, 1)

    if ($decision -ne 0) {
        return $false
    }

    try {
        Write-Verbose "Downloading Version [$NormalizedLatestVersion]..."

        $DestFile = ($LatestVersion.zipball_url).split("/")[-1]
        $DestPath = "$Temp\$DestFile"

        Start-BitsTransfer -Source $LatestVersion.url

        $DriverAutomation = "$psscriptroot\DriverAutomationTool.exe"
        $DriverAutomationOld = "$psscriptroot\DriverAutomationTool.exe.old"

        Write-Verbose "Renaming $DriverAutomation to $DriverAutomationOld"

        Rename-Item -LiteralPath "$DriverAutomation" -NewName "$DriverAutomationOld"

        Write-Verbose "Copying $DestPath to $psscriptroot"

        Copy-Item -Path $DestPath -Destination $psscriptroot

        Write-Verbose "Removing $DriverAutomationOld"

        Remove-Item -Path $DriverAutomationOld

        Write-Verbose "Successfully updated Driver Automation"
    }
    catch {
        $UpdateError = $_.Exception.Message
        Write-Error $UpdateError

        if (Test-Path $DestPath) {
            Write-Verbose "Removing $DestPath"
            Remove-Item $DestPath
        }

        if (!(Test-Path $DriverAutomation) -and (Test-Path $DriverAutomationOld)) {
            Write-Verbose "Renaming $DriverAutomationOld to $DriverAutomation"
            Rename-Item -Path $DriverAutomationOld -NewName $DriverAutomation
        }

        return $false
    }
    
    return $true
}