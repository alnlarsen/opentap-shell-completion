function Complete {
    param(
        [string[]] $arguments
    )
    $a = $arguments[0]
    $location = (Get-Childitem (Get-Command $a).Source).Directory.FullName
    $jsonFile = "$location/.tap-completions.json"

    if (! (Test-Path $jsonFile)) { return }        

    $json = ConvertFrom-Json (Get-Content $jsonFile)

    $rest = $arguments[1..$arguments.Length]
    foreach ($r in $rest) {
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

    Complete $commandAst.CommandElements | 
    Where-Object { $_ -like "$wordToComplete*" } |
    Foreach-Object {         
        $_.Contains(' ') ? "`"$_`" " : "$_ "
    }
}

$env:PATH = ";C:\Users\allarsen\submarine\tap-shell-completion\bin\Debug;$($env:PATH);"
Register-ArgumentCompleter -Native -CommandName tap -ScriptBlock $scriptBlock
Set-PSReadLineOption -EditMode Emacs