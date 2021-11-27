$global:OperationSystemBuilds = @(
    [PSCustomObject]@{
        Version = "Windows 11 21H2"
        Build = "10.0.22000"
    }
    [PSCustomObject]@{
        Version = "Windows 10 21H2"
        Build = "10.0.19044"
    }
    [PSCustomObject]@{
        Version = "Windows 10 21H1"
        Build = "10.0.19043"
    }
    [PSCustomObject]@{
        Version = "Windows 10 20H2"
        Build = "10.0.19042"
    }
    [PSCustomObject]@{
        Version = "Windows 10 20H1"
        Build = "10.0.19041"
    }
    [PSCustomObject]@{
        Version = "Windows 10 1909"
        Build = "10.0.18363"
    }
    [PSCustomObject]@{
        Version = "Windows 10 1903"
        Build = "10.0.18362"
    }
    [PSCustomObject]@{
        Version = "Windows 10 1809"
        Build = "10.0.17763"
    }
    [PSCustomObject]@{
        Version = "Windows 10 1803"
        Build = "10.0.17134"
    }
    [PSCustomObject]@{
        Version = "Windows 10 1709"
        Build = "10.0.16299"
    }
    [PSCustomObject]@{
        Version = "Windows 10 1703"
        Build = "10.0.15063"
    }
    [PSCustomObject]@{
        Version = "Windows 10 1607"
        Build = "10.0.14393"
    }
    [PSCustomObject]@{
        Version = "Windows 10 1511"
        Build = "10.0.10586"
    }
    [PSCustomObject]@{
        Version = "Windows 10"
        Build = "10.0.10240"
    }
)

function ConvertTo-BuildNumber {
    param(
        [string]$OperatingSystem,
        [string]$Version
    )

    return $global:OperationSystemBuilds | Where-Object {$_.Version -eq "$OperatingSystem $Version"} | Select-Object -ExpandProperty Build
}