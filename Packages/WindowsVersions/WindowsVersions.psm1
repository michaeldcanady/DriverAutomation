Get-ChildItem (Split-Path $script:MyInvocation.MyCommand.Path) -Filter '*.ps1' -Recurse | ForEach-Object { 
    . $_.FullName 
} 
Get-ChildItem "$(Split-Path $script:MyInvocation.MyCommand.Path)\Public\*" -Filter '*.ps1' -Recurse | ForEach-Object { 
    Export-ModuleMember -Function $_.BaseName
}