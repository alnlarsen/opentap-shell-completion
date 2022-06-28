function Complete {
    param(
        [string[]] $arguments,
        [int] $cursorPosition,
        [string] $wordToComplete
    )
    $a = $arguments[0]
    $location = (Get-Childitem (Get-Command $a).Source).Directory.FullName
    $packageXml = "$location/Packages/ShellCompletion/package.xml"
    $jsonFile = "$location/.tap-completions.json"

    if (! (Test-Path $packageXml)) { return }        
    if (! (Test-Path $jsonFile)) {
        & "$location/tap" completion regenerate | Out-Null
    }

    $json = ConvertFrom-Json (Get-Content $jsonFile)

    $i = 0
    $idx = $arguments.IndexOf($wordToComplete)
    if ($idx -eq -1) { $idx = $arguments.Count }
    $rest = $arguments[1..$arguments.Count + 1]
    foreach ($r in $rest) {        
        if ($i -gt $idx) { break; }
        $i += 1
            
        $cand = $json.Completions
        foreach ($c in $cand) {
            if ($c.Name -eq $r) {
                $json = $c
                break;
            }
        }
    }
    
    $prev = $idx - 1
    $previousWord = $null
    if ($prev -ge 0 -and $prev -lt $arguments.Count) {
        $previousWord = $arguments[$prev]
    }

    $completions = [System.Collections.Generic.List[string]]::new()

    if ($previousWord -and $previousWord.StartsWith("-")) {
        foreach ($f in $json.FlagCompletions) {
            if ("-$($f.ShortName)" -eq $previousWord -or "--$($f.LongName)" -eq $previousWord) {
                if ($f.Type -eq "System.Boolean") {
                    break;
                }

                if ($f.SuggestedCompletions) {
                    foreach ($s in $f.SuggestedCompletions) {
                        $completions.Add($s)
                    }
                }
                return $completions;
            }
        }
    }    
    
    foreach ($comp in $json.Completions) {
        $completions.Add($comp.Name)
    }

    foreach ($comp in $json.FlagCompletions) {
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

    Complete $commandAst.CommandElements $cursorPosition $wordToComplete | 
    Where-Object { $_ -like "$wordToComplete*" } |
    Foreach-Object {         
        $_.Contains(' ') ? "`"$_`" " : "$_ "
    }
}

Register-ArgumentCompleter -Native -CommandName tap -ScriptBlock $scriptBlock