function Measure-FolderSize {
    param(
        [string]$Source
    )

    $Files = Get-ChildItem -Path $Source -Recurse

    return $Files | Measure-Object -sum Length | select -ExpandProperty Sum
}