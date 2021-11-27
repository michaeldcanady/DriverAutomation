import-module $env:SMS_ADMIN_UI_PATH.Replace("bin\i386", "bin\ConfigurationManager.psd1") -force
function Get-DriverPackageStatus {
    param(
        [string]$SiteCode,
        [string]$PackageId
    )

    Push-Location

    Set-Location "$SiteCode`:"

    $Status = Get-CMDistributionStatus -Id $PackageId

    While ($Status.NumberInProgress -gt 0) {
        Write-Host "Waiting for Application to finish distributing..."
        Start-Sleep 1
    }

    if ($Status.NumberErrors -eq 1) {
        Write-Host -ForegroundColor Red "Failed to Distributed Package"
    }
    elseif ($Status.Success -eq 1) {
        Write-Host -ForegroundColor Green "Successfully Distributed Package"
    }

    Pop-Location
}