Param(
  [int]$delay = 5
)
#[int]$delay = 5
 
$inputString = Get-Clipboard;
if($inputString -is "string")
{
    $previewString = $inputString
}
else
{
    $previewString = $inputString[0];
}
if($previewString.Length -gt 33)
{
    $previewString = $previewString.Substring(0,30) + " ...";
}
 
if($delay -gt 1)
{
    Write-Output "Typing ""$previewString"" starts in $delay seconds";
    #Start-Sleep -Seconds $delay
     
    while($delay -gt 0)
    {
        Start-Sleep -Seconds 1;
        $delay -= 1;
        Write-Output "$delay ...";
    }
}
 
$inputString = Get-Clipboard;
$Milliseconds = 0;
foreach ($line in $inputString)
{
    foreach ($char in [char[]]$line)
    {
        if ($char -match "[\+\^\%\~\(\)\{\}\[\]]")
        {
            [string]$char = "{$char}";
 
        } # if ($char -match "...
 
        [System.Windows.Forms.SendKeys]::SendWait($char);
        if($Milliseconds -gt 0)
        {
            Start-Sleep -Milliseconds $Milliseconds;
        }
        $i += 1;
                 
    } # foreach ($char in [char[]]$line)
             
    [System.Windows.Forms.SendKeys]::SendWait("{ENTER}");
    $i += 1;
 
} # foreach ($line in $inputString)$inputString = Get-Clipboard
#thx: https://blogs.msdn.microsoft.com/timid/2014/08/05/send-keys/