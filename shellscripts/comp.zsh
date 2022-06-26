#compdef tap

function trace(){
  local nicecounter=0
  local line
  for line in "${(@f)@}"
  do 
    echo "$nicecounter: $line" >> $HOME/tapcomp.log
    nicecounter=$((nicecounter + 1))
  done
}

_tap_subcommands(){
  local binary="$words[1]"
  local tapdir="$(dirname "$(readlink -f "$(which "$binary")")")"
  local scriptPath="$tapdir/Packages/ShellCompletion/completer.py"

  if ! test -f "$scriptPath"; then
    # plugin is not installed. fail quickly
    return
  fi

  trace "binary = $binary"
  trace "tapdir = $tapdir"

  local line
  local context
  trace "context = $contex"
  # hack to populate line
  _arguments '*::arg:->args'
  local -a array_of_lines
  array_of_lines=("${(@f)$(python "$scriptPath" "$tapdir" zsh $line)}")
  trace "${(@f)array_of_lines}"
  _describe 'command' array_of_lines 
  
}
_tap(){
  # always suggest files 
  _alternative "files:complete files:_files"
  _arguments '*:args:_tap_subcommands'
}

