$global:OperationSystemBuilds = @(
    [PSCustomObject]@{
        PeBuild   = "N/A";
        PeVersion = "N/A";
        Version   = "Windows 11";
        Build     = "10.0.22000";
    }
    [PSCustomObject]@{
        PeBuild   = "N/A";
        PeVersion = "N/A";
        Version   = "Windows 10 21H2";
        Build     = "10.0.19044";
    }
    [PSCustomObject]@{
        PeBuild   = "N/A";
        PeVersion = "N/A";
        Version   = "Windows 10 21H1";
        Build     = "10.0.19043";
    }
    [PSCustomObject]@{
        PeBuild   = "N/A";
        PeVersion = "N/A";
        Version   = "Windows 10 20H2";
        Build     = "10.0.19042";
    }
    [PSCustomObject]@{
        PeBuild   = "N/A";
        PeVersion = "N/A";
        Version   = "Windows 10 20H1";
        Build     = "10.0.19041";
    }
    [PSCustomObject]@{
        PeBuild   = "N/A";
        PeVersion = "N/A";
        Version   = "Windows 10 1909";
        Build     = "10.0.18363";
    }
    [PSCustomObject]@{
        PeBuild   = "N/A";
        PeVersion = "N/A";
        Version   = "Windows 10 1903";
        Build     = "10.0.18362";
    }
    [PSCustomObject]@{
        PeBuild   = "N/A";
        PeVersion = "N/A";
        Version   = "Windows 10 1809";
        Build     = "10.0.17763";
    }
    [PSCustomObject]@{
        PeBuild   = "N/A";
        PeVersion = "N/A";
        Version   = "Windows 10 1803";
        Build     = "10.0.17134";
    }
    [PSCustomObject]@{
        PeBuild   = "N/A";
        PeVersion = "N/A";
        Version   = "Windows 10 1709";
        Build     = "10.0.16299";
    }
    [PSCustomObject]@{
        PeBuild   = "N/A";
        PeVersion = "N/A";
        Version   = "Windows 10 1703";
        Build     = "10.0.15063";
    }
    [PSCustomObject]@{
        PeBuild   = "N/A";
        PeVersion = "N/A";
        Version   = "Windows 10 1607";
        Build     = "10.0.14393";
    }
    [PSCustomObject]@{
        PeBuild   = "N/A";
        PeVersion = "N/A";
        Version   = "Windows 10 1511";
        Build     = "10.0.10586";
    }
    [PSCustomObject]@{
        PeBuild   = "N/A";
        PeVersion = "N/A";
        Version   = "Windows 10";
        Build     = "10.0.10240";
    }
    [PSCustomObject]@{
        PeBuild   = "N/A";
        PeVersion = "N/A";
        Version   = "Windows 8.1 Update 1";
        Build     = "6.3.9600";
    }
    [PSCustomObject]@{
        PeBuild   = "6.3.9200 PE";
        PeVersion = "Windows PE 5.0";
        Version   = "Windows 8.1";
        Build     = "6.3.9200";
    }
    [PSCustomObject]@{
        PeBuild   = "N/A";
        PeVersion = "N/A";
        Version   = "Windows 8";
        Build     = "6.2.9200";
    }
    [PSCustomObject]@{
        PeBuild   = "N/A";
        PeVersion = "N/A";
        Version   = "Windows 7 SP1";
        Build     = "6.1.7601";
    }
    [PSCustomObject]@{
        Version   = "Windows 7";
        PeVersion = "Windows PE 3.0";
        PeBuild   = "6.1.7600 PE";
        Build     = "6.1.7600";
    }
    [PSCustomObject]@{
        PeBuild   = "N/A";
        PeVersion = "N/A";
        Version   = "Windows Vista SP2";
        Build     = "6.0.6002";
    }
    [PSCustomObject]@{
        PeBuild   = "N/A";
        PeVersion = "N/A";
        Version   = "Windows Vista SP1";
        Build     = "6.0.6001";
    }
    [PSCustomObject]@{
        PeBuild   = "N/A";
        PeVersion = "N/A";
        Version   = "Windows Vista";
        Build     = "6.0.6000";
    }
    [PSCustomObject]@{
        PeBuild   = "N/A";
        PeVersion = "N/A";
        Version   = "Windows XP";
        Build     = "5.1.2600";
    }
)

function ConvertFrom-BuildNumber {
    param(
        [string]$BuildNumber
    )

    #$BuildNumber

    #Write-Output $($global:OperationSystemBuilds)

    return $global:OperationSystemBuilds | Where-Object { $_.Build -eq "$BuildNumber" } | Select-Object -ExpandProperty Version
}