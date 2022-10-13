[int]$delay = 5
[string]$char = "z";


Write-Output "$char typed each $delay sec";

while($delay -gt 0)
{
  Start-Sleep -Seconds $delay;


Write-Output "$char typed !";

    [System.Windows.Forms.SendKeys]::SendWait($char);

}

#thx: https://blogs.msdn.microsoft.com/timid/2014/08/05/send-keys/
