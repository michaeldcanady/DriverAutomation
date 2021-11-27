function Start-DaProgress{
    param(
        [Parameter(Mandatory,ParameterSetName="All")]
        [Parameter(Mandatory,ParameterSetName="Specific")]
        [switch]$BitsTransfer,
        [Parameter(Mandatory,ParameterSetName="Specific")]
        [guid[]]$JobIDs,
        [Parameter(Mandatory,ParameterSetName="All")]
        [switch]$All,
        [Parameter(ParameterSetName="All")]
        [Parameter(ParameterSetName="Specific")]
        [switch]$HideProgress
    )

    function Get-Jobs {
        if ($JobIDs.count -gt 0) {
            return Get-BitsTransfer | ? {$_.JobID -in $JobIDs}
        } else {
            return Get-BitsTransfer
        }
    }

    while ((Get-Jobs | ? { $_.JobState -eq "Connecting" }).Count -gt 0) {
        Write-Host "Waiting for Transfer to Connect"
        Start-Sleep 1
    }
    
    while ((Get-Jobs | ? { $_.JobState -eq "Transferring" }).Count -gt 0) {     
        $totalbytes=0;    
        $bytestransferred=0; 
        $timeTaken = 0;    
        foreach ($job in (Get-Jobs | ? { $_.JobState -eq "Transferring" } | Sort-Object CreationTime)) {         
            $totalbytes += $job.BytesTotal;         
            $bytestransferred += $job.bytestransferred     
            if ($timeTaken -eq 0) { 
                #Get the time of the oldest transfer aka the one that started first
                $timeTaken = ((Get-Date) - $job.CreationTime).TotalMinutes 
            }
        }    
        #TimeRemaining = (TotalFileSize - BytesDownloaded) * TimeElapsed/BytesDownloaded
        if ($totalbytes -gt 0) {        
            [int]$timeLeft = ($totalBytes - $bytestransferred) * ($timeTaken / $bytestransferred)
            [int]$pctComplete = $(($bytestransferred*100)/$totalbytes);     
            if(-not $HideProgress){
                Write-Progress -Status "Transferring $bytestransferred of $totalbytes ($pctComplete%). $timeLeft minutes remaining." -Activity "Dowloading files" -PercentComplete $pctComplete  
            } else {
                Write-Host "Transferring $bytestransferred of $totalbytes ($pctComplete%). $timeLeft minutes remaining."
            }
        }
    }
    
    if((Get-Jobs | ? { $_.JobState -eq "Transferred" }).Count -gt 0){
        foreach ($job in (Get-Jobs | ? { $_.JobState -eq "Transferred" } | Sort-Object CreationTime)){
            $Name = $job.DisplayName
            $job | Complete-BitsTransfer
            write-host "$Name has finished downloading"
        }
    }

}