try {
    import-module $env:SMS_ADMIN_UI_PATH.Replace("bin\i386", "bin\ConfigurationManager.psd1") -force
}
catch {

}

Get-ChildItem (Split-Path $script:MyInvocation.MyCommand.Path) -Filter '*.ps1' -Recurse | ForEach-Object { 
    . $_.FullName 
} 
Get-ChildItem "$(Split-Path $script:MyInvocation.MyCommand.Path)\Public\*" -Filter '*.ps1' -Recurse | ForEach-Object { 
    Export-ModuleMember -Function $_.BaseName
}