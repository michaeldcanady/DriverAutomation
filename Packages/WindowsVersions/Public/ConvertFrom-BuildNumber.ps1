function ConvertFrom-BuildNumber {
    param(
        [string]$BuildNumber
    )

    if ($OperatingSystem -like "*PE*") {
        return $global:OperationSystemBuilds | Where-Object { $_.PeBuild -eq $BuildNumber } | Select-Object -ExpandProperty PeVersion
    }
    else {
        return $global:OperationSystemBuilds | Where-Object { $_.Build -eq "$BuildNumber" } | Select-Object -ExpandProperty Version
    }
}