#/usr/bin/env bash

_portable_get_real_dirname() {
  if [[ $(uname) == Darwin ]]; then
    # Mac uses BSD readlink which supports different flags

    # relativePath is empty if this is a regular file
    # Otherwise it is a relative path from the link to the real file
    foundPath="$1"
    relativePath="$(readlink "$foundPath")"
    # Keep looping until the file is resolved to a regular file
    while [[ "$relativePath" ]]; do
      # File is a link; follow it
      pushd "$(dirname "$foundPath")" >/dev/null
      pushd "$(dirname "$relativePath")" >/dev/null
      foundPath="$(pwd)/$(basename "$0")"
      popd >/dev/null
      popd >/dev/null
      relativePath="$(readlink "$foundPath")"
    done

    echo "$(dirname "$foundPath")"
  else
    # We are on linux -- Use GNU Readline normally
    echo "$(dirname "$(readlink -f "$(which "$1")")")"
  fi
}

_tap_complete_fn ()
{
  local binary="$1"
  local tapdir="`_portable_get_real_dirname "$binary"`"
  local jqPath="$tapdir/Packages/ShellCompletion/jq"
  local cachePath="$tapdir/.tap-completions.json"

  shift

  _tap_jq()
  {
    # -M: no colors -c: compact (minified)
    "${jqPath}" -M -c "$@"
  }

  if [ ! -x "$jqPath" ]; then 
    # We cannot do anything if jq is not installed. We cannot even give an error.
    # This is probably happening because the plugin is not installed.
    return;
  fi

  if [ ! -f "$cachePath" ]; then
    # if the cache does not exist it should be created
    "${binary}" completion regenerate > /dev/null
  fi


  _buildQuery() {
    local query=""
    for word in "$@";
    do
      if [[ $word == -* ]]; then
        break;
      fi

      if [ ! "$query" = "" ]; then
        query="$query | "
      fi
      query="$query .Completions[] | select(.Name == \"$word\")"
    done
    echo "$query"
  }

  local query="$(_buildQuery $@)"

  local node="$(_tap_jq "$query" "$cachePath")"
  local comp="$(echo "$node" | _tap_jq ".Completions[]")"

  # the previous word on the line
  local args=($@)
  local previousWord="${COMP_WORDS[$(($COMP_CWORD - 1))]}"
  local flagnames=($(echo "$node" | _tap_jq ".FlagCompletions[].ShortName, .FlagCompletions[].LongName" | grep -vx null))

  if [[ "$previousWord" == -* ]]; then
    previousWord="${previousWord#-}"
    previousWord="${previousWord#-}"
    if printf "%s\n" ${flagnames[@]} | grep -x "\"$previousWord\"" > /dev/null; then
      local currentFlag="" # ="$(echo "$node" | _tap_jq "select(.FlagCompletions))"
      # shortname
      local field="LongName"
      if [ "${#previousWord}" = 1 ]; then
        field="ShortName"
      fi
      currentFlag=($(echo "$node" | _tap_jq ".FlagCompletions[] | select(.$field == \"$previousWord\") | .Type, .SuggestedCompletions[] " )"")
      if [ ! "${currentFlag[0]}" = "System.Boolean" ]; then
        for s in "${currentFlag[@]:1}";
        do
          echo "$s"
        done
        return
      fi
    fi
  fi

  for sn in "${flagnames[@]}"
  do
    # eval to strip a single layer of quotes
    eval f=$sn
    if [ ${#f} = 1 ]; then
      echo "-$f"
    else
      echo "--$f"
    fi
  done

  echo "$(echo "$comp" | _tap_jq ".Name")"
}

function _tap_completions()
{
  local relevant="${COMP_WORDS[@]:0:$((COMP_CWORD))}"
  local word="${COMP_WORDS[$COMP_CWORD]}"
  local suggestions=($(compgen -W "$(_tap_complete_fn ${relevant[@]})" -- "$word"))
  COMPREPLY+=("${suggestions[@]}")
}

complete -F _tap_completions tap

