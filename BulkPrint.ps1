# This requires PDFtoPrinter.exe

$Copiers = `
@{
    'CFP Left Copier'   = '192.168.102.14';
    'CFP Middle Copier' = '192.168.102.15';
    'CFP Right Copier'  = '192.168.102.16';
    #'CFP SW Press Box'  = '192.168.102.11';
    'CFP Photo Room'    = '192.168.102.18';
}

Function New-BulkPrinters($Copiers)
{
    foreach( $kv in $Copiers.GetEnumerator() )
    {
        New-CustomPrinter -Name $kv.Key -IP $kv.Value
    }
}

Function New-CustomPrinter
{
    param(
        $Name,
        $IP,
        $Driver='Xerox WorkCentre 7500 Series Class Driver'
    )

    Add-PrinterPort -Name $Name -PrinterHostAddress $IP 
    Add-Printer -Name $Name -PortName $Name -DriverName $Driver -Shared -ShareName $Name
    Set-PrintConfiguration -DuplexingMode OneSided -PrinterName $Name
}

Function Remove-AllCustomPrinter($Name)
{
    $CustomPrinter = Get-Printer $Name
    Write-Host "$CustomPrinter"
    
    $Choice = Read-Host -Prompt "Removing the above printers push y to continue"
    if($Choice -eq 'y')
    {
        foreach( $printer in $CustomPrinter )
        {
            $portName = $printer.PortName
            Remove-Printer -InputObject $printer
            Remove-PrinterPort -Name $portName
        }
    }
}

$path = 'P:\'
Function Invoke-PrintQueue
{
    param(
        $path,
        $printers = $Copiers.Keys
    )
    $files = Get-ChildItem $path | Select-Object -ExpandProperty FullName
    foreach($file in $files)
    {
        Invoke-BroadcastPrint -printers $printers -file $files
    }

    Remove-Item $files
}

Function Invoke-BroadcastPrint
{
    param(
        [string[]]$printers,
        $file,
        $exe = 'C:\bin\PDFtoPrinter.exe'
    )

    if($printers -and $file)
    {
        foreach($printer in $printers)
        {
            "$exe `"$file`" `"$printer`""
            Invoke-Expression "$exe `"$file`" `"$printer`""
            Start-Sleep -Seconds 3
            
        }
    }
}
$AcroRd32 = "'C:\Program Files (x86)\Adobe\Acrobat Reader DC\Reader\AcroRd32.exe'"

Function Invoke-PrintQueueMonitor
{
    param(
        $path='.\',
        $sleepTime=5
    )

    while($true)
    {
        if(Get-ChildItem $path)
        {
            Write-Progress -Activity "Found Files, Printing now..."
            Invoke-PrintQueue -path $path
        }
        else
        {
            Write-Progress -Activity "No files found at $path, sleeping $sleepTime seconds"
        }
        Start-Sleep -Seconds $sleepTime
    }

}
