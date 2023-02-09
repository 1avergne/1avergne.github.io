function subSection {
    param([string]$dir
    , [int]$level)

    Write-Host $dir
    "`n" + $("#" * $level) + " " + $dir.Substring(1 + $dir.LastIndexOf("\")) | out-file $destFile -Append -Encoding utf8

    if($level -le 1){
        $d = Get-ChildItem $dir | Sort-Object -Descending LastWriteTime    #tri par ordre de dernière modification
    }else{
        $d = Get-ChildItem $dir | Sort-Object -Descending Name    #tri par ordre alpha
    }
    

    foreach($f in $d){
        if($f.Name.ToString() -ne "APublier")
        {
            $path = $dir.ToString() + "\" + $f.Name
        
            if($f.PSIsContainer)
            {
                subSection -dir $path -level $($level + 1)
            }
            else
            {
                $title = Get-Content $path -Encoding utf8 | Select-Object -first 1
                $line = "- [" + $title.TrimStart("#").TrimStart() + "](" + $path.Replace("\", "/").Replace(".md", ".html") + ")"
                $line | out-file $destFile -Append -Encoding utf8
            }
        }
    }

}


$destFile = "README.md"

Get-Content "homepage.md" | out-file $destFile -Encoding default

subSection -dir ".\Articles" -level 1
