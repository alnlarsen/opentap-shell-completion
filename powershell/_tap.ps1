function GetWordNumber {
    param(
        [string[]] $arguments,
        [int] $cursorPosition
    )
    
    $cnt = 0;
    $i = 0;
    foreach ($arg in $arguments){
        $i = $i + 1
        if (($cnt + $arg.Length + 1) -ge $cursorPosition){
            return $i
        }
        $cnt += $arg.Length
    }
    return $arguments.Length + 1
}

function Complete {
    param(
        [string[]] $arguments,
        [int] $cursorPosition
    )
    $a = $arguments[0]
    $current = GetWordNumber $arguments $cursorPosition
    $location = (Get-Childitem (Get-Command $a).Source).Directory.FullName
    $jsonFile = "$location/.tap-completions.json"

    if (! (Test-Path $jsonFile)) { return }        

    $json = ConvertFrom-Json (Get-Content $jsonFile)

    $i = 0
    $rest = $arguments[1..$arguments.Length]
    foreach ($r in $rest) {
        $i += 1
        if ($i -ge $current) { break; }
            
        $cand = $json.Completions
        foreach ($c in $cand){
            if ($c.Name -eq $r)
            {
                $json = $c
                break;
            }
        }
    }
    $completions = [System.Collections.Generic.List[string]]::new()
    foreach ($comp in $json.Completions){
        $completions.Add($comp.Name)
    }
    foreach ($comp in $json.FlagCompletions){
        $sn = $comp.ShortName
        if (! [String]::IsNullOrWhiteSpace($sn) ) {
            $completions.Add("-$sn")
        }
        $ln = $comp.LongName
        if (! [String]::IsNullOrWhiteSpace($ln) ) {
            $completions.Add("--$ln")
        }            
    }
    return $completions
}

$scriptBlock = {
    param($wordToComplete, $commandAst, $cursorPosition)    

    Complete $commandAst.CommandElements $cursorPosition | 
    Where-Object { $_ -like "$wordToComplete*" } |
    Foreach-Object {         
        $_.Contains(' ') ? "`"$_`" " : "$_ "
    }
}

Register-ArgumentCompleter -Native -CommandName tap -ScriptBlock $scriptBlock
