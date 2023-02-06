Param(
  [int]$verbose = 1
)

#TypeAssurance
$signature = @"
[DllImport("user32.dll", CharSet=CharSet.Auto, ExactSpelling=true)]
public static extern short GetAsyncKeyState(int virtualKeyCode);
"@
$getKeyState = Add-Type -memberDefinition $signature -name "Newtype" -namespace newnamespace -passThru
$check = 0
$cnt = 0

[string]$word = ""
[string]$target = "CHOCOB"

[int]$max_length = 10 + $target.Length
$target = $target.ToUpperInvariant()
$vkey_prec = "#"

if($verbose -gt 0){ Write-Output "target = $target" }

while ($true)
{
    Start-Sleep -Milliseconds 40
    $logged = ""
    $result=""
    $shift_state=""
    $caps_state=""
    for ([int]$char=1;$char -le 254;$char++)
    {
        $vkey = $char
        $logged = $getKeyState::GetAsyncKeyState($vkey)
        if (($logged -eq -32767) -and ($vkey -ge 65) -and ($vkey -le 90) -and($vkey -ne $vkey_prec))
        {
            #Write-Output "code : $vkey"
            #[string]$ascii_char = [char]$vkey

            $vkey_prec = $vkey

            $word = $word + [char]$vkey
            if($word.Length -gt $max_length){ $word = $word.Substring($word.Length - $max_length) }

            if($verbose -gt 0){ Write-Output "$word" }

            if($word.Contains($target))
            {
                Write-Output "target detected !"
                $word = ""
                if($word.Length -eq 0){ rundll32.exe user32.dll,LockWorkStation }
            }
        }
    }
    
    $cnt++
    if($cnt -gt 25){
        $inputString = Get-Clipboard;
        foreach ($line in $inputString)
        {
            $line = $line.Replace(" ", "").ToUpperInvariant()
            if($line.Contains($target))
            {
                Write-Output "target detected in clipboard !"
                Set-Clipboard -Value "..."
                $cnt_down=150

            }
        }
        $cnt = 0
    }

    if($cnt_down -gt 0){
        if($cnt_down % 5 -eq 0){ Set-Clipboard -Value "$cnt_down" }
        $cnt_down--
     }

}