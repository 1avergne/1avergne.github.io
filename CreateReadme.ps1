function subSection {
    param([string]$dir
    , [int]$level)

    Write-Host $dir
    $tdir = $dir.Split("\")
    $("#" * $level) + " " + $dir.Substring(1 + $dir.LastIndexOf("\")) >> $destFile 

    $d = Get-ChildItem $dir | Sort-Object -Descending LastWriteTime

    foreach($f in $d){
        if($f.Name.ToString() -ne "APublier")
        {
            $path = $dir.ToString() + "\" + $f.Name
        
            if($f.PSIsContainer)
            {
                subSection  -dir $path -level $($level + 1)
            }
            else
            {
                $title = Get-Content $path -Encoding utf8 | select -first 1
                $line = "- [" + $title.TrimStart("#").TrimStart() + "](" + $path.Replace(".md", ".html") + ")"
                $line >> $destFile 
            }
        }
    }

}


$destFile = "README.md"

Get-Content "homepage.md" -Encoding utf8 > $destFile 

subSection -dir ".\Articles" -level 1
