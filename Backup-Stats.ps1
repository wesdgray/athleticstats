Function Backup-Stats
{
    param(
        $source         = 'V:\2020',
        $destination    = 'S:\Football\Backup',
        $backupInterval = 60
    )
    
    $ProgressBarColorSuccess = 'DarkCyan'
    $ProgressBarColorError = 'Red'
    
    $isPathGood = $(Test-Path -Path $source) -or $(Test-Path -Path $destination)
    
    if ( -not $isPathGood )
    {
        Write-Host "Check source or destination path is reachable! `r`n Source: $source `r`n Destination: $destination"
        return
    }
    
    while($true) 
    {
        robocopy $source $destination * /mir | Write-Output
        
        for( $i=0; $i -lt $backupInterval; $i++)
        {
            if ($LASTEXITCODE -ge 8) 
            {
                $host.privatedata.ProgressBackgroundColor = $ProgressBarColorError
                $status = 'BAD'
            }
            else
            {
                $host.privatedata.ProgressBackgroundColor = $ProgressBarColorSuccess
                $status = 'GOOD'
            }
            
            Write-Progress -Activity "Robocopy from $source to $destination"`
                           -Status "Status: $status; Time until next backup..."`
                           -PercentComplete $( 100 * ($i / $backupInterval) )`
                           -SecondsRemaining $( $backupInterval - $i )
            
            Start-Sleep -Seconds 1
        }
    }
}
