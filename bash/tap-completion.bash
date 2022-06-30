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

_tap_complete_fn () {
  if [ ! -x "$1" ]; then
    # fail fast when $1 is not an executable
    return;
  fi

  local binary="$1"
  local tapdir="`_portable_get_real_dirname "$binary"`"
  local yqPath="$tapdir/Packages/ShellCompletion/yq"
  local cachePath="$tapdir/.tap-completions.json"

  shift

  yq()
  {
    "${yqPath}" "$@"
  }

  if [ ! -x "$yqPath" ]; then 
    # We cannot do anything if jq is not installed. We cannot even give an error.
    # This is probably happening because the plugin is not installed.
    return;
  fi

  if [ ! -f "$cachePath" ]; then
    # if the cache does not exist it should be created
    "${binary}" completion regenerate > /dev/null
  fi

  _buildQuery() {
    local query="."
    for word in "$@";
    do
      if [[ $word == -* ]]; then
        break;
      fi

      query="$query | .Completions[] | select(.Name == \"$word\")"
    done
    echo "$query"
  }

  local query="$(_buildQuery $@)"

  # the previous word on the line
  local args=($@)
  if [ "$COMP_CWORD" = "" ]; then
    COMP_CWORD="${#args[@]}"
  fi

  local previousWord="${COMP_WORDS[$(($COMP_CWORD - 1))]}"
  if [[ "$previousWord" == -* ]]; then
    local flagquery="$query | .FlagCompletions[] | select (\"-\" + .ShortName == \"$previousWord\" or \"--\" + .LongName == \"$previousWord\") | [.Type, .SuggestedCompletions[]][]"
    local flagopts=($(yq "$flagquery" "$cachePath"))

    # If the current flag is a bool, just continue since it requires no argument
    # otherwise we should only suggest completions for this flag and return
    if [ ! "${flagopts[0]}" = "System.Boolean" ]; then
      # flag completions can contain spaces. Whitespace should be escaped in the suggestions
      # compopt -o filenames
      printf "%s\n" "${flagopts[@]:1}"
      return
    fi
  fi

  query="$query | (\"-\" + (.FlagCompletions[].ShortName | select(. != null)), \"--\" + (.FlagCompletions[].LongName | select(. != null)), .Completions[].Name)"
  local candidates=($(yq "$query" "$cachePath"))

  printf "%s\n" "${candidates[@]}"
}

function _tap_completions()
{
  local IFS=$'\n'
  local relevant="${COMP_WORDS[@]:0:$((COMP_CWORD))}"
  local word="${COMP_WORDS[$COMP_CWORD]}"
  local suggestions=($(compgen -W  "$(_tap_complete_fn ${relevant[@]})" -- "$word"))
  COMPREPLY+=("${suggestions[@]}")
}

complete -o filenames -o default -o nosort -F _tap_completions tap -W

