function Find-OsVersion {
    param(
        [string]$OsBuild
    )

    return $global:OperationSystemBuilds | Where-Object { $_.Version -like "*$OsBuild" } | Select-Object -ExpandProperty Version
}