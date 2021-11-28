function ConvertTo-BuildNumber {
    param(
        [string]$OperatingSystem,
        [string]$Version
    )

    if ($OperatingSystem -like "*PE*") {
        return $global:OperationSystemBuilds | Where-Object { $_.PeVersion -eq $OperatingSystem } | Select-Object -ExpandProperty PeBuild
    }
    else {
        $Joined = "$OperatingSystem $Version".Trim()
        return $global:OperationSystemBuilds | Where-Object { $_.Version -eq $Joined } | Select-Object -ExpandProperty Build
    }
}