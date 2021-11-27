function ConvertFrom-BuildNumber {
    param(
        [string]$BuildNumber
    )

    return $OperationSystemBuilds | Where-Object {$_.Build -eq "$BuildNumber"} | Select-Object Version
}