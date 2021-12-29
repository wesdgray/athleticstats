# This requires PDFtoPrinter.exe
# RB 
$Copiers = `
@{
    'Media Tent'    = '10.1.1.223';
    'South Press 1' = '10.1.1.215';
    'South Press 2' = '10.1.1.216';
    'North Press 1' = '10.1.1.217';
    'North Press 2' = '10.1.1.218';
}

$DriverPath = 'C:\users\WesGray\Downloads\WHQL Universal Print Driver_64bit'
$DriverFile = 'sfweMENU.inf'
$DriverName = 'SHARP UD2 PCL6'

Function Add-BulkPrinterDriver($DriverPath, $DriverFile, $DriverName)
{
    if (pnputil.exe /enum-drivers | select-string $DriverFile -Quiet) 
    { 
        Write-Host "Driver $DriverFile is already installed to DriverStore"
    }
    else 
    {
        pnputil /a "$DriverPath\$DriverFile"
    }
    
    if (Get-PrinterDriver -Name $DriverName)
    {
        Write-Host "Driver $DriverName has already been added as a Printer Driver"
    }
    else
    {
        Add-PrinterDriver -Name $DriverName
    }
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